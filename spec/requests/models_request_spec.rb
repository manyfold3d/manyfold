require "rails_helper"

RSpec.describe "Models", type: :request do
  before :all do
    @library = FactoryBot.create(:library) do |library|
      FactoryBot.create_list(:model, 11, library: library)
    end
  end

  describe "GET /libraries/1/models/1" do
    it "returns http success" do
      get "/libraries/1/models/1"
      expect(response).to have_http_status(:success)
    end
  end

  describe "PUT /libraries/1/models/1" do
    it "adds tags to a model" do
      p @library.inspect
      put "/libraries/#{@library.id}/models/#{@library.models.first.id}", params: {model: {tags: "a, b, c"}}
      expect(response).to have_http_status(:redirect)
      tags = @library.models.first.tag_list
      expect(tags.length).to eq 3
      expect(tags[0]).to eq "a"
      expect(tags[1]).to eq "b"
      expect(tags[2]).to eq "c"
    end

    it "removes tags from a model" do
      p @library.inspect
      @library.models.first.tag_list = "a, b, c"
      put "/libraries/#{@library.id}/models/#{@library.models.first.id}", params: {model: {tags: "a, b"}}
      expect(response).to have_http_status(:redirect)
      tags = @library.models.first.tag_list
      expect(tags.length).to eq 2
      expect(tags[0]).to eq "a"
      expect(tags[1]).to eq "b"
    end

    it "both adds and removes tags from a model" do
      p @library.inspect
      @library.models.first.tag_list = "a, b, c"
      put "/libraries/#{@library.id}/models/#{@library.models.first.id}", params: {model: {tags: "a, b, d"}}
      expect(response).to have_http_status(:redirect)
      tags = @library.models.first.tag_list
      expect(tags.length).to eq 3
      expect(tags[0]).to eq "a"
      expect(tags[1]).to eq "b"
      expect(tags[2]).to eq "d"
    end
  end
end
