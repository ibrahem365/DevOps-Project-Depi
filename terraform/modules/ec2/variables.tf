variable "ami" {
  type = string
  default = "ami-0da424eb883458071"
}

variable "sg-id" {
  type = list(string)
}

variable "user-data" {
  type = string
  default = ""
}


variable "name" {
  type = string
}

variable "ssh_key_path" {
  description = "Path to the SSH key"
  type        = string
}
