require "rails_helper"

RSpec.describe DatabaseDetector do
  it "doesn't leak connections when checking database type" do
    expect { described_class.server }.not_to change { ActiveRecord::Base.connection_pool.stat.dig(:busy) }
  end

  it "doesn't leak connections when checking tables" do
    expect { described_class.table_ready? "users" }.not_to change { ActiveRecord::Base.connection_pool.stat.dig(:busy) }
  end

  it "checks that tables are ready" do
    expect(described_class.table_ready?("users")).to be true
  end

  it "checks that missing tables are not ready" do
    expect(described_class.table_ready?("animals")).to be false
  end
end
