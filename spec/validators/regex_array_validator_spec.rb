# frozen_string_literal: true

require "rails_helper"

RSpec.describe RegexArrayValidator do
  subject { RegexArrayValidator.new({attributes: {any: true}}) }

  let(:errors) { ActiveModel::Errors.new(subject) }

  let(:record) { instance_double(ActiveModel::Validations, errors: errors) }

  let(:array_of_regexes) {
    %w[
          /^\.[^\.]+/
          /.*\/@eaDir\/.*/
          /__MACOSX/
        ]
  }

  describe "#validate_each(record, attribute, value)" do
    it "adds error to invalid record when the array has an invalid regex" do
      array_of_regexes.push "INVALID_REGEX"
      expect {
        subject.validate_each(record, :model_ignore_files, array_of_regexes)
      }.to change(record.errors, :count)
        .and change {record.errors.first&.type}.to eq(:invalid)
    end

    it "does not add error to invalid record when array contains only regexes" do
      puts array_of_regexes.inspect
      expect {
        subject.validate_each(record, :model_ignore_files, array_of_regexes)
      }.not_to change(record.errors, :count)
    end
  end
end
