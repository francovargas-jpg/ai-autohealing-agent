"""
Lambda de Diagnóstico — Agente de Auto-Healing
================================================
Este es el "cerebro" del sistema. Cuando un pod falla:
1. Lee los logs recientes del pod desde CloudWatch
2. Se los envía a Bedrock (IA) con instrucciones de análisis
3. Devuelve un diagnóstico: qué pasó, nivel de confianza, qué hacer

Este archivo es el "handler" de la Lambda — la función que AWS ejecuta
automáticamente cuando Step Functions la invoca.
"""

import json
import boto3
from datetime import datetime, timedelta


# -----------------------------------------------------------------
# CLIENTES DE AWS
# boto3 es la librería de Python para hablar con servicios de AWS.
# Creamos un "cliente" por cada servicio que necesitamos usar.
# -----------------------------------------------------------------
logs_client = boto3.client("logs")          # Para leer CloudWatch Logs
bedrock_client = boto3.client("bedrock-runtime")  # Para invocar modelos de IA


# -----------------------------------------------------------------
# CONFIGURACIÓN
# -----------------------------------------------------------------
MODELO_BEDROCK = "anthropic.claude-3-haiku-20240307-v1:0"  # Modelo rápido y económico
MINUTOS_DE_LOGS = 30  # Cuántos minutos hacia atrás buscar logs


def handler(event, context):
    """
    Función principal que AWS Lambda ejecuta.

    Parámetros:
    -----------
    event : dict
        Datos que recibe de Step Functions. Esperamos:
        - log_group_name: nombre del log group en CloudWatch (ej: "/aws/eks/cluster/pod-name")
        - pod_name: nombre del pod que falló (ej: "api-service-7d4b8c6f-x9k2m")
        - namespace: namespace de Kubernetes (ej: "default")
        - error_type: tipo de error detectado (ej: "CrashLoopBackOff")

    context : object
        Información de la Lambda (tiempo restante, memoria, etc.)
        No lo usamos directamente pero AWS lo pasa siempre.

    Retorna:
    --------
    dict con el diagnóstico:
        - causa_probable: explicación de qué pasó
        - nivel_confianza: "alto", "medio" o "bajo"
        - accion_recomendada: qué debería hacer el agente de acción
        - detalle_tecnico: info técnica para el equipo
    """

    print(f"[DIAGNOSTICO] Evento recibido: {json.dumps(event)}")

    # --- Paso 1: Extraer datos del evento ---
    log_group_name = event.get("log_group_name")
    pod_name = event.get("pod_name", "desconocido")
    namespace = event.get("namespace", "default")
    error_type = event.get("error_type", "desconocido")

    if not log_group_name:
        return {
            "error": "Falta el campo 'log_group_name' en el evento",
            "nivel_confianza": "bajo",
            "accion_recomendada": "escalar_a_humano"
        }

    # --- Paso 2: Leer logs de CloudWatch ---
    logs = obtener_logs_recientes(log_group_name)

    if not logs:
        return {
            "causa_probable": "No se encontraron logs recientes para analizar",
            "nivel_confianza": "bajo",
            "accion_recomendada": "escalar_a_humano",
            "detalle_tecnico": f"Log group: {log_group_name} — sin eventos en los últimos {MINUTOS_DE_LOGS} minutos"
        }

    # --- Paso 3: Consultar a Bedrock (IA) ---
    diagnostico = consultar_bedrock(logs, pod_name, namespace, error_type)

    print(f"[DIAGNOSTICO] Resultado: {json.dumps(diagnostico)}")
    return diagnostico


def obtener_logs_recientes(log_group_name):
    """
    Lee los logs más recientes de un log group en CloudWatch.

    ¿Por qué 30 minutos? Porque si un pod se crasheó, los logs relevantes
    van a estar en los últimos minutos. No necesitamos ir más atrás.

    Parámetros:
    -----------
    log_group_name : str
        El nombre del log group (ej: "/aws/eks/autohealing-cluster/pod-api")

    Retorna:
    --------
    str : todos los mensajes de log concatenados, o string vacío si no hay
    """

    # Calculamos el timestamp de "hace 30 minutos" en milisegundos
    # (CloudWatch usa milisegundos desde epoch)
    ahora = datetime.now()
    hace_30_min = ahora - timedelta(minutes=MINUTOS_DE_LOGS)
    timestamp_inicio = int(hace_30_min.timestamp() * 1000)

    try:
        # filter_log_events busca eventos en el log group
        # Limitamos a 50 eventos para no mandar demasiado texto a Bedrock
        response = logs_client.filter_log_events(
            logGroupName=log_group_name,
            startTime=timestamp_inicio,
            limit=50,
            interleaved=True  # Mezcla logs de todos los streams (útil si hay varios containers)
        )

        # Extraemos solo el mensaje de cada evento y los unimos con saltos de línea
        mensajes = [evento["message"] for evento in response.get("events", [])]
        return "\n".join(mensajes)

    except logs_client.exceptions.ResourceNotFoundException:
        print(f"[ERROR] Log group no encontrado: {log_group_name}")
        return ""
    except Exception as e:
        print(f"[ERROR] Error leyendo logs: {str(e)}")
        return ""


