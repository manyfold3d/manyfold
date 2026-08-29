# frozen_string_literal: true

require "rails_helper"

RSpec.describe TagListable, type: :controller do
  controller(ApplicationController) do
    include TagListable
    include Pundit::Authorization

    def index
      head :ok
    end
  end

  before do
    allow(controller).to receive(:policy_scope) { |scope| scope }
    allow(controller).to receive(:helpers).and_return(
      double( # ApplicationHelper is mixed into view context; ActionView::Base won't verify
        tag_cloud_settings: {"threshold" => 1, "sorting" => "frequency", "keypair" => false}
      )
    )
  end

  describe "#generate_tag_list" do
    it "does not load every model into memory for a Relation" do
      create(:model, tag_list: ["alpha"])
      create(:model, tag_list: ["beta"])
      scope = Model.all

      expect(scope).not_to receive(:map)
      expect(scope).not_to receive(:to_a)
      expect(scope).not_to receive(:load)

      tags, unrelated = controller.send(:generate_tag_list, scope)
      expect(unrelated).to eq 0
      expect(tags.pluck(:name)).to include("alpha", "beta")
    end

    it "preserves caber joins when building the id subquery" do
      create(:model, tag_list: ["delta"])
      # Simulate policy_scope.granted_to shape: includes + where on caber_relations
      scope = Model.includes(:caber_relations).references(:caber_relations)
      expect {
        tags, _ = controller.send(:generate_tag_list, scope)
        tags.load
      }.not_to raise_error
    end

    it "still accepts an Array of models" do
      model = create(:model, tag_list: ["gamma"])
      tags, _ = controller.send(:generate_tag_list, [model])
      expect(tags.pluck(:name)).to include("gamma")
    end

    it "limits the browse tag cloud so large libraries stay bounded" do
      create(:model, tag_list: ["alpha"])
      create(:model, tag_list: ["beta"])
      tags, _ = controller.send(:generate_tag_list, Model.all, limit: 1)
      expect(tags.limit_value).to eq 1
      expect(tags.to_a.size).to eq 1
    end
  end
end
