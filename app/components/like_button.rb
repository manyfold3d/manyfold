# frozen_string_literal: true

class Components::LikeButton < Components::BaseButton
  def initialize(thing:, small: false)
    @thing = thing
    @small = small
  end

  def before_template
    @liked = current_user.liked?(@thing)
    @form_attributes = @liked ?
      {id: current_user.liked_list.list_items.find_by(listable: @thing), _destroy: "1"} :
      {listable_type: @thing.model_name, listable_id: @thing.id}
    @count = @thing.list_items.includes(:list).where("list.special": :liked).count
    @count = nil if @count == 0
  end

  def view_template
    DoButton(
      icon: (@liked ? "heart-fill" : "heart"),
      variant: :secondary,
      small: @small,
      href: list_path(current_user.liked_list, list: {list_items_attributes: {"0" => @form_attributes}}),
      method: :patch,
      label: @count,
      help: (@liked ? t("components.like_button.unlike") : t("components.like_button.like"))
    )
  end
end
