require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#icon' do
    it 'returns the correct HTML tag with the correct attributes' do
      # Arrange
      id = 'test'
      label = 'Test Label'

      # Act
      result = helper.icon(id, label)

      # Assert
      expect(result).to eq("<i class=\"bi bi-#{id}\" role=\"img\" aria-label=\"#{label}\" title=\"#{label}\"></i>")
    end
  end

  # Add similar describe and it blocks for the other methods in the ApplicationHelper module
end
