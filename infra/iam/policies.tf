# =============================================================
# IAM POLICIES — Qué puede hacer cada rol (permisos específicos)
# =============================================================
# Concepto: Una policy es una lista de permisos.
# Se "attacha" (adjunta) a un rol para darle capacidades.
# Principio: MÍNIMO PRIVILEGIO — solo lo que necesita, nada más.
# =============================================================


# -------------------------------------------------------------
# POLICY: Lambda básica (logs)
# Todas las Lambdas necesitan escribir sus propios logs
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
        # Limita a log groups del proyecto
        Resource = "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/${var.project_name}-*"
      }
    ]
  })
}


# -------------------------------------------------------------
# POLICY: Lambda Trigger → puede iniciar Step Functions
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
        # Permite invocar cualquier modelo en Bedrock (se puede restringir más)
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
        Resource = "arn:aws:eks:${var.aws_region}:${var.aws_account_id}:cluster/${var.eks_cluster_name}"
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
# POLICY: Step Functions → puede invocar las Lambdas
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
# POLICY: EventBridge → puede invocar la Lambda trigger
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
