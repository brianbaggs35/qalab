FactoryBot.define do
  factory :organization_user do
    organization { nil }
    user { nil }
    role { "MyString" }
  end
end
