# Infrastructure Auto-Healing Agent — Roadmap (main)
## Roadmap y tareas — Crubyt AI-Driven Initiative

**Equipo:** Franco · Juli · Miguel · Lautaro  
**Duración:** 10 semanas · 1h/día por persona · ~160hs totales  
**Stack:** EKS · Amazon Bedrock · Lambda · Step Functions · EventBridge · CloudWatch · ECR · Terraform · Jenkins

---

## Línea de tiempo

| Semana | Fase | Foco |
|--------|------|------|
| Sem 1–2 | Fase 01 | Diseño de arquitectura |
| Sem 3–4 | Fase 02 | Infraestructura base con Terraform |
| Sem 5–7 | Fase 03 | Core del agente (multi-agente + Bedrock) |
| Sem 8–9 | Fase 04 | CI/CD pipeline con Jenkins |
| Sem 10  | Fase 05 | Demo en vivo + documentación |

---

## Fase 01 — Diseño de arquitectura `Sem 1–2`

### Objetivo
Tener el diagrama de arquitectura completo, el caso de uso definido, y el repositorio listo antes de escribir una sola línea de código.

> ⚠️ **Prioridad inmediata:** Solicitar acceso a Bedrock en la cuenta AWS esta semana. Requiere aprobación manual de Amazon y puede demorar 1–2 días hábiles.

| # | Tarea | Responsable | Detalle |
|---|-------|-------------|---------|
| 1.1 | Crear repositorio GitHub | **Franco** | Repo: `ai-autohealing-agent`. README inicial, `.gitignore`, estructura de carpetas: `infra/`, `functions/`, `docs/` |
| 1.2 | Diagrama de arquitectura detallado | **Juli** | Draw.io o Lucidchart. Todos los servicios AWS, flujo entre agentes, fuentes de eventos |
| 1.3 | Definir caso de uso ficticio | **Miguel** | Documentar el cliente imaginario, qué servicios tiene en EKS, tipos de fallos esperados, qué hace el agente en cada caso |
| 1.4 | Solicitar acceso a Bedrock + elegir modelo | **Lautaro** | Definir si se usa Claude Haiku, Claude Sonnet o Titan. Solicitar acceso en AWS Console (Bedrock → Model access) |

---

## Fase 02 — Infraestructura base con Terraform `Sem 3–4`

### Objetivo
Toda la infraestructura de base levantada como código, reproducible desde cero con un `terraform apply`.

| # | Tarea | Responsable | Detalle |
|---|-------|-------------|---------|
| 2.1 | VPC y networking | **Miguel** | VPC, subnets públicas/privadas, Internet Gateway, security groups |
| 2.2 | EKS cluster + node group | **Franco** | Cluster EKS con Terraform. Node group t3.small o Fargate para mantener costo bajo en el piloto |
| 2.3 | IAM roles y políticas | **Juli** | Roles para Lambda, EKS, Bedrock y EventBridge. Principio de mínimo privilegio desde el inicio |
| 2.4 | ECR registry | **Lautaro** | Repositorio ECR para imágenes Docker de los agentes. Lifecycle policy para limpiar imágenes viejas |
| 2.5 | CloudWatch log groups y alarmas base | **Miguel** | Log groups para cada agente. Alarmas de prueba que el agente va a leer en la fase 3 |

---

## Fase 03 — Core del agente `Sem 5–7`

### Objetivo
Los cuatro agentes funcionando en cadena: EventBridge detecta una falla → Lambda trigger → Step Functions orquesta → Diagnóstico → Acción → Notificación.

```
EventBridge → Lambda → Step Functions → [Diagnóstico → Acción → Notificación]
```

| # | Tarea | Responsable | Detalle |
|---|-------|-------------|---------|
| 3.1 | EventBridge rule → Lambda trigger | **Lautaro** | Regla que escucha eventos de EKS (pod failed, crashloopbackoff). Lambda que recibe el evento y arranca Step Functions |
| 3.2 | Step Functions state machine | **Franco** | Flujo orquestador completo con manejo de errores y retry. Estados: trigger → diagnóstico → decisión → acción → notificación |
| 3.3 | Agente de diagnóstico (Lambda + Bedrock) | **Juli** | Lambda que lee logs de CloudWatch y llama a Bedrock con el contexto. Devuelve causa probable y nivel de confianza |
| 3.4 | Agente de acción (Lambda + EKS API) | **Miguel** | Lambda que ejecuta en el cluster: restart pod, patch deployment, o escala a humano si la confianza es baja |
| 3.5 | Agente de notificación (Lambda + SNS/SES) | **Lautaro** | Bedrock genera resumen en español. Se envía por email o Slack: qué pasó, qué hizo el agente, nivel de confianza |

