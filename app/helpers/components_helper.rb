module ComponentsHelper
  # ERB helpers that map directly to Phlex components
  # purely to make the syntax tidier

  def Icon(**args, &block)
    render Components::Icon.new(**args, &block)
  end

  def PreviewFrame(**args, &block)
    render Components::PreviewFrame.new(**args, &block)
  end

  def BurgerMenu(**args, &block)
    render Components::BurgerMenu.new(**args, &block)
  end

  def DropdownItem(**args, &block)
    render Components::DropdownItem.new(**args, &block)
  end

  def AccessIndicator(**args, &block)
    render Components::AccessIndicator.new(**args, &block)
  end
end
