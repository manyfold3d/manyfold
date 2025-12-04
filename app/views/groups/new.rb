# frozen_string_literal: true

class Views::Groups::New < Views::Base
  def initialize(creator:, group:)
    @creator = creator
    @group = group
  end

  def view_template
    h1 { "Groups::New" }
    p { "Find me in app/views/groups/new.rb" }
  end
end
