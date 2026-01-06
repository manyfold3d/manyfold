# frozen_string_literal: true

class Views::Groups::Form < Views::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(creator:, group:)
    @creator = creator
    @group = group
  end

  def before_template
    @group.memberships.build if @group.memberships.empty?
  end

  def view_template
    # Using an ERB form otherwise coccooned doesn't work
    render partial("form", creator: @creator, group: @group)
  end
end
