require "rails_helper"

RSpec.describe "Groups", :after_first_run do
  let(:owner) { create(:user) }
  let(:creator) { create(:creator, owner: owner) }

  context "when signed in as an owner of the creator" do
    before do
      sign_in owner
    end

    describe "GET /creators/{creator_id}/groups" do
      before { create(:group, creator: creator) }

      it "shows a group list for a creator" do
        get "/creators/#{creator.to_param}/groups"
        expect(response).to have_http_status :success
      end
    end

    describe "GET /creators/{creator_id}/groups/new" do
      it "shows new group form" do
        get "/creators/#{creator.to_param}/groups/new"
        expect(response).to have_http_status :success
      end
    end

    describe "POST /creators/{creator_id}/groups" do
      let(:user) { create(:user) }
      let(:params) { {group: {name: "Group name", memberships_attributes: {"0" => {user_id: user.username}}}} }

      it "creates new group" do
        expect { post "/creators/#{creator.to_param}/groups", params: params }.to change(Group, :count).by(1)
      end

      it "sets name" do
        post "/creators/#{creator.to_param}/groups", params: params
        expect(Group.last.name).to eq "Group name"
      end

      it "adds members" do
        post "/creators/#{creator.to_param}/groups", params: params
        expect(Group.last.members).to include user
      end

      it "redirects to list" do
        post "/creators/#{creator.to_param}/groups", params: params
        expect(response).to redirect_to("/creators/#{creator.to_param}/groups")
      end

      it "gives a 422 response if the data is invalid" do
        post "/creators/#{creator.to_param}/groups", params: {group: {name: nil}}
        expect(response).to have_http_status :unprocessable_content
      end
    end

    describe "GET /creators/{creator_id}/groups/{id}/edit" do
      let(:group) { create(:group, creator: creator) }

      it "shows group edit form" do
        get "/creators/#{creator.to_param}/groups/#{group.to_param}/edit"
        expect(response).to have_http_status :success
      end
    end

    describe "PATCH /creators/{creator_id}/groups/{id}" do
      let(:user) { create(:user) }
      let(:group) { create(:group, creator: creator) }
      let(:params) { {group: {name: "Group name", memberships_attributes: {"0" => {user_id: user.username}}}} }

      it "redirects back to list" do
        patch "/creators/#{creator.to_param}/groups/#{group.to_param}", params: params
        expect(response).to redirect_to("/creators/#{creator.to_param}/groups")
      end

      it "sets name" do
        patch "/creators/#{creator.to_param}/groups/#{group.to_param}", params: params
        expect(group.reload.name).to eq "Group name"
      end

      it "adds members by username" do
        patch "/creators/#{creator.to_param}/groups/#{group.to_param}", params: params
        expect(group.reload.members).to include(user)
      end

      it "adds members by ID" do
        id_params = {group: {memberships_attributes: {"0" => {user_id: user.id}}}}
        patch "/creators/#{creator.to_param}/groups/#{group.to_param}", params: id_params
        expect(group.reload.members).to include(user)
      end

      it "adds members by email" do
        id_params = {group: {memberships_attributes: {"0" => {user_id: user.email}}}}
        patch "/creators/#{creator.to_param}/groups/#{group.to_param}", params: id_params
        expect(group.reload.members).to include(user)
      end

      it "removes memberships" do
        group.members << user
        remove_params = {group: {memberships_attributes: {"0" => {id: group.memberships.last.id, _destroy: "1"}}}}
        patch "/creators/#{creator.to_param}/groups/#{group.to_param}", params: remove_params
        expect(group.reload.members).not_to include(user)
      end

      it "gives a 422 response if the data is invalid" do
        patch "/creators/#{creator.to_param}/groups/#{group.to_param}", params: {group: {name: nil}}
        expect(response).to have_http_status :unprocessable_content
      end
    end

    describe "DELETE /creators/{creator_id}/groups/{id}" do
      let!(:group) { create(:group, creator: creator) }

      it "removes group" do
        expect {
          delete "/creators/#{creator.to_param}/groups/#{group.to_param}"
        }.to change(Group, :count).by(-1)
      end

      it "redirects to list" do
        delete "/creators/#{creator.to_param}/groups/#{group.to_param}"
        expect(response).to redirect_to "/creators/#{creator.to_param}/groups"
      end
    end
  end

  context "when signed in as a moderator" do
    let(:group) { create(:group, creator: creator) }

    before do
      sign_in create :moderator
    end

    describe "GET /creators/{creator_id}/groups" do
      it "shows a group list for a creator" do
        get "/creators/#{creator.to_param}/groups"
        expect(response).to have_http_status :success
      end
    end
  end

  context "when signed in as a member" do
    let(:group) { create(:group, creator: creator) }

    before do
      sign_in create :user
    end

    describe "GET /creators/{creator_id}/groups" do
      it "doesn't show group list" do
        get "/creators/#{creator.to_param}/groups"
        expect(response).to have_http_status :forbidden
      end
    end
  end
end
