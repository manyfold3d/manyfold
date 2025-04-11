ActionDispatch::Request.parameter_parsers[:manyfold_api_v0] = ->(body) {
  {json: JSON.parse(body)}
}
