FactoryBot.define do
  factory :provider, class: "FaspClient::Provider" do
    name { "Example FASP" }
    base_url { "https://fasp.example.com" }
    server_id { "b2ks6vm8p23w" }
    public_key { "pDnfhQyTX06RNDhyDI7yMlSohxcpOzHF/xUbJ5DTgAA=" }

    trait :registered do
      # This setup is from a manually-registered local fediscoverer instance;
      # if you need to change the cassettes to run against a real instance,
      # you'll need different values here.
      name { "fediscoverer" }
      base_url { "http://localhost:3000/fasp" }
      server_id { "7" }
      public_key { "2m4yAcnNSi5qX5JgyX8MnuKjf/7W87qdqT6t6y/IJc0=" }
      uuid { "ae95fe4f-c52e-408e-8212-c827126e5f7e" }
      ed25519_signing_key { Ed25519::SigningKey.new(Base64.strict_decode64("hqRBxE0Eaby1lVevr3SBNglxLXmAOLSJQQFE5S4Lf7Q=")) }
    end
  end
end
