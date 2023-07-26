resource "aws_security_group" "HealthCheckLambdaSecurityGroup" {
  description = "HealthCheckLambdaSecurityGroup"
  name        = "HealthCheckLambdaSecurityGroup"
  tags        = {}
  vpc_id      = aws_vpc.my_vpc.id
  egress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    description = "allow send http request"
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }
  egress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    description = "allow send https request"
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
  }
}
