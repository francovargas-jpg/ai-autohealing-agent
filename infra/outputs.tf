output "cluster_name" {
  description = "Nombre del cluster EKS"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint de la API de Kubernetes (al que le habla kubectl)"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificado del cluster, necesario para autenticar kubectl"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_security_group_id" {
  description = "Security group del cluster (lo va a necesitar Lautaro para EventBridge/ECR si hace falta)"
  value       = module.eks.cluster_security_group_id
}

output "vpc_id" {
  description = "ID de la VPC standalone (temporal, hasta que se reemplace por la de Miguel)"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Subnets privadas donde corren los nodos"
  value       = module.vpc.private_subnets
}

output "node_group_name" {
  description = "Nombre del node group (lo va a necesitar Miguel para el agente de acción, tarea 3.4)"
  value       = module.eks.eks_managed_node_groups["main"].node_group_id
}