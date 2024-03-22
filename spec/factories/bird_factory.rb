FactoryBot.define do
  factory :bird do
    association :node, factory: :node
  end
end
