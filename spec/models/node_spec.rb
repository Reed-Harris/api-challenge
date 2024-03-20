require 'rails_helper'

RSpec.describe Node, type: :model do
  it 'is valid without any attributes' do
    expect(create(:node)).to be_valid
  end

  it 'is valid with parent speficied' do
    parent = create(:node)
    expect(create(:node, parent: parent)).to be_valid
  end
end
