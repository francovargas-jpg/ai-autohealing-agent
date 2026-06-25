# =============================================================
# Variables: valores que se pueden cambiar sin tocar el código
# =============================================================

variable "aws_region" {
  description = "Región de AWS donde se despliega la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "ID de la cuenta AWS (número de 12 dígitos)"
  type        = string
}

variable "project_name" {
  description = "Nombre del proyecto, se usa como prefijo en los recursos"
  type        = string
  default     = "autohealing-agent"
}

variable "eks_cluster_name" {
  description = "Nombre del cluster EKS (lo crea Franco en la tarea 2.2)"
  type        = string
  default     = "autohealing-cluster"
}
