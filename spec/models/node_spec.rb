require 'rails_helper'

RSpec.describe Node, type: :model do
  describe 'Behavior' do
    it { should belong_to(:parent).class_name('Node').optional }
    it { should have_many(:children).class_name('Node').with_foreign_key('parent_id') }
    it { should have_many(:birds) }
  end

  describe 'Validations' do
    it 'is valid without any attributes' do
      expect(build(:node)).to be_valid
    end
  
    it 'is valid with parent specified' do
      parent = create(:node)
      expect(build(:node, parent: parent)).to be_valid
    end
  end
end
