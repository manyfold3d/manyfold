require "rails_helper"

RSpec.describe "/lists", :as_member do
  describe "GET /index" do
    before do
      create(:list)
    end

    it "renders a successful response" do
      get lists_url
      expect(response).to be_successful
    end
  end

  describe "GET /show", :as_member do
    let(:list) { create(:list, owner: User.last) }

    it "renders a successful response" do
      get list_url(list)
      expect(response).to be_successful
    end
  end

  describe "GET /new", :as_member do
    it "renders a successful response" do
      get new_list_url
      expect(response).to be_successful
    end
  end

  describe "GET /edit", :as_member do
    let(:list) { create(:list, owner: User.last) }

    it "renders a successful response" do
      get edit_list_url(list)
      expect(response).to be_successful
    end
  end

  describe "POST /create", :as_member do
    context "with valid parameters" do
      it "creates a new List" do
        expect {
          post lists_url, params: {list: attributes_for(:list)}
        }.to change(List, :count).by(1)
      end

      it "redirects to the created list" do
        post lists_url, params: {list: attributes_for(:list)}
        expect(response).to redirect_to(list_url(List.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new List" do
        expect {
          post lists_url, params: {list: {name: ""}}
        }.not_to change(List, :count)
      end

      it "renders a 422 response" do
        post lists_url, params: {list: {name: ""}}
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH /update", :as_member do
    let(:list) { create(:list, owner: User.last) }
    let(:model) { create(:model) }

    context "with valid parameters" do
      it "redirects to the list" do
        patch list_url(list), params: {list: attributes_for(:list)}
        list.reload
        expect(response).to redirect_to(list_url(list))
      end

      it "adds items" do
        expect {
          patch list_url(list), params: {list: {list_items_attributes: {"0" => {listable_type: "Model", listable_id: model.id}}}}
        }.to change { list.reload.models.count }.from(0).to(1)
      end

      it "removes items" do
        list.models << model
        item = list.list_items.last
        expect {
          patch list_url(list), params: {list: {list_items_attributes: {"0" => {id: item.id, _destroy: "1"}}}}
        }.to change { list.reload.models.count }.from(1).to(0)
      end
    end

    context "with invalid parameters" do
      it "renders a 422 response" do
        patch list_url(list), params: {list: {name: ""}}
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /destroy", :as_member do
    let!(:list) { create(:list, owner: User.last) }

    it "destroys the requested list" do
      expect { delete list_url(list) }.to change(List, :count).by(-1)
    end

    it "redirects to the lists list" do
      delete list_url(list)
      expect(response).to redirect_to(lists_url)
    end
  end
end
