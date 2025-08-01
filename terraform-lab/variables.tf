variable "aws_access_key" {
  type      = string
  sensitive = true
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
}

variable "key_name" {
  description = "SSH Key Pair name for EC2"
  type        = string
}