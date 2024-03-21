require "rails_helper"
RSpec.describe Role do
  let(:user) { create(:user) }

  it "can be given to a user" do
    user.add_role :administrator
    expect(user.has_role?(:administrator)).to be true
  end

  it "must be from the allowed list" do # rubocop:disable RSpec/MultipleExpectations
    expect { user.add_role :batman }.to raise_error(ActiveRecord::RecordInvalid)
    expect(user.has_role?(:batman)).to be false
  end

  context "when administrator" do
    let(:admin) { create(:admin) }

    it "has administrator permission" do
      expect(admin.is_administrator?).to be true
    end

    it "inherits editor permission" do
      expect(admin.is_editor?).to be true
    end

    it "inherits contributor permission" do
      expect(admin.is_contributor?).to be true
    end

    it "inherits viewer permission" do
      expect(admin.is_viewer?).to be true
    end
  end

  context "when editor" do
    let(:editor) { create(:editor) }

    it "does not have administrator permission" do
      expect(editor.is_administrator?).to be false
    end

    it "has editor permission" do
      expect(editor.is_editor?).to be true
    end

    it "inherits contributor permission" do
      expect(editor.is_contributor?).to be true
    end

    it "inherits viewer permission" do
      expect(editor.is_viewer?).to be true
    end
  end

  context "when contributor" do
    let(:contributor) { create(:contributor) }

    it "does not have administrator permission" do
      expect(contributor.is_administrator?).to be false
    end

    it "does not have editor permission" do
      expect(contributor.is_editor?).to be false
    end

    it "has contributor permission" do
      expect(contributor.is_contributor?).to be true
    end

    it "inherits viewer permission" do
      expect(contributor.is_viewer?).to be true
    end
  end

  context "when viewer" do
    let(:viewer) { create(:user) }

    it "does not have administrator permission" do
      expect(viewer.is_administrator?).to be false
    end

    it "does not have editor permission" do
      expect(viewer.is_editor?).to be false
    end

    it "does not have contributor permission" do
      expect(viewer.is_contributor?).to be false
    end

    it "has viewer permission" do
      expect(viewer.is_viewer?).to be true
    end
  end
end
