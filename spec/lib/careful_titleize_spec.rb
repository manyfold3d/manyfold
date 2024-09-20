require "rails_helper"

RSpec.describe CarefulTitleize do
  [
    "Death Star II",
    "README.txt",
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
    "death_star_II" => "Death Star II",
    "will.i.am" => "Will.i.am"
  }.each_pair do |input, output|
    it "titleizes '#{input}' to '#{output}'" do
      expect(input.careful_titleize).to eq output
    end
  end
end
