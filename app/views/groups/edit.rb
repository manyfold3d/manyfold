# frozen_string_literal: true

class Views::Groups::Edit < Views::Base
  def initialize(creator:, group:)
    @creator = creator
    @group = group
  end

  def view_template
    h1 { "Groups::Edit" }
    p { "Find me in app/views/groups/edit.rb" }
  end
end
