module PathBuilder
  extend ActiveSupport::Concern

  def formatted_path
    SiteSettings.model_path_template.gsub(/{.+?}/) do |token|
      case token
      when "{tags}"
        (tags.count > 0) ?
          File.join(tags.order(taggings_count: :desc).map(&:to_s).map(&:parameterize)) :
          "@untagged"
      when "{creator}"
        creator&.name || "@unattributed"
      when "{collection}"
        (collections.count > 0) ?
          collections.map(&:name).join(",") :
          "@uncollected"
      when "{modelName}"
        name.parameterize
      when "{modelId}"
        "##{id}"
      else
        token
      end
    end
  end
end
