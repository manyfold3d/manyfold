ActionDispatch::IntegrationTest.register_encoder :json_ld,
  param_encoder: ->(params) { params.to_json },
  response_parser: ->(body) { JSON.parse(body) }
