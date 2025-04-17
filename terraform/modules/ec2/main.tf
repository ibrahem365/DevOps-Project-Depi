resource "aws_instance" "instance" {
  ami           = var.ami
  instance_type = "t2.micro"
  vpc_security_group_ids = var.sg-id
  
  key_name = var.key-name
  
   user_data = <<-EOF
              #!/bin/bash
              mkdir -p /home/ubuntu/.ssh
              echo "${var.ssh_key_content}" >> /home/ubuntu/.ssh/authorized_keys
              chmod 600 /home/ubuntu/.ssh/authorized_keys
              chown -R ubuntu:ubuntu /home/ubuntu/.ssh
              EOF

  tags = {
    Name = var.name
  }
}
