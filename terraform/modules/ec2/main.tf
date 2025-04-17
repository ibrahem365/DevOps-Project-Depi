resource "aws_instance" "instance" {
  ami           = var.ami
  instance_type = "t2.micro"
  vpc_security_group_ids = var.sg-id
  
  key_name = var.key-name
  
  user_data = <<-EOF
              #!/bin/bash
              echo "${var.ssh_key_content}" >> /home/ubuntu/.ssh/authorized_keys
              EOF

  tags = {
    Name = var.name
  }
}
