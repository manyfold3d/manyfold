xml.instruct!
xml.urlset "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
  "xsi:schemaLocation": "http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd",
  xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  xml.url { xml.loc creators_url }
  xml.url { xml.loc collections_url }
  xml.url { xml.loc models_url }
  @creators.each do |it|
    xml.url do
      xml.loc creator_url(it)
      xml.lastmod it.updated_at.iso8601
    end
  end
  @collections.each do |it|
    xml.url do
      xml.loc collection_url(it)
      xml.lastmod it.updated_at.iso8601
    end
  end
  @models.each do |it|
    xml.url do
      xml.loc model_url(it)
      xml.lastmod it.updated_at.iso8601
    end
  end
end
