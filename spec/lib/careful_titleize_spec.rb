require "rails_helper"

RSpec.describe CarefulTitleize do
  [
    "Death Star II",
    "camelCase",
    "OpenGL",
    "3MF",
    "Object3D"
  ].each do |input|
    it "leaves '#{input}' unchanged" do
      expect(input.careful_titleize).to eq input
    end
  end

  {
    "all along the watchtower" => "All Along The Watchtower",
    "left_hand_3" => "Left Hand 3",
    "death_star_II" => "Death Star II"
  }.each_pair do |input, output|
    it "titleizes '#{input}' to '#{output}'" do
      expect(input.careful_titleize).to eq output
    end
  end
end
