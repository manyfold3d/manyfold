# frozen_string_literal: true

module Components
  class Base < Phlex::HTML
    include Components

    # Include any helpers you want to be available across all components
    include Phlex::Rails::Helpers::Routes
    include Phlex::Rails::Helpers::Translate

    register_value_helper :current_user

    if Rails.env.development?
      def before_template
        comment { "Before #{self.class.name}" }
        super
      end
    end
  end
end
