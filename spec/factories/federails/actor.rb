FactoryBot.define do
  factory :actor, class: "Federails::Actor" do
    name { Faker::Name.name }
    entity { nil }
    federated_url { "https://example.com/actors/#{rand(1...10_000)}" }
    username { Faker::Internet.username separators: ["-", "_"] }
    server { "example.com" }
    inbox_url { "#{federated_url}/inbox" }
    outbox_url { "#{federated_url}/outbox" }
    followers_url { "#{federated_url}/followers" }
    followings_url { "#{federated_url}/followings" }
    profile_url { "https://example.com/users/#{federated_url.split("/").last}" }
    extensions {
      {
        summary: Faker::Lorem.sentence,
        content: Faker::Lorem.paragraph,
        attachment: [
          {
            "type" => "Link",
            "href" => "https://example.org"
          },
          {
            "type" => "Ignored",
            "href" => "https://example.org"
          }
        ]
      }
    }

    factory :model_actor do
      extensions {
        {
          tag: [
            {
              type: "Hashtag",
              name: "Hash Tag",
              href: "http://localhost:3214/models?tag=Hash%20Tag"
            },
            {
              type: "Hashtag",
              name: "#Wizard",
              href: "http://localhost:3214/models?tag=Wizard"
            }
          ],
          summary: Faker::Lorem.sentence,
          content: Faker::Lorem.paragraph,
          "f3di:concreteType": "3DModel",
          "spdx:license": {
            "spdx:licenseId": "MIT"
          },
          attachment: [
            {
              "type" => "Link",
              "href" => "https://example.org"
            },
            {
              "type" => "Ignored",
              "href" => "https://example.org"
            }
          ]
        }
      }
    end
  end
end
