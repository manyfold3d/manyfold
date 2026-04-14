module ModelsHelper
  def group(files)
    return {} if files.empty?
    sections = {}
    min_section_size = [2, (files.count * 0.05).round].max
    min_prefix_length = 3
    names = files.map { |it| it.filename.downcase }
    slice = names.map(&:length).max
    while slice > min_prefix_length
      slice -= 1
      candidates = names.map { |it| it.slice(0, slice) }
      groups = candidates.group_by { |it| it }
      ready = groups.select { |k, v| v.count >= min_section_size }.map(&:first)
      ready.each do |r|
        names.reject! { |it| it.starts_with? r }
        sections[r], files = files.partition { |it| it.filename.downcase.starts_with? r }
      end
    end
    # Sort and include empty set
    {nil => files}.merge sections.sort_by { |k, v| k }.to_h
  end

  def problems_including_files(model)
    policy_scope(Problem).where(problematic: policy_scope(model.model_files) + [self])
  end

  def license_select_options(selected: nil)
    # Generate a list of select options for select with a set of useful licenses
    options_for_select(
      [
        "CC-BY-4.0", # i18n-tasks-use t('licenses.CC-BY-40')
        "CC-BY-NC-4.0", # i18n-tasks-use t('licenses.CC-BY-NC-40')
        "CC-BY-ND-4.0", # i18n-tasks-use t('licenses.CC-BY-ND-40')
        "CC-BY-NC-ND-4.0", # i18n-tasks-use t('licenses.CC-BY-NC-ND-40')
        "CC-BY-NC-SA-4.0", # i18n-tasks-use t('licenses.CC-BY-NC-SA-40')
        "CC-BY-SA-4.0", # i18n-tasks-use t('licenses.CC-BY-SA-40')
        "CC-PDDC", # i18n-tasks-use t('licenses.CC-PDDC')
        "CC0-1.0", # i18n-tasks-use t('licenses.CC0-10')
        "CERN-OHL-P-2.0", # i18n-tasks-use t('licenses.CERN-OHL-P-20')
        "CERN-OHL-S-2.0", # i18n-tasks-use t('licenses.CERN-OHL-S-20')
        "CERN-OHL-W-2.0", # i18n-tasks-use t('licenses.CERN-OHL-W-20')
        "MIT", # i18n-tasks-use t('licenses.MIT')
        "GPL-2.0-only", # i18n-tasks-use t('licenses.GPL-20-only')
        "GPL-3.0-only", # i18n-tasks-use t('licenses.GPL-30-only')
        "LGPL-2.0-only", # i18n-tasks-use t('licenses.LGPL-20-only')
        "LGPL-3.0-only", # i18n-tasks-use t('licenses.LGPL-30-only')
        "0BSD", # i18n-tasks-use t('licenses.0BSD')
        "LicenseRef-Commercial" # i18n-tasks-use t('licenses.LicenseRef-Commercial')
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
