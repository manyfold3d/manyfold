module UploadsHelper

  def library_select_title(l)
    title = [l.name]
    title << t(".free_space",
      available: number_to_human_size(l.free_space),
      precision: 2
    ) if (current_user.is_administrator?)
    title.join(" ")
  end

end
