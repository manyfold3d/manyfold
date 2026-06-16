xml.instruct!
xml.urlset "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
  "xsi:schemaLocation": "http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd",
  xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  xml.url { xml.loc creators_url }
  xml.url { xml.loc collections_url }
  xml.url { xml.loc models_url }
  @creators.each do |creator|
    xml.url do
      xml.loc creator_url(creator)
      xml.lastmod creator.updated_at.iso8601
    end
  end
  @collections.each do |collection|
    xml.url do
      xml.loc collection_url(collection)
      xml.lastmod collection.updated_at.iso8601
    end
  end
  @models.each do |model|
    xml.url do
      xml.loc model_url(model)
      xml.lastmod model.updated_at.iso8601
    end
  end
end
