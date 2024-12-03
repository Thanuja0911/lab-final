resource "aws_api_gateway_rest_api" "chat_api" {
  name        = "chatconnect-api"
  description = "API for ChatConnect backend services"
}

resource "aws_api_gateway_resource" "messages" {
  rest_api_id = aws_api_gateway_rest_api.chat_api.id
  parent_id   = aws_api_gateway_rest_api.chat_api.root_resource_id
  path_part   = "messages"
}

resource "aws_api_gateway_method" "messages_post" {
  rest_api_id   = aws_api_gateway_rest_api.chat_api.id
  resource_id   = aws_api_gateway_resource.messages.id
  http_method   = "POST"
  authorization = "NONE"

  request_models = {}
}

resource "aws_api_gateway_integration" "messages_post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.chat_api.id
  resource_id             = aws_api_gateway_resource.messages.id
  http_method             = aws_api_gateway_method.messages_post.http_method
  integration_http_method = "POST"
  type                    = "MOCK" 
}