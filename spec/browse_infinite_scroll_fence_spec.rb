# frozen_string_literal: true

require "rails_helper"

# INIT-003/SPEC-003 fence: any action that mounts models infinite-scroll chrome
# (via models/list → models-scroll-sentinel) must respond to turbo_stream.
# Show pages historically omitted format.turbo_stream → live HTTP 406.
RSpec.describe "browse infinite-scroll stream fence" do
  ACTIONS_THAT_MOUNT_MODELS_SCROLL = {
    "app/controllers/models_controller.rb" => "index",
    "app/controllers/creators_controller.rb" => "show",
    "app/controllers/collections_controller.rb" => "show"
  }.freeze

  it "keeps turbo_stream responders on every models-scroll mount action" do
    ACTIONS_THAT_MOUNT_MODELS_SCROLL.each do |path, action|
      source = Rails.root.join(path).read
      expect(source).to match(/def #{action}\b/m), "#{path} missing ##{action}"
      # Within the action method, require format.turbo_stream rendering models/page
      # (creators/collections show) or models/page / models controller index.
      action_body = source[/\bdef #{action}\b.*?(?=\n  def |\n  private|\z)/m]
      expect(action_body).to include("format.turbo_stream"),
        "#{path}##{action} must declare format.turbo_stream (INIT-003/SPEC-003)"
    end
  end

  it "documents models/list as the shared chrome that requires show streams" do
    list = Rails.root.join("app/views/models/_list.html.erb").read
    expect(list).to include("browse_infinite_grid")
    # Sentinel DOM id is "#{sentinel_prefix}-scroll-sentinel" in the shared layout.
    expect(list).to include('sentinel_prefix: "models"')
  end
end
