require "rails_helper"

RSpec.describe SiteSettings do
  context "when detecting ignored files" do
    %w[
      ./test.stl
      /test.stl
      test.stl
      test/test.stl
    ].each do |pathname|
      it "accepts `#{pathname}`" do
        expect(described_class.send(:ignored_file?, pathname)).to be false
      end
    end

    %w[
      .test.stl
      test/.test.stl
      .test/test.stl
      model/@eaDir/test.png/SYNOPHOTO_THUMB_S.png
      model/__MACOSX
    ].each do |pathname|
      it "ignores `#{pathname}`" do
        expect(described_class.send(:ignored_file?, pathname)).to be true
      end
    end
  end
end
