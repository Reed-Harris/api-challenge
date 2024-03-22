require 'rails_helper'

RSpec.describe Bird, type: :model do
  it 'is invalid without a node attribute' do
    expect(build(:bird, node: nil)).not_to be_valid
  end

  it 'is valid with node speficied' do
    node = create(:node)
    expect(build(:bird, node: node)).to be_valid
  end
end
