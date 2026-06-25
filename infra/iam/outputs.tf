# =============================================================
# OUTPUTS — Valores que otros módulos/compañeros van a necesitar
# =============================================================
# Concepto: Cuando Franco crea las Lambdas, necesita saber el ARN
# del rol para asignárselo. Los outputs exportan esos valores.
# =============================================================

output "lambda_trigger_role_arn" {
  description = "ARN del rol para la Lambda trigger"
  value       = aws_iam_role.lambda_trigger.arn
}

output "lambda_diagnostico_role_arn" {
  description = "ARN del rol para la Lambda de diagnóstico"
  value       = aws_iam_role.lambda_diagnostico.arn
}

output "lambda_accion_role_arn" {
  description = "ARN del rol para la Lambda de acción"
  value       = aws_iam_role.lambda_accion.arn
}

output "lambda_notificacion_role_arn" {
  description = "ARN del rol para la Lambda de notificación"
  value       = aws_iam_role.lambda_notificacion.arn
}

output "step_functions_role_arn" {
  description = "ARN del rol para Step Functions"
  value       = aws_iam_role.step_functions.arn
}

output "eventbridge_role_arn" {
  description = "ARN del rol para EventBridge"
  value       = aws_iam_role.eventbridge.arn
}
