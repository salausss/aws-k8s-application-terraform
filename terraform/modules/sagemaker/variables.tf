variable "project_name" {
    description = "sagemaker project name."
    type        = string
}

variable "instance_type" {
  description = "The EC2 instance type for the notebook (e.g., ml.t3.medium, ml.m5.xlarge)"
  type        = string
  default     = "ml.t3.medium"
}

variable "lifecycle_config_name" {
  description = "The name of a SageMaker lifecycle configuration to associate with the notebook"
  type        = string
  default     = null
}