resource "aws_instance" "instance" {
  ami           = var.ami
  instance_type = "t2.micro"
  vpc_security_group_ids = var.sg-id
  
  key_name = var.key-name
  connection {
    host        = aws_instance.instance.public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.ssh_key_path)
  }

  tags = {
    Name = var.name
  }
}
