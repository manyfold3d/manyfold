FakeNote = Struct.new(
  :id,
  :type,
  :attributedTo,
  :content,
  :inReplyTo,
  :url,
  :sensitive,
  :"f3di:compatibilityNote",
  keyword_init: true
)

FactoryBot.define do
  factory :note, class: "FakeNote" do
    id { "https://example.org/users/@account/posts/#{SecureRandom.uuid}" }
    type { "Note" }
    attributedTo { "https://3dp.chat/@manyfold" }
    content { Faker::Lorem.sentence }

    # Extra fields of interest
    # - inReplyTo
    # - url
    # - sensitive
    # - f3di:compatibilityNote
  end
end
