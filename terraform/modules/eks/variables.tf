variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "cluster_version" {
  description = "The Kubernetes version for the EKS cluster."
  type        = string
}

variable "cluster_role_arn" {
  description = "The ARN of the IAM role for the EKS cluster control plane."
  type        = string
}

variable "node_role_arn" {
  description = "The ARN of the IAM role for the EKS worker nodes."
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs where the cluster and nodes will be deployed."
  type        = list(string)
  #default     = [
  #]
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key for encrypting secrets."
  type        = string
}

variable "service_ipv4_cidr_block" {
  description = "The CIDR block for Kubernetes services."
  type        = string
  default     = "172.20.0.0/16"
}

# --- Node Group Names ---

variable "cluster_node_name" {
  description = "Name of the cluster node group."
  type        = string
}

variable "application_node_name" {
  description = "Name of the application node group."
  type        = string
}

variable "gpu_node_name" {
  description = "Name of the GPU node group."
  type        = string
}

variable "database_node_name" {
  description = "Name of the database node group."
  type        = string
}

variable "jobs_node_name" {
  description = "Name of the jobs node group."
  type        = string
}

# --- Node Group Configurations ---

# --- cluster Pool ---
variable "cluster_pool_machine_type" {
  description = "Instance type for cluster nodes."
  type        = string
  default     = "m5.large"
}

variable "cluster_pool_disk_size_gb" {
  description = "Disk size for cluster nodes."
  type        = number
  default     = 50
}

variable "cluster_pool_node_count" {
  description = "Desired number of cluster nodes."
  type        = number
  default     = 1
}

variable "cluster_pool_min_node_count" {
  description = "Minimum number of cluster nodes."
  type        = number
  default     = 1
}

variable "cluster_pool_max_node_count" {
  description = "Maximum number of cluster nodes."
  type        = number
  default     = 1
}

variable "cluster_pool_max_unavailable" {
  description = "Maximum unavailable nodes during updates for the cluster pool."
  type        = number
  default     = 1
}

# --- Application Pool ---
variable "application_pool_machine_type" {
  description = "Instance type for application nodes."
  type        = string
  default     = "m5.large"
}

variable "application_pool_disk_size_gb" {
  description = "Disk size for application nodes."
  type        = number
  default     = 50
}

variable "application_pool_node_count" {
  description = "Desired number of application nodes."
  type        = number
  default     = 1
}

variable "application_pool_min_node_count" {
  description = "Minimum number of application nodes."
  type        = number
  default     = 1
}

variable "application_pool_max_node_count" {
  description = "Maximum number of application nodes."
  type        = number
  default     = 1
}

variable "application_pool_max_unavailable" {
  description = "Maximum unavailable nodes during updates for the application pool."
  type        = number
  default     = 1
}

# --- GPU Pool ---
variable "gpu_pool_machine_type" {
  description = "Instance type for GPU nodes."
  type        = string
  default     = "g4dn.xlarge"
}

variable "gpu_pool_disk_size_gb" {
  description = "Disk size for GPU nodes."
  type        = number
  default     = 50
}

variable "gpu_pool_node_count" {
  description = "Desired number of GPU nodes."
  type        = number
  default     = 1
}

variable "gpu_pool_min_node_count" {
  description = "Minimum number of GPU nodes."
  type        = number
  default     = 1
}

variable "gpu_pool_max_node_count" {
  description = "Maximum number of GPU nodes."
  type        = number
  default     = 1
}

variable "gpu_pool_max_unavailable" {
  description = "Maximum unavailable nodes during updates for the GPU pool."
  type        = number
  default     = 1
}

# --- Database Pool ---
variable "database_pool_machine_type" {
  description = "Instance type for database nodes."
  type        = string
  default     = "m6a.2xlarge"
}

variable "database_pool_disk_size_gb" {
  description = "Disk size for database nodes."
  type        = number
  default     = 50
}

variable "database_pool_node_count" {
  description = "Desired number of database nodes."
  type        = number
  default     = 1
}

variable "database_pool_min_node_count" {
  description = "Minimum number of database nodes."
  type        = number
  default     = 1
}

variable "database_pool_max_node_count" {
  description = "Maximum number of database nodes."
  type        = number
  default     = 1
}

variable "database_pool_max_unavailable" {
  description = "Maximum unavailable nodes during updates for the database pool."
  type        = number
  default     = 1
}

# --- Jobs Pool ---
variable "jobs_pool_machine_type" {
  description = "Instance type for jobs nodes."
  type        = string
  default     = "m5.large"
}

variable "jobs_pool_disk_size_gb" {
  description = "Disk size for jobs nodes."
  type        = number
  default     = 50
}

variable "jobs_pool_node_count" {
  description = "Desired number of jobs nodes."
  type        = number
  default     = 1
}

variable "jobs_pool_min_node_count" {
  description = "Minimum number of jobs nodes."
  type        = number
  default     = 1
}

variable "jobs_pool_max_node_count" {
  description = "Maximum number of jobs nodes."
  type        = number
  default     = 1
}

variable "jobs_pool_max_unavailable" {
  description = "Maximum unavailable nodes during updates for the jobs pool."
  type        = number
  default     = 1
}