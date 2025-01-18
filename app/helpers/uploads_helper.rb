module UploadsHelper
  def library_select_title(l)
    title = [l.name]
    if current_user.is_administrator? && l.free_space
      title << translate("models.new.free_space",
        available: number_to_human_size(l.free_space),
        precision: 2)
    end
    title.join(" ")
  end

  def uploadable_file_extensions
    SupportedMimeTypes.indexable_extensions
  end

  def input_accept_string
    safe_join [
      uploadable_file_extensions.map { |it| Mime::EXTENSION_LOOKUP[it].to_s },
      uploadable_file_extensions.map { |it| ".#{it}" }
    ].uniq.flatten, ","
  end
end
