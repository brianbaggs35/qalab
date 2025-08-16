FactoryBot.define do
  factory :system_setting do
    key { "MyString" }
    value { "MyText" }
    encrypted_value { "MyText" }
  end
end
