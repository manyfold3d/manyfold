module ModelsHelper
  def group(files)
    groups = files.group_by { |i| i.filename.split(/[\ _\-:.]/)[0] }
    ungrouped = []
    groups.each_pair do |group, p|
      ungrouped << groups.delete(group)[0] if p.count == 1
    end
    groups.merge(nil => ungrouped)
  end

  def status_badges(model)
    badges = []
    badges << content_tag(:span, "new", class: "badge rounded-pill bg-info") if model.tag_list.include? SiteSettings.model_tags_auto_tag_new
    badges << content_tag(:span, icon("exclamation-triangle-fill", "Problem"), class: "text-warning align-middle") unless model.problems.empty?
    content_tag :span, safe_join(badges), class: "status-badges"
  end
end
