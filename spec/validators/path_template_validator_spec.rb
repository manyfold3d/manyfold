# frozen_string_literal: true

require "rails_helper"

RSpec.describe PathTemplateValidator do
  subject(:validator) { described_class.new({attributes: {any: true}}) }

  let(:errors) { ActiveModel::Errors.new(subject) }
  let(:record) { instance_double(ActiveModel::Validations, errors: errors) }

  describe "#validate_each(record, attribute, value)" do
    it "doesn't add error to record if the template includes only valid tokens" do
      expect {
        validator.validate_each(record, :test, "testing/{tags}/{modelName}{modelId}")
      }.not_to change(record.errors, :count)
    end

    it "adds error to record if the template includes invalid tokens" do
      expect {
        validator.validate_each(record, :test, "testing/{tag}/{modelName}{modelId}")
      }.to change(record.errors, :count).from(0).to(1)
        .and change { record.errors.first&.type }.to eq(:invalid)
    end

    it "adds only one single error to record if the template includes multiple invalid tokens" do
      expect {
        validator.validate_each(record, :test, "testing/{tag}/{modelname}{modelid}")
      }.to change(record.errors, :count).from(0).to(1)
        .and change { record.errors.first&.type }.to eq(:invalid)
    end
  end
end
