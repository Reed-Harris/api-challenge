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

  describe 'Instance Methods' do
    describe '#find_path_from_root' do
      before do
        # Generate a set of nodes for a single tree, grouped by depth
        #       -root-
        #      /      \
        #    1a*       1b
        #   /  \      /  \
        # 2a    2b  2c*   2d
        @root = create(:node)
        
        @child1a = create(:node, parent: @root) # node targeted for get_bird_ids()
        @child1b = create(:node, parent: @root)

        @child2a = create(:node, parent: @child1a)
        @child2b = create(:node, parent: @child1a)
        @child2c = create(:node, parent: @child1b) # node targeted for find_path_from_root(), descendant_of_any?(), and get_ancestor_ids()
        @child2d = create(:node, parent: @child1b)

        @expected_result = [@root.id, @child1b.id, @child2c.id]
        @actual_result = @child2c.find_path_from_root
      end

      it 'should return the correct path, beginning at the root and ending at the invoking node' do
        expect(@actual_result).to eq(@expected_result)
      end
    end
  end
end