---

## Fase 04 — CI/CD pipeline con Jenkins `Sem 8–9`

### Objetivo
Pipeline automatizado: push a `main` → build → push a ECR → deploy a EKS. Sin pasos manuales.

```
GitHub push → Jenkins → docker build → ECR push → kubectl apply → EKS
```

| # | Tarea | Responsable | Detalle |
|---|-------|-------------|---------|
| 4.1 | Jenkinsfile + pipeline base | **Franco** | Stages: checkout → test → docker build → push ECR → deploy EKS. Trigger en push a main |
| 4.2 | Dockerizar los agentes Lambda | **Juli** | Dockerfile por agente. Imagen base Python/Node + dependencias. Subir a ECR manualmente primero, luego automatizar |
| 4.3 | Credenciales AWS en Jenkins | **Lautaro** | Configurar AWS credentials en Jenkins Credentials Store. Nunca hardcodear keys. Usar IAM role o OIDC si es posible |
| 4.4 | Testing de pipeline end-to-end | **Miguel** | Verificar que el pipeline completo corre sin errores. Documentar cualquier ajuste necesario |

---

## Fase 05 — Demo y documentación `Sem 10`

### Objetivo
Demo en vivo funcionando. README técnico en inglés. Presentación final al equipo Crubyt con resultados reales del piloto.

| # | Tarea | Responsable | Detalle |
|---|-------|-------------|---------|
| 5.1 | Script de demo en vivo | **Franco** | Matar un pod con `kubectl delete pod`, mostrar EventBridge capturándolo, Step Functions ejecutando, reporte llegando por Slack |
| 5.2 | README técnico | **Miguel** | Arquitectura, diagrama, instrucciones de despliegue, variables de entorno necesarias, caso de uso documentado. En inglés |
| 5.3 | Grabación o GIF del agente actuando | **Lautaro** | Screen recording de la demo para adjuntar al repo y usar en LinkedIn/presentaciones |
| 5.4 | Presentación final al equipo Crubyt | **Juli** | Actualizar el deck con resultados reales del piloto: qué funcionó, qué no, próximos pasos |

---

## Resumen por persona

| | Franco | Juli | Miguel | Lautaro |
|--|--------|------|--------|---------|
| Fase 01 | 1.1 Repo GitHub | 1.2 Diagrama arquitectura | 1.3 Caso de uso | 1.4 Acceso Bedrock |
| Fase 02 | 2.2 EKS cluster | 2.3 IAM roles | 2.1 VPC + networking | 2.4 ECR registry |
| Fase 03 | 3.2 Step Functions | 3.3 Agente diagnóstico | 3.4 Agente acción | 3.1 EventBridge trigger |
| | | | 2.5 CloudWatch | 3.5 Agente notificación |
| Fase 04 | 4.1 Jenkinsfile | 4.2 Dockerizar agentes | 4.4 Testing pipeline | 4.3 Credenciales Jenkins |
| Fase 05 | 5.1 Script demo | 5.4 Presentación final | 5.2 README técnico | 5.3 Grabación demo |
| **Total** | **5 tareas** | **5 tareas** | **5 tareas** | **5 tareas** |

---

## Referencias y recursos

- [Amazon Bedrock — Model access](https://console.aws.amazon.com/bedrock/home#/modelaccess)
- [EKS con Terraform — módulo oficial](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [AWS Step Functions — Documentación](https://docs.aws.amazon.com/step-functions/)
- [EventBridge — Eventos de EKS](https://docs.aws.amazon.com/eks/latest/userguide/logging-using-cloudtrail.html)
- [Jenkins + AWS ECR — Plugin](https://plugins.jenkins.io/amazon-ecr/)

---

*Proyecto piloto — Crubyt AI-Driven Initiative · 2026*
