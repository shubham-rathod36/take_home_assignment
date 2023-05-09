variable "PRIVATE_KEY_PATH" {
  default = "nit_account_key"
}

variable "PUBLIC_KEY_PATH" {
  default = "nit_account_key.pub"
}

variable "EC2_USER" {
  default = "ec2-user"
}
variable "AMI" {
   default = "ami-06e46074ae430fba6"
}
variable "KEY_NAME" {
   default = "nit_account_key"
}

variable "subnet_cidr_public" {
  description = "cidr blocks for the public subnets"
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
  type        = list(any)
}

variable "availability_zone" {
  description = "availability zones for the public subnets"
  default     = ["us-east-1a", "us-east-1b"]
  type        = list(any)
}
