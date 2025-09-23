class Integrations::Cults3d::ModelDeserializer < Integrations::Cults3d::BaseDeserializer
  attr_reader :object_slug

  def deserialize
    return {} unless valid?
    result = self.class.client.query <<~GRAPHQL
      {
        creation(slug: "#{@object_slug}") {
          name
          description
          license {
            spdxId
          }
          safe
          tags
          illustrationImageUrl
          illustrations {
            imageUrl
          }
          creator {
            nick
            bio
            url
            imageUrl
          }
        }
      }
    GRAPHQL
    raise Faraday::ResourceNotFound.new("Not Found") unless result.data&.creation
    {
      name: result.data&.creation&.name,
      slug: @object_slug,
      notes: result.data&.creation&.description,
      tag_list: result.data&.creation&.tags.to_a,
      sensitive: result.data&.creation&.safe == false,
      file_urls: result.data&.creation&.illustrations&.map { |it| {url: it.image_url.split("()/").last, filename: filename_from_url(it.image_url.split("()/").last)} },
      preview_filename: filename_from_url(result.data&.creation&.illustration_image_url),
      license: result.data&.creation&.license&.spdx_id
    }.merge(creator_attributes(result&.data&.creation&.creator))
  end

  def capabilities
    {
      class: Model,
      name: true,
      notes: true,
      images: true,
      model_files: false,
      creator: true,
      tags: true,
      sensitive: true,
      license: true
    }
  end

  private

  def valid_path?(path)
    match = /\A\/#{PATH_COMPONENTS[:locale]}\/#{PATH_COMPONENTS[:model]}\/#{PATH_COMPONENTS[:category]}\/#{PATH_COMPONENTS[:model_slug]}\Z/.match(path)
    @object_slug = match[:model_slug] if match.present?
    match.present?
  end

  def creator_attributes(creator)
    return {} unless creator
    attempt_creator_match(Integrations::Cults3d::CreatorDeserializer.parse(creator))
  end
end
