# =============================================================
# ECR — Repositorios de imágenes Docker (Lautaro, Tarea 2.4)
# =============================================================
# Un repo por agente Lambda. Escaneo automático al hacer push y
# lifecycle policy para no acumular imágenes viejas (costo).

locals {
  agentes = ["diagnostico", "accion", "notificacion", "trigger"]
}

resource "aws_ecr_repository" "agentes" {
  for_each = toset(local.agentes)

  name                 = "${var.project_name}/${each.value}"
  image_tag_mutability = "MUTABLE" # el piloto reusa tags como "latest"
  force_delete         = true      # facilita destroy en el piloto

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = var.project_name
    Agente  = each.value
  }
}

resource "aws_ecr_lifecycle_policy" "agentes" {
  for_each   = aws_ecr_repository.agentes
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Mantener solo las ultimas 10 imagenes"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}
