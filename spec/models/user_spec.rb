require "rails_helper"

RSpec.describe User, type: :model do
  describe '#method_name' do
    context 'when condition A' do
      it 'does something' do
        user = create(:user)
        result = user.method_name
        expect(result).to eq(expected_result)
      end
    end

    context 'when condition B' do
      it 'does something else' do
        user = create(:user)
        result = user.method_name
        expect(result).to eq(expected_result)
      end
    end
  end
end
