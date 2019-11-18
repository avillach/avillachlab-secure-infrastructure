resource "aws_security_group" "inbound-from-public-internet" {
  name = "allow_inbound_from_public_internet_to_httpd"
  description = "Allow inbound traffic from public internet to httpd servers"
  vpc_id = var.target-vpc

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/32"
    ]
  }

  tags = {
    Owner       = "Avillach_Lab"
    Environment = "development"
    Name        = "FISMA Terraform Playground - ${var.stack_githash} - inbound-from-public-internet Security Group"
  }
}

resource "aws_security_group" "outbound-to-app" {
  name = "allow_outbound_from_edge_to_wildfly_port_in_app_vpc"
  description = "Allow outbound traffic to app-subnets on port 8080 until we have TLS in place for app server"
  vpc_id = var.target-vpc

  egress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = [
      var.app-subnet-us-east-1a-cidr, 
      var.app-subnet-us-east-1b-cidr
    ]
  }
  tags = {
    Owner       = "Avillach_Lab"
    Environment = "development"
    Name        = "FISMA Terraform Playground - ${var.stack_githash} - outbound-to-app Security Group"
  }
}
