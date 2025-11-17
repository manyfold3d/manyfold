require "rails_helper"

RSpec.describe ModelFilesHelper do
  describe "#slicer_url" do
    let(:file) { create(:model_file, filename: "model.stl") }
    let(:slic3r_family_regex) { "://open\\?file=http%3A%2F%2Ftest.host%2Fmodels%2F#{file.model.to_param}%2Fmodel_files%2Fsigned%2Fey[0-9a-zA-Z-]+%2F#{file.filename}" }

    it "generates orcaslicer links" do
      url = helper.slicer_url(:orca, file)
      expect(url).to match(/orcaslicer#{slic3r_family_regex}/)
    end

    it "generates bambustudio links" do
      url = helper.slicer_url(:bambu, file)
      expect(url).to match(/bambustudioopen#{slic3r_family_regex}/)
    end

    it "generates prusaslicer links" do
      url = helper.slicer_url(:prusa, file)
      expect(url).to match(/prusaslicer#{slic3r_family_regex}/)
    end

    it "generates superslicer links" do
      # Superslicer uses the prusaslicer URL handler
      url = helper.slicer_url(:superslicer, file)
      expect(url).to match(/prusaslicer#{slic3r_family_regex}/)
    end

    it "generates cura links" do
      url = helper.slicer_url(:cura, file)
      expect(url).to match(/cura#{slic3r_family_regex}/)
    end

    it "generates elegoo links" do
      url = helper.slicer_url(:elegoo, file)
      expect(url).to match(/elegooslicer#{slic3r_family_regex}/)
    end

    it "generates lychee links" do
      url = helper.slicer_url(:lychee, file)
      expect(url).to match(/lycheeslicer:\/\/open\/http%3A%2F%2Ftest.host%2Fmodels%2F#{file.model.to_param}%2Fmodel_files%2Fsigned%2Fey[0-9a-zA-Z-]+%2F#{file.filename}/)
    end
  end
end
