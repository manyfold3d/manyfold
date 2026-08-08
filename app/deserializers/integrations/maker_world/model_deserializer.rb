class Integrations::MakerWorld::ModelDeserializer < Integrations::MakerWorld::BaseDeserializer
  attr_reader :model_id, :profile_id

  def deserialize
    return {} unless valid?

    design = fetch("design/#{CGI.escapeURIComponent(@model_id)}").body
    {
      name: design["title"],
      slug: design["title"]&.parameterize,
      notes: design["summary"],
      tag_list: tags_from(design),
      file_urls: file_urls_from(design),
      preview_filename: preview_filename_from(design),
      license: license_from(design)
    }.merge(creator_attributes(design))
  end

  def capabilities
    {
      class: Model,
      name: true,
      notes: true,
      images: true,
      model_files: download_configured?,
      creator: true,
      tags: true,
      sensitive: false,
      license: true
    }
  end

  private

  def tags_from(design)
    [
      Array.wrap(design["tags"]).filter_map { |tag| tag.is_a?(Hash) ? (tag["name"] || tag["tagName"]) : tag },
      Array.wrap(design["categories"]).filter_map { |category| category.is_a?(Hash) ? category["name"] : category }
    ].flatten.compact.uniq
  end

  def file_urls_from(design)
    [
      image_urls_from(design),
      download_url_from(design)
    ].flatten.compact
  end

  def image_urls_from(design)
    urls = [
      design["coverUrl"],
      design["cover"],
      design["thumbnail"],
      Array.wrap(design["pictures"]).filter_map { |picture| picture.is_a?(Hash) ? (picture["url"] || picture["imageUrl"]) : picture },
      Array.wrap(design["images"]).filter_map { |image| image.is_a?(Hash) ? (image["url"] || image["imageUrl"]) : image }
    ].flatten.compact.uniq

    urls.filter_map { |url| {url: url, filename: File.join("images", filename_from_url(url))} if filename_from_url(url).present? }
  end

  def download_url_from(design)
    return unless download_configured?

    profile_id = selected_profile_id(design)
    model_id = design["modelId"]
    return if profile_id.blank? || model_id.blank?

    manifest = fetch_download(profile_id: profile_id, model_id: model_id).body
    url = manifest["url"]
    return if url.blank?

    filename = manifest["filename"].presence || manifest["name"].presence || "#{design["title"].presence || "makerworld-#{@model_id}"}.3mf"
    {url: url, filename: File.join("files", File.basename(CGI.unescape(filename)))}
  end

  def preview_filename_from(design)
    url = design["coverUrl"] || design["cover"] || design["thumbnail"]
    File.join("images", filename_from_url(url)) if filename_from_url(url).present?
  end

  def license_from(design)
    license = design["license"]
    value = design.dig("licenseInfo", "spdxId")
    value ||= license["spdxId"] if license.is_a?(Hash)
    value ||= license
    value if value.is_a?(String) && value.match?(/\A[A-Za-z0-9.-]+\z/)
  end

  def creator_attributes(design)
    creator = creator_from(design)
    return {} unless creator.is_a?(Hash)

    name = creator_name(creator)
    return {} if name.blank?

    attributes = {
      name: name,
      slug: name.parameterize
    }
    url = creator_url(creator)
    attributes[:links_attributes] = [{url: url}] if url.present?
    attempt_creator_match(attributes)
  end

  def creator_from(design)
    design["designer"] || design["user"] || design["creator"]
  end

  def creator_name(creator)
    creator["name"] || creator["nickname"] || creator["handle"] || creator["userName"]
  end

  def creator_url(creator)
    creator["profileUrl"] || creator["url"] || creator_handle_url(creator)
  end

  def creator_handle_url(creator)
    handle = creator["handle"] || creator["userName"]
    "https://makerworld.com/en/@#{handle}" if handle.present?
  end
end
