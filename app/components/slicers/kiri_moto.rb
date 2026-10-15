# frozen_string_literal: true

class Components::Slicers::KiriMoto < Components::Base
  def initialize(file:)
    @file = file
  end

  def view_template
    iframe class: "slicer", src: "https://grid.space/kiri"
  end
end
