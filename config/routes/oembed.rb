get("/oembed", to: redirect(status: 303) { |_, request|
  path = URI.parse(request.params[:url])&.path
  raise ActionController::BadRequest if path.blank?
  URI::HTTP.build(path: path + ".oembed", query: {
    maxwidth: request.params[:maxwidth],
    maxheight: request.params[:maxheight]
  }.compact.to_query)
})
