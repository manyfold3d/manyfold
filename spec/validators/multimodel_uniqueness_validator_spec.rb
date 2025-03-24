# frozen_string_literal: true

require "rails_helper"

RSpec.describe MultimodelUniquenessValidator do
  before do
    create(:creator, public_id: "abc123")
    create(:collection, public_id: "DEF456")
    create(:model, public_id: "ghi789")
  end

  context "when in case sensitive mode (default)" do
    with_model :Thing do
      table do |t|
        t.string :public_id
      end
      model do
        validates :public_id, multimodel_uniqueness: {check: {creator: :public_id, collection: :public_id}}
      end
    end

    it "adds error if value is present in one of checked models" do
      thing = Thing.new(public_id: "abc123")
      thing.validate
      expect(thing.errors).to be_of_kind(:public_id, :taken)
    end

    it "does not add error if value is in an unchecked model" do
      thing = Thing.new(public_id: "ghi789")
      expect(thing).to be_valid
    end

    it "does not add error if value is present but different case" do
      thing = Thing.new(public_id: "def456")
      expect(thing).to be_valid
    end

    it "does not add error if value is unique" do
      thing = Thing.new(public_id: "cba321")
      expect(thing).to be_valid
    end
  end

  context "when in case insensitive mode" do
    with_model :Thing do
      table do |t|
        t.string :public_id
      end
      model do
        validates :public_id, multimodel_uniqueness: {case_sensitive: false, check: {creator: :public_id, collection: :public_id}}
      end
    end

    it "adds error if value in uppercase is in one of checked models" do
      thing = Thing.new(public_id: "def456")
      thing.validate
      expect(thing.errors).to be_of_kind(:public_id, :taken)
    end
  end
end
