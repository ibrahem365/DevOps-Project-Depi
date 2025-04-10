variable "description" {
  type = string
  default = "my-sg"
}

variable "name" {
  type = string
  default = "my-ssh-SG"
}

variable "vpc-id" {
  type = string
}

variable "ingress_rules" {
  description = "List of ingress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    cidr_blocks = string
    description = string
  }))
}
