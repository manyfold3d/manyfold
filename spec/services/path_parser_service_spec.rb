require "rails_helper"

RSpec.describe PathParserService do
  subject(:service) { described_class.new(SiteSettings.model_path_template, path) }

  let(:path) { "/top/middle/bottom/prefix - name#42" }

  {
    "{tags}" => %r{^/?.*?(?<tags>[[:print:]]*)(?<model_id>#[[:digit:]]+)?$},
    "{creator}" => %r{^/?.*?(?<creator>[[:print:]&&[^/]]*?)(?<model_id>#[[:digit:]]+)?$},
    "{collection}" => %r{^/?.*?(?<collection>[[:print:]&&[^/]]*?)(?<model_id>#[[:digit:]]+)?$},
    "{tags}/{creator}" => %r{^/?.*?(?<tags>[[:print:]]*)/(?<creator>[[:print:]&&[^/]]*?)(?<model_id>#[[:digit:]]+)?$},
    "{tags}/{creator}/{modelName}" => %r{^/?.*?(?<tags>[[:print:]]*)/(?<creator>[[:print:]&&[^/]]*?)/(?<model_name>[[:print:]&&[^/]]*?)(?<model_id>#[[:digit:]]+)?$},
    "@{creator}" => %r{^/?.*?@(?<creator>[[:print:]&&[^/]]*?)(?<model_id>#[[:digit:]]+)?$},
    "{creator}/{collection}/{tags}/{modelName}" => %r{^/?.*?(?<creator>[[:print:]&&[^/]]*?)/(?<collection>[[:print:]&&[^/]]*?)/(?<tags>[[:print:]]*)/(?<model_name>[[:print:]&&[^/]]*?)(?<model_id>#[[:digit:]]+)?$}
  }.each_pair do |tag, regexp|
    it "correctly converts #{tag} into a regexp matcher" do
      allow(SiteSettings).to receive(:model_path_template).and_return(tag)
      expect(service.send(:path_parse_pattern)).to eql regexp
    end
  end

  {
    "{tags}/{modelName}" => {
      tags: ["top", "middle", "bottom"],
      model_name: "prefix - name"
    },
    "{creator}/{modelName}" => {
      creator: "bottom",
      model_name: "prefix - name"
    },
    "{collection}/{modelName}" => {
      collection: "bottom",
      model_name: "prefix - name"
    },
    "{tags}/{creator}/{modelName}" => {
      creator: "bottom",
      tags: ["top", "middle"],
      model_name: "prefix - name"
    },
    "{creator}" => {
      creator: "prefix - name"
    },
    "{tags}/{creator}/{collection} - {modelName}" => {
      tags: ["top", "middle"],
      creator: "bottom",
      collection: "prefix",
      model_name: "name"
    }
  }.each_pair do |tag, values|
    it "correctly matches components of #{tag}" do
      allow(SiteSettings).to receive(:model_path_template).and_return(tag)
      expect(service.call).to eql values
    end
  end
end
