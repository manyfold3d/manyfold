module ComponentsHelper
  # ERB helpers that map directly to Phlex components
  # purely to make the syntax tidier

  def Icon(icon:, id: nil, label: nil, effect: nil, role: "img")
    render Components::Icon.new(icon: icon, id: id, label: label, effect: effect, role: role)
  end
end
