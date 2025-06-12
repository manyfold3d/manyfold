require "rails_helper"

describe CreatorPolicy do
  let(:target_class) { Creator }

  it_behaves_like "ApplicationPolicy"
end
