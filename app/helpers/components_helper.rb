module ComponentsHelper
  # Dynamically map ERB helpers directly to Phlex components
  # This defines a helper named exactly the same as the Phlex class
  # e.g. Components::Icon maps to the helper method Icon() with the same capitalisation
  Components.constants.each do |constant|
    define_method constant do |**args, &block|
      render Components.const_get(constant).new(**args, &block)
    end
  end
end
