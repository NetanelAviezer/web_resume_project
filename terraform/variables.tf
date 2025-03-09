variable "jenkins_public_key" {
  description = "Public key for the Jenkins key pair"
  type        = string
}

variable "db_username" {
  description = "Database admin username"
  type        = string
  default     = "neho"
}

variable "db_password" {
  description = "Database admin password"
  type        = string
  default     = "!Twork314Nh"
  sensitive   = true
}
