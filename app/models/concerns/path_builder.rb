module PathBuilder
  extend ActiveSupport::Concern

  def formatted_path
    SiteSettings.model_path_template.gsub(/{.+?}/) do |token|
      case token
      when "{tags}"
        tags.exists? ?
          File.join(tags.order(taggings_count: :desc, name: :asc).map { |it| it.to_s.parameterize }) :
          "@untagged"
      when "{creator}"
        path_component(creator) || "@unattributed"
      when "{collection}"
        path_component(collection) || "@uncollected"
      when "{modelName}"
        path_component(self)
      when "{modelId}"
        "##{id}"
      else
        token
      end
    end
  end

  private

  def path_component(object)
    return nil if object.nil?
    SiteSettings.safe_folder_names ? object.slug : object.name
  end
end
