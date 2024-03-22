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
    end

    describe '#find_path_from_root' do
      before do
        @expected_result = [@root.id, @child1b.id, @child2c.id]
        @actual_result = @child2c.find_path_from_root
      end

      it 'should return the correct path, beginning at the root and ending at the invoking node' do
        expect(@actual_result).to eq(@expected_result)
      end
    end

    describe '#descendant_of_any?' do
      context 'with only non-ancestor nodes provided' do
        before do
          @actual_result = @child2c.descendant_of_any?([@child1a.id, @child2a.id, @child2b.id, @child2d.id])
        end

        it 'should return false' do
          expect(@actual_result).to be(false)
        end
      end

      context 'with the invoking node provided' do
        before do
          @actual_result = @child2c.descendant_of_any?([@child2c.id, @child1a.id])
        end

        it 'should not view the invoking node as its own ancestor' do
          expect(@actual_result).to be(false)
        end
      end

      context 'with an ancestor node provided' do
        before do
          @actual_result = @child2c.descendant_of_any?([@child1b.id, @child1a.id])
        end

        it 'should return true' do
          expect(@actual_result).to be(true)
        end
      end
    end

    describe '#get_ancestor_ids' do
      before do
        @expected_result = [@child1b.id, @root.id]
        @actual_result = @child2c.get_ancestor_ids
      end

      it 'should return the correct list of ancestor ids' do
        expect(@actual_result).to match_array(@expected_result)
      end
    end

    describe '#get_bird_ids' do
      before do
        # Generate a set of birds for the tree, grouped by node
        #            ----root-----
        #           /    (1,2)    \
        #  *(3,4) 1a               1b ()
        #        /  \             /  \
        # *(5) 2a    2b ()   () 2c    2d (6,7)
        bird1 = create(:bird, node: @root)
        bird2 = create(:bird, node: @root)

        bird3 = create(:bird, node: @child1a)
        bird4 = create(:bird, node: @child1a)

        bird5 = create(:bird, node: @child2a)

        bird6 = create(:bird, node: @child2d)
        bird7 = create(:bird, node: @child2d)

        @expected_result = [bird3.id, bird4.id, bird5.id]
        @actual_result = @child1a.get_bird_ids
      end

      it 'should return the correct list of bird ids' do
        expect(@actual_result).to match_array(@expected_result)
      end
    end
  end
end
