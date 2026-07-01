# =============================================================
# IAM ROLES Y POLICIES — Responsable: Juli (Tarea 2.3)
# =============================================================
# Este archivo define los roles y permisos de todos los servicios.
# Principio: MÍNIMO PRIVILEGIO — cada servicio solo puede hacer
# lo que estrictamente necesita, nada más.
# =============================================================


# =============================================================
# ROLES — Cada servicio tiene su propio rol
# =============================================================


# -------------------------------------------------------------
# 1. ROL PARA LAMBDA TRIGGER
# -------------------------------------------------------------
resource "aws_iam_role" "lambda_trigger" {
  name = "${var.project_name}-lambda-trigger-role"

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


# =============================================================
# POLICIES — Qué puede hacer cada rol
# =============================================================


# -------------------------------------------------------------
# POLICY: Lambda básica (logs) — Todas las Lambdas la usan
# -------------------------------------------------------------
resource "aws_iam_policy" "lambda_basic_logs" {
  name        = "${var.project_name}-lambda-basic-logs"
  description = "Permite a las Lambdas escribir logs en CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/${var.project_name}-*"
      }
    ]
  })
}


# -------------------------------------------------------------
# POLICY: Lambda Trigger → iniciar Step Functions
# -------------------------------------------------------------
resource "aws_iam_policy" "lambda_trigger_start_execution" {
  name        = "${var.project_name}-trigger-start-sfn"
  description = "Permite a la Lambda trigger iniciar la state machine"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "StartStepFunctions"
        Effect = "Allow"
        Action = [
          "states:StartExecution"
        ]
        Resource = "arn:aws:states:${var.aws_region}:${var.aws_account_id}:stateMachine:${var.project_name}-*"
      }
    ]
  })
}


# -------------------------------------------------------------
# POLICY: Lambda Diagnóstico → leer logs + invocar Bedrock
# -------------------------------------------------------------
resource "aws_iam_policy" "lambda_diagnostico_permissions" {
  name        = "${var.project_name}-diagnostico-permissions"
  description = "Permite leer logs de CloudWatch e invocar modelos en Bedrock"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:*"
      },
      {
        Sid    = "InvokeBedrock"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "arn:aws:bedrock:${var.aws_region}::foundation-model/*"
      }
    ]
  })
}


# -------------------------------------------------------------
# POLICY: Lambda Acción → interactuar con EKS
# -------------------------------------------------------------
resource "aws_iam_policy" "lambda_accion_permissions" {
  name        = "${var.project_name}-accion-permissions"
  description = "Permite describir el cluster EKS y acceder a su API"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EKSAccess"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi"
        ]
        Resource = "arn:aws:eks:${var.aws_region}:${var.aws_account_id}:cluster/${var.cluster_name}"
      }
    ]
  })
}


# -------------------------------------------------------------
# POLICY: Lambda Notificación → invocar Bedrock + publicar SNS
# -------------------------------------------------------------
resource "aws_iam_policy" "lambda_notificacion_permissions" {
  name        = "${var.project_name}-notificacion-permissions"
  description = "Permite invocar Bedrock para generar resumen y publicar en SNS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InvokeBedrock"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "arn:aws:bedrock:${var.aws_region}::foundation-model/*"
      },
      {
        Sid    = "PublishSNS"
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = "arn:aws:sns:${var.aws_region}:${var.aws_account_id}:${var.project_name}-*"
      }
    ]
  })
}


# -------------------------------------------------------------
# POLICY: Step Functions → invocar Lambdas
# -------------------------------------------------------------
resource "aws_iam_policy" "step_functions_invoke_lambdas" {
  name        = "${var.project_name}-sfn-invoke-lambdas"
  description = "Permite a Step Functions invocar las Lambdas del proyecto"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InvokeLambdas"
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "arn:aws:lambda:${var.aws_region}:${var.aws_account_id}:function:${var.project_name}-*"
      }
    ]
  })
}


# -------------------------------------------------------------
# POLICY: EventBridge → invocar Lambda trigger
# -------------------------------------------------------------
resource "aws_iam_policy" "eventbridge_invoke_lambda" {
  name        = "${var.project_name}-eb-invoke-lambda"
  description = "Permite a EventBridge invocar la Lambda trigger"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InvokeTriggerLambda"
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "arn:aws:lambda:${var.aws_region}:${var.aws_account_id}:function:${var.project_name}-trigger"
      }
    ]
  })
}


# =============================================================
# ATTACHMENTS — Conectar cada policy con su rol
# =============================================================


# --- Lambda Trigger ---
resource "aws_iam_role_policy_attachment" "trigger_logs" {
  role       = aws_iam_role.lambda_trigger.name
  policy_arn = aws_iam_policy.lambda_basic_logs.arn
}

resource "aws_iam_role_policy_attachment" "trigger_start_sfn" {
  role       = aws_iam_role.lambda_trigger.name
  policy_arn = aws_iam_policy.lambda_trigger_start_execution.arn
}


# --- Lambda Diagnóstico ---
resource "aws_iam_role_policy_attachment" "diagnostico_logs" {
  role       = aws_iam_role.lambda_diagnostico.name
  policy_arn = aws_iam_policy.lambda_basic_logs.arn
}

resource "aws_iam_role_policy_attachment" "diagnostico_permissions" {
  role       = aws_iam_role.lambda_diagnostico.name
  policy_arn = aws_iam_policy.lambda_diagnostico_permissions.arn
}


# --- Lambda Acción ---
resource "aws_iam_role_policy_attachment" "accion_logs" {
  role       = aws_iam_role.lambda_accion.name
  policy_arn = aws_iam_policy.lambda_basic_logs.arn
}

resource "aws_iam_role_policy_attachment" "accion_permissions" {
  role       = aws_iam_role.lambda_accion.name
  policy_arn = aws_iam_policy.lambda_accion_permissions.arn
}


# --- Lambda Notificación ---
resource "aws_iam_role_policy_attachment" "notificacion_logs" {
  role       = aws_iam_role.lambda_notificacion.name
  policy_arn = aws_iam_policy.lambda_basic_logs.arn
}

resource "aws_iam_role_policy_attachment" "notificacion_permissions" {
  role       = aws_iam_role.lambda_notificacion.name
  policy_arn = aws_iam_policy.lambda_notificacion_permissions.arn
}


# --- Step Functions ---
resource "aws_iam_role_policy_attachment" "sfn_invoke" {
  role       = aws_iam_role.step_functions.name
  policy_arn = aws_iam_policy.step_functions_invoke_lambdas.arn
}


# --- EventBridge ---
resource "aws_iam_role_policy_attachment" "eb_invoke" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.eventbridge_invoke_lambda.arn
}
