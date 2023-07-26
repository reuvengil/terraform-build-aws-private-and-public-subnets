resource "aws_lambda_layer_version" "HealthCheckLambdaLayerVersion" {
  layer_name  = "node_modules"
  description = "node_modulesLayer"
  compatible_runtimes = [
    "nodejs18.x"
  ]
  filename         = "zips/node_modules.zip"
  source_code_hash = filebase64sha256("zips/node_modules.zip")
}

resource "aws_iam_role" "HealthCheckLambdaRole" {
  name = "HealthCheckLambdaRole"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Statement1",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole",
      }
    ]
  })
}
resource "aws_lambda_function" "HealthCheckLambda" {
  description   = ""
  function_name = "HealthCheckLambda"
  handler       = "index.handler"
  architectures = [
    "x86_64"
  ]
  role    = aws_iam_role.HealthCheckLambdaRole.arn
  runtime = "nodejs18.x"
  timeout = 3
  layers = [
    aws_lambda_layer_version.HealthCheckLambdaLayerVersion.arn
  ]

  filename         = "zips/HealthCheckLambda.zip"
  source_code_hash = filebase64sha256("zips/HealthCheckLambda.zip")
}

# ----------
resource "aws_cloudwatch_event_target" "eventTarget" {
  arn  = aws_lambda_function.HealthCheckLambda.arn
  rule = aws_cloudwatch_event_rule.triggerLambda.id
}
resource "aws_cloudwatch_event_rule" "triggerLambda" {
  name                = "triggerLambda"
  description         = "triggerLambda"
  schedule_expression = "rate(1 minute)"
}
resource "aws_lambda_permission" "EventBridgeLambdaPremission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.HealthCheckLambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.triggerLambda.arn
}
resource "aws_iam_policy" "LambdaPolicy" {
  policy = <<POLICY4
{
"Version" : "2012-10-17",
"Statement" : [
        {
            "Effect" : "Allow",
            "Action" : [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource" : "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.HealthCheckLambda.function_name}:*:*"
        }
    ]
}
POLICY4
}
resource "aws_iam_policy_attachment" "LambdaPolicyAttachment" {
  name       = "LambdaPolicyAttachment"
  roles      = [aws_iam_role.HealthCheckLambdaRole.name]
  policy_arn = aws_iam_policy.LambdaPolicy.arn
}
resource "aws_cloudwatch_log_group" "HealthCheckLogGroup" {
  name              = "/aws/lambda/${aws_lambda_function.HealthCheckLambda.function_name}"
  retention_in_days = 0
}
/*
# Create the EventBridge Rule
resource "aws_cloudwatch_event_rule" "console" {
  name        = "capture-aws-sign-in"
  description = "Capture each AWS Console Sign In"

  event_pattern = jsonencode({
    "detail-type" : ["AWS Console Sign In via CloudTrail"]
  })
}

# Create the EventBridge Rule Target to trigger the Lambda function
resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.console.name
  target_id = "SendToSNS"
  arn       = aws_lambda_function.HealthCheckLambda.arn
}
*/
