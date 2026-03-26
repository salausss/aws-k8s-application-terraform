variable "environment" {
    type      = string
}
variable "bucket_name" {
    description     =   "name of s3 bucket"
}

variable "enable_versioning" {
    type = bool
    default = false
}
