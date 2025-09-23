class Components::Avatar < Components::Base
  def initialize(url:, size: nil)
    @url = url
    @size = size
  end

  def view_template
    classes = ["avatar"]
    classes << "avatar-lg" if @size == :large
    classes << "avatar-sm" if @size == :small
    img src: @url, class: classes.join(" ")
  end
end
