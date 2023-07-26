resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/22"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = "healthcheck-vpc"
  }
}

resource "aws_subnet" "publicSubnet" {
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.1.0/24"
  vpc_id                  = aws_vpc.my_vpc.id
  map_public_ip_on_launch = false
}

resource "aws_subnet" "privateSubnet" {
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.2.0/24"
  vpc_id                  = aws_vpc.my_vpc.id
  map_public_ip_on_launch = false
}

resource "aws_internet_gateway" "publicInternetGateway" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "healthcheck-igw"
  }
}

resource "aws_route_table" "publicRouteTable" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "healthcheck-rtb-public"
  }
}

resource "aws_route_table" "privateRouteTable" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "healthcheck-rtb-private"
  }
}

resource "aws_route" "publicRoute" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.publicInternetGateway.id
  route_table_id         = aws_route_table.publicRouteTable.id
}

resource "aws_route" "privateRoute" {
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natGateway.id
  route_table_id         = aws_route_table.privateRouteTable.id
}

resource "aws_nat_gateway" "natGateway" {
  subnet_id = aws_subnet.publicSubnet.id
  tags = {
    Name = "healthcheck-nat-public1-us-east-1a"
  }
  allocation_id = aws_eip.my_eip.id
}
resource "aws_eip" "my_eip" {
  domain = "vpc"
}

resource "aws_route_table_association" "publicRouteTableAssociation" {
  route_table_id = aws_route_table.publicRouteTable.id
  subnet_id      = aws_subnet.publicSubnet.id
}

resource "aws_route_table_association" "privateRouteTableAssociation" {
  route_table_id = aws_route_table.privateRouteTable.id
  subnet_id      = aws_subnet.privateSubnet.id
}
