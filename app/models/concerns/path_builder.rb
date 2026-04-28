module PathBuilder
  extend ActiveSupport::Concern

  def formatted_path
    library.path_template.gsub(/{.+?}/) do |token|
      case token
      when "{tags}"
        tags.exists? ?
          File.join(tags.order(taggings_count: :desc, name: :asc).map { |it| it.to_s.parameterize }) :
          "@untagged"
      when "{creator}"
        path_component(creator) || "@unattributed"
      when "{collection}"
        path_component(collections.order(created_at: :asc).first) || "@uncollected"
      when "{collections}"
        scope = collections.order(models_count: :desc, name: :asc)
        File.join(scope.map { |it| path_component(it) })
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
    (library.safe_folder_names ? object.slug : object.name).first(ApplicationRecord::SAFE_NAME_LENGTH[:maximum])
  end
end
