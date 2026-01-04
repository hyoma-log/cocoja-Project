FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    username { Faker::Internet.unique.username(specifier: 1..20) }
    uid { Faker::Alphanumeric.unique.alphanumeric(number: 10) }
    bio { Faker::Lorem.paragraph_by_chars(number: 160) }
    terms_agreement { '1' }
    privacy_agreement { '1' }

    after(:build) do |user|
      # Only sanitize if username was auto-generated (contains special chars from Faker)
      if user.username.match?(/[._\-]/)
        user.username = user.username.gsub(/[^a-zA-Z0-9]/, '')
      end
      user.uid = user.uid.gsub(/[^a-zA-Z0-9]/, '')
    end
  end
end
