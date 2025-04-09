FactoryBot.define do
  factory :oauth_application, class: "Doorkeeper::Application" do
    name { Faker::Appliance.equipment }
    redirect_uri { "urn:ietf:wg:oauth:2.0:oob" }
    scopes { ["read", "delete"] }
    confidential { true }
    owner { association :moderator }
  end
end
