# frozen_string_literal: true

class Views::Groups::Index < Views::Base
  def initialize(creator:, groups:)
    @creator = creator
    @groups = groups
  end

  def view_template
    h1 { "Groups::Index" }
    p { "Find me in app/views/groups/index.rb" }
  end
end
