require "rails_helper"

RSpec.describe Library do
  around do |ex|
    MockDirectory.create([]) do |path|
      @library_path = path
      ex.run
    end
  end

  it "is not valid without a path" do
    expect(build(:library, path: nil)).not_to be_valid
  end

  it "is valid if a path is specified" do
    expect(build(:library, path: @library_path)).to be_valid # rubocop:todo RSpec/InstanceVariable
  end

  it "is invalid if a bad path is specified" do # rubocop:todo RSpec/MultipleExpectations
    l = build(:library, path: "/nope")
    expect(l).not_to be_valid
    expect(l.errors[:path].first).to eq "could not be found on disk"
  end

  it "has many models" do
    expect(build(:library).models).to eq []
  end

  it "must have a unique path" do
    create(:library, path: @library_path) # rubocop:todo RSpec/InstanceVariable
    expect(build(:library, path: @library_path)).not_to be_valid # rubocop:todo RSpec/InstanceVariable
  end

  context "when setting a path" do
    [
      "/bin",
      "/boot",
      "/dev",
      "/etc",
      "/lib",
      "/lost",
      "/proc",
      "/root",
      "/run",
      "/sbin",
      "/selinux",
      "/srv",
      "/usr"
    ].each do |prefix|
      it "disallows paths under #{prefix}" do
        path = File.join(prefix, "library")
        allow(File).to receive(:exist?).with(path).and_return(true)
        library = build(:library, path: path)
        library.valid?
        expect(library.errors[:path]).to include "cannot be a privileged system path"
      end
    end

    it "allows paths that *begin* with a filtered path" do
      library = build(:library, path: "/libraries")
      library.valid?
      expect(library.errors[:path]).not_to include "cannot be a privileged system path"
    end

    it "disallows root folder" do
      library = build(:library, path: "/")
      library.valid?
      expect(library.errors[:path]).to include "cannot be a privileged system path"
    end

    it "disallows read-only folders" do
      path = "/readonly/library"
      allow(FileTest).to receive(:exist?).with(path).and_return(true)
      library = build(:library, path: path)
      library.valid?
      expect(library.errors[:path]).to include "must be writable"
    end

    it "normalizes paths" do
      path = Rails.root + "tmp/../app"
      library = build(:library, path: path)
      expect(library.path).to eq (Rails.root + "app").to_s
    end
  end
end
