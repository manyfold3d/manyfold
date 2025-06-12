require "rails_helper"

describe CollectionPolicy do
  let(:target_class) { Collection }

  it_behaves_like "ApplicationPolicy"
end
