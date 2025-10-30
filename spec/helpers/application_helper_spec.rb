require "rails_helper"

RSpec.describe ApplicationHelper do
  describe "#icon" do
    it "returns the correct HTML for the icon" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
      html = helper.icon(icon: "test", label: "Test Label")
      doc = Nokogiri::HTML(html)
      expect(doc.at("i")["class"]).to eq("bi bi-test")
      expect(doc.at("i")["role"]).to eq("img")
      expect(doc.at("i")["title"]).to eq("Test Label")
    end

    it "supports RPG-awesome icons" do
      html = helper.icon(icon: "ra-test", label: "Test Label")
      doc = Nokogiri::HTML(html)
      expect(doc.at("i")["class"]).to eq("ra ra-test")
    end
  end

  describe "#card" do
    it "returns the correct HTML for the card" do # rubocop:todo RSpec/MultipleExpectations
      html = helper.card("test", "Test Title") { "Test Content" }
      doc = Nokogiri::HTML(html)
      expect(doc.at("div.card")["class"]).to include("card mb-4")
      expect(doc.at("div.card-header")["class"]).to include("text-white bg-test")
      expect(doc.at("div.card-text").text).to eq("Test Content")
    end
  end

  describe "#text_input_row" do
    it "returns the correct HTML for the text input row" do # rubocop:todo RSpec/MultipleExpectations
      form = ActionView::Helpers::FormBuilder.new(:test, nil, helper, {})
      html = helper.text_input_row(form, :field)
      doc = Nokogiri::HTML(html)
      expect(doc.at("input")["class"]).to include("form-control")
    end
  end

  describe "#rich_text_input_row" do
    it "returns the correct HTML for the rich text input row" do # rubocop:todo RSpec/MultipleExpectations
      form = ActionView::Helpers::FormBuilder.new(:test, nil, helper, {})
      html = helper.rich_text_input_row(form, :field)
      doc = Nokogiri::HTML(html)
      expect(doc.at("textarea")["class"]).to include("form-control")
    end
  end

  describe "#nav_link" do
    it "returns the correct HTML for the navigation link" do # rubocop:todo RSpec/MultipleExpectations
      html = helper.nav_link("test", "Test Text", "/")
      doc = Nokogiri::HTML(html)
      expect(doc.at("a")["class"]).to include("nav-link")
      expect(doc.css("span")[1].text).to eq("Test Text")
    end
  end
end
