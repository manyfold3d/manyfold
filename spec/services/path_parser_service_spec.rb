require "rails_helper"

RSpec.describe PathParserService do
  let(:path) { "/one/two/three/prefix - name#42" }

  {
    "{tags}" => %r{^/?.*?(?<tags>[[:print:]]*)$},
    "{creator}" => %r{^/?.*?(?<creator>[[:print:]&&[^/]]*?)$},
    "{collection}" => %r{^/?.*?(?<collection>[[:print:]&&[^/]]*?)$},
    "{tags}/{creator}" => %r{^/?.*?(?<tags>[[:print:]]*)/(?<creator>[[:print:]&&[^/]]*?)$},
    "{tags}/{creator}/{modelName}{modelId}" => %r{^/?.*?(?<tags>[[:print:]]*)/(?<creator>[[:print:]&&[^/]]*?)/(?<model_name>[[:print:]&&[^/]]*?)(?<model_id>#[[:digit:]]+)?$},
    "@{creator}{modelId}" => %r{^/?.*?@(?<creator>[[:print:]&&[^/]]*?)(?<model_id>#[[:digit:]]+)?$},
    "{creator}/{collection}/{tags}/{modelName}{modelId}" => %r{^/?.*?(?<creator>[[:print:]&&[^/]]*?)/(?<collection>[[:print:]&&[^/]]*?)/(?<tags>[[:print:]]*)/(?<model_name>[[:print:]&&[^/]]*?)(?<model_id>#[[:digit:]]+)?$}
  }.each_pair do |tag, regexp|
    it "correctly converts #{tag} into a regexp matcher" do
      service = described_class.new(tag, path)
      expect(service.send(:path_parse_pattern)).to eql regexp
    end
  end

  {
    "{tags}/{modelName}{modelId}" => {
      tags: ["one", "two", "three"],
      model_name: "prefix - name"
    },
    "{creator}/{modelName}{modelId}" => {
      creator: "three",
      model_name: "prefix - name"
    },
    "{collection}/{modelName}{modelId}" => {
      collection: "three",
      model_name: "prefix - name"
    },
    "{tags}/{creator}/{modelName}{modelId}" => {
      creator: "three",
      tags: ["one", "two"],
      model_name: "prefix - name"
    },
    "{creator}{modelId}" => {
      creator: "prefix - name"
    },
    "{tags}/{creator}/{collection} - {modelName}{modelId}" => {
      tags: ["one", "two"],
      creator: "three",
      collection: "prefix",
      model_name: "name"
    }
  }.each_pair do |tag, values|
    it "correctly matches components of #{tag}" do
      service = described_class.new(tag, path)
      expect(service.call).to eql values
    end
  end
end
