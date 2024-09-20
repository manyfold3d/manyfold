require "rails_helper"

RSpec.describe CarefulTitleize do
  {
    "camelCase" => "camelCase",
    "README.txt" => "README.Txt",
    "death_star_II" => "Death Star II",
    "will.i.am" => "Will.i.am",
    "3jane tessier-ashpool" => "3Jane Tessier-Ashpool"
  }.each_pair do |input, output|
    it "titleizes '#{input}' to '#{output}'" do
      expect(input.careful_titleize).to eq output
    end
  end
end
