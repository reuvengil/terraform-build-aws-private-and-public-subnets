terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.0"
        }
    }
}

provider "aws" {
    region = "us-east-1"
    access_key = "enter access key"
    secret_key = "enter secret key"
}

resource "aws_lambda_function" "GetNextBlockLambda" {
    description = ""
    function_name = "GetNextBlockLambda"
    handler = "index.handler"
    architectures = [
        "x86_64"
    ]
    role = aws_iam_role.getNextBlockLambdaRole.arn
    runtime = "nodejs18.x"
    timeout = 3
    layers = [
        aws_lambda_layer_version.LambdaLayerVersion.arn
    ]
  
    filename      = "zips/getNextBlockLambda.zip"
    source_code_hash = filebase64sha256("zips/getNextBlockLambda.zip")

}

resource "aws_iam_role" "getNextBlockLambdaRole" {
  name = "getNextBlockLambdaRole"
  
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "Statement1",
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action":"sts:AssumeRole",
      }
    ]
  })
}

resource "aws_lambda_layer_version" "LambdaLayerVersion" {
    layer_name = "node_modules"
    description = "node_modulesLayer"
    compatible_runtimes = [
        "nodejs18.x"
    ]
    filename   = "zips/node_modules.zip"
    source_code_hash = filebase64sha256("zips/node_modules.zip")
}

resource "aws_vpc" "my_vpc" {
    cidr_block = "10.0.0.0/22"
    enable_dns_support = true
    enable_dns_hostnames = true
    instance_tenancy = "default"
    tags = {
        Name = "blockchain-vpc"
    }
}

resource "aws_subnet" "publicSubnet" {
    availability_zone = "us-east-1a"
    cidr_block = "10.0.1.0/24"
    vpc_id = aws_vpc.my_vpc.id
    map_public_ip_on_launch = false
}

resource "aws_subnet" "privateSubnet" {
    availability_zone = "us-east-1a"
    cidr_block = "10.0.2.0/24"
    vpc_id = aws_vpc.my_vpc.id
    map_public_ip_on_launch = false
}

resource "aws_internet_gateway" "publicInternetGateway" {
    tags = {
        Name = "blockchain-igw"
    }
    vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "publicRouteTable" {
    vpc_id = aws_vpc.my_vpc.id
    tags = {
        Name = "blockchain-rtb-public"
    }
}

resource "aws_route_table" "privateRouteTable" {
    vpc_id = aws_vpc.my_vpc.id
    tags = {
        Name = "blockchain-rtb-private"
    }
}

resource "aws_route" "publicRoute" {
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.publicInternetGateway.id
    route_table_id = aws_route_table.publicRouteTable.id
}

resource "aws_route" "privateRoute" {
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natGateway.id
    route_table_id = aws_route_table.privateRouteTable.id
}

resource "aws_nat_gateway" "natGateway" {
    subnet_id = aws_subnet.publicSubnet.id
    tags = {
        Name = "blockchain-nat-public1-us-east-1a"
    }
    allocation_id = aws_eip.my_eip.id
}
resource "aws_eip" "my_eip" {
  vpc = true
}

resource "aws_route_table_association" "publicRouteTableAssociation" {
    route_table_id = aws_route_table.publicRouteTable.id
    subnet_id = aws_subnet.publicSubnet.id
}

resource "aws_route_table_association" "privateRouteTableAssociation" {
    route_table_id = aws_route_table.privateRouteTable.id
    subnet_id = aws_subnet.privateSubnet.id
}

resource "aws_security_group" "GetNextBlockLambdaSecurityGroup" {
    description = "GetNextBlockLambdaSecurityGroup"
    name = "GetNextBlockLambdaSecurityGroup"
    tags = {}
    vpc_id = aws_vpc.my_vpc.id
    egress {
        cidr_blocks = [
            "0.0.0.0/0"
        ]
        description = "allow send http request"
        from_port = 80
        protocol = "tcp"
        to_port = 80
    }
    egress {
        cidr_blocks = [
            "0.0.0.0/0"
        ]
        description = "allow send https request"
        from_port = 443
        protocol = "tcp"
        to_port = 443
    }
}