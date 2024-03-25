require 'rails_helper'

RSpec.describe Bird, type: :model do
  describe 'Behavior' do
    it { should belong_to(:node) }
  end

  describe 'Validations' do
    it 'is invalid without a node attribute' do
      expect(build(:bird, node: nil)).not_to be_valid
    end

    it 'is valid with node specified' do
      node = create(:node)
      expect(build(:bird, node:)).to be_valid
    end
  end
end
