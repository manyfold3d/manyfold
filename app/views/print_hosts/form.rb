# frozen_string_literal: true

module Views::PrintHosts
  class Form < Views::Base
    include Phlex::Rails::Helpers::FormWith

    def initialize(print_host:)
      @print_host = print_host
    end

    def view_template
      # Using an ERB form otherwise coccooned doesn't work and we might want it later
      render partial("form", print_host: @print_host)
    end
  end
end
