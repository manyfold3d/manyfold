require "rails_helper"

RSpec.describe PublicUrl do
  it "provides default hostname as a string" do
    expect(described_class.hostname).to eq "localhost"
  end

  it "provides default port as a string" do
    expect(described_class.port).to eq "3214"
  end

  context "when checking for only nonstandard ports" do
    it "returns nil for port 80" do
      ClimateControl.modify PUBLIC_PORT: "80" do
        expect(described_class.nonstandard_port).to be_nil
      end
    end

    it "returns nil for port 443" do
      ClimateControl.modify PUBLIC_PORT: "443" do
        expect(described_class.nonstandard_port).to be_nil
      end
    end

    it "returns specified port for anything else" do
      expect(described_class.nonstandard_port).to eq "3214"
    end
  end

  context "with only PUBLIC_HOSTNAME set" do
    around do |example|
      ClimateControl.modify PUBLIC_HOSTNAME: "manyfold.example.com" do
        example.run
      end
    end

    it "provides specified hostname" do
      expect(described_class.hostname).to eq "manyfold.example.com"
    end

    it "assumes the standard port 80" do
      expect(described_class.port).to eq "80"
    end

    it "assumes standard port 443 if HTTPS_ONLY is set" do
      ClimateControl.modify HTTPS_ONLY: "enabled" do
        expect(described_class.port).to eq "443"
      end
    end
  end

  context "with only PUBLIC_PORT set" do
    around do |example|
      ClimateControl.modify PUBLIC_PORT: "80" do
        example.run
      end
    end

    it "provides specified port" do
      expect(described_class.port).to eq "80"
    end
  end

  context "with PUBLIC_HOSTNAME and PUBLIC_PORT set" do
    around do |example|
      ClimateControl.modify PUBLIC_PORT: "1234", PUBLIC_HOSTNAME: "example.com" do
        example.run
      end
    end

    it "provides specified port" do
      expect(described_class.port).to eq "1234"
    end
  end

  context "with RAILS_PORT set" do
    around do |example|
      ClimateControl.modify RAILS_PORT: "5000" do
        example.run
      end
    end

    it "provides specified port" do
      expect(described_class.port).to eq "5000"
    end
  end

  context "with RAILS_PORT and PUBLIC_PORT set" do
    around do |example|
      ClimateControl.modify RAILS_PORT: "5000", PUBLIC_PORT: "80" do
        example.run
      end
    end

    it "provides PUBLIC_PORT" do
      expect(described_class.port).to eq "80"
    end
  end
end
