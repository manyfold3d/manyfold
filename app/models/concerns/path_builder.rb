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
        safe(creator&.name) || "@unattributed"
      when "{collection}"
        (collections.count > 0) ?
          collections.map(&:name).map { |s| safe(s) }.join(",") :
          "@uncollected"
      when "{modelName}"
        safe(name)
      when "{modelId}"
        "##{id}"
      else
        token
      end
    end
  end

  private

  def safe(str)
    SiteSettings.safe_folder_names ? str&.parameterize : str
  end
end
