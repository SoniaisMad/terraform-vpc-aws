provider "aws" {
  region = "eu-west-3"
}

# 1 - creation of the VPC
# 2 - creation of a public and private Network
# 3 - Routes all the traffic from the private network to the public network
# 4 - Routes all the traffic from the public network to internet
# 5 - assigns an elastic IP to the traffic coming from the public network (with the nat gateway)

# Virtual Private Cloud (VPC)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

#Subnet

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private"
  }
}

#Routes tables public
resource "aws_route_table" "routes-public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }
}

#Routes tables private
resource "aws_route_table" "routes-private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

# Route Table Associations

resource "aws_route_table_association" "ehr-routes-public" {
  route_table_id = aws_route_table.routes-public.id
  subnet_id      = aws_subnet.public_subnet.id
}

resource "aws_route_table_association" "ehr-routes-private" {
  route_table_id = aws_route_table.routes-private.id
  subnet_id      = aws_subnet.private_subnet.id
}

# Internet Gateway
resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.main.id}"
}

# Elastic IP
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.ig]
}

# Nat Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${element(aws_subnet.public_subnet.*.id, 0)}"
  depends_on    = [aws_internet_gateway.ig]
}
# 1 EC2 Instance in public/ Private Subnet (Amazon Linux 2 AMI)
resource "aws_instance" "my_instance" {
  ami           = "ami-00798d7180f25aac2" # eu-west-3
  instance_type = "t2.micro"

}
# Security Groups

resource "aws_security_group" "sg" {
  name        = "security group"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my_sg"
  }
}
