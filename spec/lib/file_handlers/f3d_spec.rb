require "rails_helper"

RSpec.describe FileHandlers::F3d do
  it "can execute f3d" do
    expect(`f3d --version`).to include "F3D"
  end
end
