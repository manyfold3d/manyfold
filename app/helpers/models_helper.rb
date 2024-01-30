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
    badges << content_tag(:span, icon("bi bi-stars", t("general.new")), class: "text-warning align-middle") if model.new?
    badges << problem_icon(model.problems_including_files)
    content_tag :span, safe_join(badges, " "), class: "status-badges"
  end

  def license_select_options(selected: nil)
    # Generate a list of select options for select with a set of useful licenses
    options_for_select(
      %w[
        CC-BY-4.0
        CC-BY-NC-4.0
        CC-BY-ND-4.0
        CC-BY-NC-ND-4.0
        CC-BY-NC-SA-4.0
        CC-BY-SA-4.0
        CC-PDDC
        CC0-1.0
        MIT
        LicenseRef-Commercial
      ].map { |id|
        [
          t_license(id),
          id
        ]
      },
      selected: selected
    )
  end

  def t_license(license)
    t("licenses.%{id}" % {id: license.delete(".")}, default: license)
  end
end
