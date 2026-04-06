output "taskflow_app_secret_arn" {
  value = module.secrets_manager.taskflow_app_secret_arn
}

output "taskflow_db_secret_arn" {
  value = module.secrets_manager.taskflow_db_secret_arn
}

output "app_sa_role_arn" {
  value = module.secrets_manager.app_sa_role_arn
}

output "db_sa_role_arn" {
  value = module.secrets_manager.db_sa_role_arn
}