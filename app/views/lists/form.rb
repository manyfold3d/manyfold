# frozen_string_literal: true

class Views::Lists::Form < Views::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(list:)
    @list = list
  end

  def view_template
    # Using an ERB form otherwise coccooned doesn't work
    render partial("form", list: @list)
  end
end
