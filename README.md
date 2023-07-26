# Terraform Build AWS Private & Public Subnets
First add aws Credentials by createing `secret.tfvars` file with the content:
```
aws_access_key = "your access key"
aws_secret_key = "your secret key"
```

Then run the commands:
```terraform
terraform init
terraform apply -var-file="secret.tfvars"
```
After creating a new cloud environments, you can check the Healthcheck result in the `cloudwatch` logs group with the name **`/aws/lambda/HealthCheckLambda`**.
