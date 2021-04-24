// the main vpc
resource "aws_vpc" "main" {
  cidr_block           = var.vpc-cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
}

// public subnet that will receive traffic from internet
resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.current.names)
  availability_zone = element(data.aws_availability_zones.current.names, count.index)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public"
  }
}

// private subnet that should not be connected to the internet
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet-cidr

  tags = {
    Name = "private"
  }
}

// internet gateway that will be used by the public subnet to both send and receive traffic to and from the internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

// elastic ip to be used by NAT gateway
resource "aws_eip" "nat-gw" {
  vpc      = true
}

// nat gateway that will be used by the private subnet to talk to the internet
resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat-gw.id
  subnet_id     = aws_subnet.public[0].id // TODO: better to have 1 NAT gateway in every public subnet, and every private subnet should route traffic to the NAT gateway present in the public subnet of the same AZ
}

// route table for the public subnet
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.main.id
}

// route entry in the public subnet route table to route traffic to the internet gateway. the local vpc route (10.0.0.0/16) is implicit and cant be specified.
resource "aws_route" "gw-route" {
  route_table_id         = aws_route_table.public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

// route table for the private subnet
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.main.id
}

// route entry in the private subnet route table to route traffic to the nat gateway. the local vpc route (10.0.0.0/16) is implicit and cant be specified.
resource "aws_route" "nat-gw-route" {
  route_table_id         = aws_route_table.private-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.gw.id
}

// associate the public subnet with the public route table
resource "aws_route_table_association" "public-subnet-route-assoc" {
  count = length(data.aws_availability_zones.current.names)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public-route-table.id
}

// associate the private subnet with the private route table
resource "aws_route_table_association" "private-subnet-route-assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private-route-table.id
}

resource "aws_security_group" "ecs-tasks" {
  name   = "ecs-tasks"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = var.ecs-service-port
    to_port     = var.ecs-service-port
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb" {
  name   = "alb"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}