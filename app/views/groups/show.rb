# frozen_string_literal: true

class Views::Groups::Show < Views::Base
  def initialize(creator:, group:)
    @creator = creator
    @group = group
  end

  def view_template
    h1 { "Groups::Show" }
    p { "Find me in app/views/groups/show.rb" }
  end
end