def consultar_bedrock(logs, pod_name, namespace, error_type):
    """
    Envía los logs a Bedrock (Claude) y pide un diagnóstico estructurado.

    ¿Por qué armamos un prompt tan específico? Porque cuanto más contexto
    y estructura le damos a la IA, mejor y más consistente es la respuesta.
    Le pedimos que responda en JSON para poder procesarlo programáticamente.

    Parámetros:
    -----------
    logs : str
        Los logs recientes del pod
    pod_name : str
        Nombre del pod que falló
    namespace : str
        Namespace de Kubernetes
    error_type : str
        Tipo de error detectado (ej: CrashLoopBackOff)

    Retorna:
    --------
    dict con: causa_probable, nivel_confianza, accion_recomendada, detalle_tecnico
    """

    # --- Armamos el prompt para la IA ---
    prompt = f"""Sos un ingeniero DevOps/SRE experto analizando fallos en Kubernetes.

CONTEXTO:
- Pod: {pod_name}
- Namespace: {namespace}
- Tipo de error: {error_type}
- Plataforma: Amazon EKS

LOGS RECIENTES DEL POD:
{logs}

TAREA:
Analizá los logs y respondé EXCLUSIVAMENTE con un JSON válido (sin texto adicional) con esta estructura:

{{
    "causa_probable": "Explicación clara y concisa de qué causó el fallo",
    "nivel_confianza": "alto | medio | bajo",
    "accion_recomendada": "restart_pod | scale_deployment | rollback | escalar_a_humano",
    "detalle_tecnico": "Información técnica adicional para el equipo de DevOps"
}}

REGLAS:
- Si los logs muestran OOMKilled → accion_recomendada = "scale_deployment"
- Si los logs muestran un error de conexión a DB → accion_recomendada = "restart_pod"
- Si los logs muestran un error de código (exception, traceback) → accion_recomendada = "rollback"
- Si no estás seguro de la causa → nivel_confianza = "bajo" y accion_recomendada = "escalar_a_humano"
- Respondé SOLO el JSON, sin explicaciones adicionales
"""

    try:
        # --- Llamamos a Bedrock ---
        # invoke_model envía el prompt al modelo y espera la respuesta
        response = bedrock_client.invoke_model(
            modelId=MODELO_BEDROCK,
            contentType="application/json",
            accept="application/json",
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 1024,
                "messages": [
                    {
                        "role": "user",
                        "content": prompt
                    }
                ]
            })
        )

        # --- Parseamos la respuesta ---
        response_body = json.loads(response["body"].read())
        respuesta_texto = response_body["content"][0]["text"]

        # Intentamos convertir la respuesta de texto a un diccionario Python
        diagnostico = json.loads(respuesta_texto)

        # Validamos que tenga los campos esperados
        campos_requeridos = ["causa_probable", "nivel_confianza", "accion_recomendada"]
        for campo in campos_requeridos:
            if campo not in diagnostico:
                diagnostico[campo] = "no_disponible"

        return diagnostico

    except json.JSONDecodeError:
        # Si Bedrock no devolvió un JSON válido
        print(f"[ERROR] Respuesta de Bedrock no es JSON válido: {respuesta_texto}")
        return {
            "causa_probable": "No se pudo parsear la respuesta de la IA",
            "nivel_confianza": "bajo",
            "accion_recomendada": "escalar_a_humano",
            "detalle_tecnico": f"Respuesta raw: {respuesta_texto[:500]}"
        }
    except Exception as e:
        print(f"[ERROR] Error llamando a Bedrock: {str(e)}")
        return {
            "causa_probable": f"Error al consultar IA: {str(e)}",
            "nivel_confianza": "bajo",
            "accion_recomendada": "escalar_a_humano",
            "detalle_tecnico": "Fallo en la comunicación con Bedrock"
        }
