ActionDispatch::IntegrationTest.register_encoder :manyfold_api_v0,
  param_encoder: ->(params) { params.to_json },
  response_parser: ->(body) { JSON.parse(body) }
