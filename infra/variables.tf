variable "aws_region" {
  description = "Región de AWS donde se despliega todo"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Nombre del cluster EKS"
  type        = string
  default     = "autohealing-cluster"
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes para el control plane de EKS"
  type        = string
  default     = "1.30"
}

variable "node_instance_type" {
  description = "Tipo de instancia EC2 para el node group"
  type        = string
  default     = "t3.small"
}

variable "node_desired_size" {
  description = "Cantidad deseada de nodos"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Cantidad mínima de nodos"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Cantidad máxima de nodos"
  type        = number
  default     = 3
}