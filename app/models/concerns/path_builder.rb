module PathBuilder
  extend ActiveSupport::Concern

  def formatted_path
    path = SiteSettings.model_path_template.gsub(/{.+?}/) do |token|
      case token
      when "{tags}"
        (tags.count > 0) ?
          File.join(tags.order(taggings_count: :desc, name: :asc).map { |it| it.to_s.parameterize }) :
          "@untagged"
      when "{creator}"
        path_component(creator) || "@unattributed"
      when "{collection}"
        path_component(collection) || "@uncollected"
      when "{modelName}"
        path_component(self)
      when "{modelId}"
        "" # Deprecated, now always added below; kept for compatibility
      else
        token
      end
    end
    path + "##{id}"
  end

  private

  def path_component(object)
    return nil if object.nil?
    SiteSettings.safe_folder_names ? object.slug : object.name
  end
end
