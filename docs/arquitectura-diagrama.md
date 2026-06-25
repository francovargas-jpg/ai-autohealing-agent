# Diagrama de Arquitectura — Infrastructure Auto-Healing Agent

## Flujo principal: Detección y auto-healing

```mermaid
flowchart LR
    subgraph EKS["Amazon EKS (Cluster)"]
        POD[Pod con falla]
    end

    subgraph Observabilidad
        CW[Amazon CloudWatch\nLogs + Alarmas]
    end

    subgraph Orquestacion["Orquestación (AWS Step Functions)"]
        SF[State Machine]
        DIAG[Lambda\nDiagnóstico]
        ACTION[Lambda\nAcción]
        NOTIF[Lambda\nNotificación]
    end

    subgraph IA["Inteligencia Artificial"]
        BEDROCK[Amazon Bedrock\nClaude / Titan]
    end

    subgraph Notificaciones
        SNS[Amazon SNS]
        SLACK[Slack / Email]
    end

    EB[Amazon EventBridge]
    TRIGGER[Lambda Trigger]

    %% Flujo principal
    POD -->|"emite evento\n(CrashLoopBackOff)"| EB
    POD -->|"escribe logs"| CW
    EB -->|"regla detecta fallo"| TRIGGER
    TRIGGER -->|"inicia ejecución"| SF

    %% Step Functions orquesta
    SF --> DIAG
    DIAG -->|"lee logs"| CW
    DIAG -->|"consulta IA:\n¿qué pasó?"| BEDROCK
    DIAG -->|"causa probable +\nnivel confianza"| SF

    SF --> ACTION
    ACTION -->|"reinicia pod /\nescala deployment"| POD
    ACTION -->|"si confianza baja:\nescala a humano"| NOTIF

    SF --> NOTIF
    NOTIF -->|"genera resumen\nen español"| BEDROCK
    NOTIF -->|"envía alerta"| SNS
    SNS --> SLACK
```

## Pipeline CI/CD

```mermaid
flowchart LR
    subgraph Desarrollo
        GH[GitHub\nRepositorio]
    end

    subgraph CICD["CI/CD"]
        JK[Jenkins\nPipeline]
    end

    subgraph AWS["AWS"]
        ECR[Amazon ECR\nDocker Registry]
        EKS2[Amazon EKS\nCluster]
    end

    GH -->|"push a main"| JK
    JK -->|"docker build +\npush imagen"| ECR
    JK -->|"kubectl apply"| EKS2
    ECR -->|"imagen disponible"| EKS2
```

## Servicios involucrados

| Servicio | Rol en el sistema |
|----------|-------------------|
| Amazon EKS | Cluster donde corren las aplicaciones (pods) |
| Amazon EventBridge | Detecta eventos de fallo en EKS |
| AWS Lambda (x4) | Trigger, Diagnóstico, Acción, Notificación |
| AWS Step Functions | Orquesta el flujo entre los agentes |
| Amazon Bedrock | IA para análisis de logs y generación de reportes |
| Amazon CloudWatch | Almacena logs y métricas |
| Amazon ECR | Registro privado de imágenes Docker |
| Amazon SNS/SES | Envío de notificaciones |
| Jenkins | Pipeline CI/CD automatizado |
| GitHub | Repositorio de código fuente |

## Notas de diseño

- **Multi-agente:** Cada Lambda cumple un rol específico (diagnóstico, acción, notificación), orquestados por Step Functions.
- **Bedrock como cerebro:** Se usa para interpretar logs (diagnóstico) y para generar reportes legibles (notificación).
- **Escalamiento a humano:** Si el agente de diagnóstico tiene baja confianza en su análisis, no actúa automáticamente — escala a un humano via Slack.
- **Principio de mínimo privilegio:** Cada Lambda tiene un IAM role con solo los permisos que necesita (esto se detalla en la tarea 2.3).
