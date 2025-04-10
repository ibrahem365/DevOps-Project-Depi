resource "aws_security_group" "my-ssh-SG" {
  name        = var.name
  description = var.description
  vpc_id      = var.vpc-id
 
  tags = {
    Name = var.name
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  for_each          = { for idx, rule in var.ingress_rules : idx => rule }  
  security_group_id = aws_security_group.my-ssh-SG.id
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_ipv4         = each.value.cidr_blocks
  ip_protocol       = "tcp"
  description       = each.value.description
}

resource "aws_vpc_security_group_egress_rule" "allow-all1" {
  security_group_id = aws_security_group.my-ssh-SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
