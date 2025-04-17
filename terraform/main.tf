data "aws_vpc" "default" {
  default = true
}

module "todo-app" {
  source = "./modules/ec2"
  ami           = "ami-084568db4383264d4"
  sg-id  = [module.todo-app-sg.id]
 ssh_key = var.ssh_key_content
  key-name = "connection"
  name = "todo-app"
}

module "todo-app-sg" {
  source = "./modules/sg"
  name = "todo-app-sg"
  description = "enable ssh and ports 3000,9100,8080"
  vpc-id = data.aws_vpc.default.id
  ingress_rules = [
    { from_port = 22, to_port = 22, cidr_blocks = "0.0.0.0/0", description = "Allow SSH" },
    { from_port = 3000, to_port = 3000, cidr_blocks = "0.0.0.0/0", description = "Allow port 3000 todo-app" },
    { from_port = 9100, to_port = 9100, cidr_blocks = "0.0.0.0/0", description = "Allow port 9100 nodeExporter" },
    { from_port = 8080, to_port = 8080, cidr_blocks = "0.0.0.0/0", description = "Allow port 8080 cAdvisor" }
  ]
}

resource "local_file" "todo-app_public_ip" {
  content  = module.todo-app.public-ip
  filename = "${path.module}/ec2_public_ip.txt"
}

module "prometheus" {
  source = "./modules/ec2"
  ami           = "ami-0ea3c35c5c3284d82"
  sg-id  = [module.prometheus-sg.id]
  ssh_key       = var.ssh_key_content
  key-name = "connection"
  name = "prometheus"
}

module "prometheus-sg" {
  source = "./modules/sg"
  name = "prometheus-sg"
  description = "enable ssh and ports 9090,3000"
  vpc-id = data.aws_vpc.default.id
  ingress_rules = [
    { from_port = 22, to_port = 22, cidr_blocks = "0.0.0.0/0", description = "Allow SSH" },
    { from_port = 9090, to_port = 9090, cidr_blocks = "0.0.0.0/0", description = "Allow port 9090 Prometheus" },
    { from_port = 3000, to_port = 3000, cidr_blocks = "0.0.0.0/0", description = "Allow port 3000 Grafana" },
  ]
}

resource "local_file" "prometheus_public_ip" {
  content  = module.prometheus.public-ip
  filename = "${path.module}/prometheus_public_ip.txt"
}
