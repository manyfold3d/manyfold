module PathBuilder
  extend ActiveSupport::Concern

  def formatted_path
    formatted_path_out = []
    SiteSettings.model_path_prefix_template.split("/").each { |p|
      case p
      when "{tags}"
        formatted_path_out.push(tags.order(taggings_count: :desc).map(&:to_s).map(&:parameterize))
      when "{creator}"
        formatted_path_out.push(creator ? creator.name : "unset-creator")
      when "{collection}"
        formatted_path_out.push((collections.count > 0) ? collections.map { |c| c.name } : "unset-collection")
      else
        formatted_path_out.push("bad-formatted-path-element")
      end
    }
    File.join("", formatted_path_out, name.parameterize) + (SiteSettings.model_path_suffix_model_id ? "##{id}" : "")
  end
end
