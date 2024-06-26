module UploadsHelper
  def library_select_title(l)
    title = [l.name]
    if current_user.is_administrator?
      title << t("models.new.free_space",
        available: number_to_human_size(l.free_space),
        precision: 2)
    end
    title.join(" ")
  end

  def uploadable_file_extensions
    %w[zip rar 7z bz2 gz]
  end

  def input_accept_string
    safe_join [
      uploadable_file_extensions.map { |x| Mime::EXTENSION_LOOKUP[x].to_s },
      uploadable_file_extensions.map { |x| ".#{x}" }
    ].uniq.flatten, ","
  end
end
