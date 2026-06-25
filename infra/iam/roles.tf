# =============================================================
# IAM ROLES — Cada servicio tiene su propio rol
# =============================================================
# Concepto: Un "assume_role_policy" dice QUIÉN puede usar este rol.
# Por ejemplo: si el rol es para Lambda, solo Lambda puede asumirlo.
# =============================================================


# -------------------------------------------------------------
# 1. ROL PARA LAMBDA TRIGGER
#    Lo usa: la Lambda que recibe el evento de EventBridge
#    Necesita: iniciar ejecuciones de Step Functions
# -------------------------------------------------------------
resource "aws_iam_role" "lambda_trigger" {
  name = "${var.project_name}-lambda-trigger-role"

  # "assume_role_policy" = ¿quién puede usar este rol? → Lambda
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = var.project_name
    Role    = "trigger"
  }
}


# -------------------------------------------------------------
# 2. ROL PARA LAMBDA DE DIAGNÓSTICO
#    Lo usa: la Lambda que lee logs y consulta a Bedrock
#    Necesita: leer CloudWatch Logs + invocar modelos en Bedrock
# -------------------------------------------------------------
resource "aws_iam_role" "lambda_diagnostico" {
  name = "${var.project_name}-lambda-diagnostico-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = var.project_name
    Role    = "diagnostico"
  }
}


# -------------------------------------------------------------
# 3. ROL PARA LAMBDA DE ACCIÓN
#    Lo usa: la Lambda que reinicia pods o escala deployments
#    Necesita: acceso a la API de EKS
# -------------------------------------------------------------
resource "aws_iam_role" "lambda_accion" {
  name = "${var.project_name}-lambda-accion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = var.project_name
    Role    = "accion"
  }
}


# -------------------------------------------------------------
# 4. ROL PARA LAMBDA DE NOTIFICACIÓN
#    Lo usa: la Lambda que genera el resumen con Bedrock y notifica
#    Necesita: invocar Bedrock + publicar en SNS
# -------------------------------------------------------------
resource "aws_iam_role" "lambda_notificacion" {
  name = "${var.project_name}-lambda-notificacion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = var.project_name
    Role    = "notificacion"
  }
}


# -------------------------------------------------------------
# 5. ROL PARA STEP FUNCTIONS
#    Lo usa: la state machine que orquesta todo
#    Necesita: invocar las Lambdas
# -------------------------------------------------------------
resource "aws_iam_role" "step_functions" {
  name = "${var.project_name}-stepfunctions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = var.project_name
    Role    = "orquestador"
  }
}


# -------------------------------------------------------------
# 6. ROL PARA EVENTBRIDGE
#    Lo usa: la regla que detecta fallos en EKS
#    Necesita: invocar la Lambda trigger
# -------------------------------------------------------------
resource "aws_iam_role" "eventbridge" {
  name = "${var.project_name}-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = var.project_name
    Role    = "eventbridge"
  }
}
