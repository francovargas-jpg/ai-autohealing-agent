# =============================================================
# ATTACHMENTS — Conectar cada policy con su rol
# =============================================================
# Concepto: Crear un rol y una policy por separado no hace nada.
# Hay que "attachar" (adjuntar) la policy al rol para que funcione.
# Es como darle la credencial (policy) a la persona correcta (rol).
# =============================================================


# --- Lambda Trigger: logs básicos + iniciar Step Functions ---
resource "aws_iam_role_policy_attachment" "trigger_logs" {
  role       = aws_iam_role.lambda_trigger.name
  policy_arn = aws_iam_policy.lambda_basic_logs.arn
}

resource "aws_iam_role_policy_attachment" "trigger_start_sfn" {
  role       = aws_iam_role.lambda_trigger.name
  policy_arn = aws_iam_policy.lambda_trigger_start_execution.arn
}


# --- Lambda Diagnóstico: logs básicos + leer logs + Bedrock ---
resource "aws_iam_role_policy_attachment" "diagnostico_logs" {
  role       = aws_iam_role.lambda_diagnostico.name
  policy_arn = aws_iam_policy.lambda_basic_logs.arn
}

resource "aws_iam_role_policy_attachment" "diagnostico_permissions" {
  role       = aws_iam_role.lambda_diagnostico.name
  policy_arn = aws_iam_policy.lambda_diagnostico_permissions.arn
}


# --- Lambda Acción: logs básicos + acceso a EKS ---
resource "aws_iam_role_policy_attachment" "accion_logs" {
  role       = aws_iam_role.lambda_accion.name
  policy_arn = aws_iam_policy.lambda_basic_logs.arn
}

resource "aws_iam_role_policy_attachment" "accion_permissions" {
  role       = aws_iam_role.lambda_accion.name
  policy_arn = aws_iam_policy.lambda_accion_permissions.arn
}


# --- Lambda Notificación: logs básicos + Bedrock + SNS ---
resource "aws_iam_role_policy_attachment" "notificacion_logs" {
  role       = aws_iam_role.lambda_notificacion.name
  policy_arn = aws_iam_policy.lambda_basic_logs.arn
}

resource "aws_iam_role_policy_attachment" "notificacion_permissions" {
  role       = aws_iam_role.lambda_notificacion.name
  policy_arn = aws_iam_policy.lambda_notificacion_permissions.arn
}


# --- Step Functions: invocar Lambdas ---
resource "aws_iam_role_policy_attachment" "sfn_invoke" {
  role       = aws_iam_role.step_functions.name
  policy_arn = aws_iam_policy.step_functions_invoke_lambdas.arn
}


# --- EventBridge: invocar Lambda trigger ---
resource "aws_iam_role_policy_attachment" "eb_invoke" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.eventbridge_invoke_lambda.arn
}
