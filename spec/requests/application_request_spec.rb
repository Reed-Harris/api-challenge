require 'rails_helper'

RSpec.describe 'Applications', type: :request do
  describe 'GET /common_ancestor' do
    context 'with invalid id parameters' do
      before do
        # Generate a set of nodes
        root = create(:node)
        child1 = create(:node, parent: root)
        child2 = create(:node, parent: root)

        # Ensure that the parameter, a, is NOT equal to any node id
        @a = nil
        loop do
          @a = rand(1..1000)
          break unless [root.id, child1.id, child2.id].include?(@a)
        end

        # Make request
        get common_ancestor_path(a: @a, b: root.id)
        @json_message = JSON.parse(response.body)['message']
      end

      it 'should return an appropriate error message' do
        expect(response).to have_http_status(:bad_request)
        expect(@json_message).to eq("One or more invalid node ids provided. Please replace the following ids with valid node ids: #{@a}")
      end
    end

    context 'with id parameters present on different trees' do
      before do
        # Generate nodes for two trees
        root1 = create(:node)
        child1 = create(:node, parent: root1)
        root2 = create(:node)
        child2 = create(:node, parent: root2)

        # Make request
        get common_ancestor_path(a: child1.id, b: child2.id)
        @json_message = JSON.parse(response.body)['message']
      end

      it 'should return null values' do
        expect(response).to have_http_status(:ok)
        expect(@json_message).to eq('{root_id: null, lowest_common_ancestor: null, depth: null}')
      end
    end

    context 'with id parameters present on the same tree' do
      before do
        # Generate nodes for a single tree, grouped by depth
        #       root  
        #      /    \
        #    1a      1b
        #   /  \       \
        # 2a    2b*     2c
        #      /  \       \
        #    3a    3b      3c
        #   /     /  \
        # 4a*   4b    4c
        #      /        \
        #    5a          5b*
        @root = create(:node)

        child1a = create(:node, parent: @root)
        child1b = create(:node, parent: @root)

        _child2a = create(:node, parent: child1a)
        @child2b = create(:node, parent: child1a) # lowest common ancestor
        child2c = create(:node, parent: child1b)

        child3a = create(:node, parent: @child2b)
        child3b = create(:node, parent: @child2b)
        _child3c = create(:node, parent: child2c)

        child4a = create(:node, parent: child3a) # node a
        child4b = create(:node, parent: child3b)
        child4c = create(:node, parent: child3b)

        _child5a = create(:node, parent: child4b)
        child5b = create(:node, parent: child4c) # node b

        # Make request
        get common_ancestor_path(a: child4a.id, b: child5b.id)
        @json_message = JSON.parse(response.body)['message']
      end

      it 'should return the id of the lowest common ancestor' do
        expect(response).to have_http_status(:ok)
        expect(@json_message).to eq("{root_id: #{@root.id}, lowest_common_ancestor: #{@child2b.id}, depth: 3}")
      end
    end

    context 'with the same id provided twice' do
      before do
        # Generate nodes for a single tree
        @root = create(:node)
        @child = create(:node, parent: @root)

        # Make request
        get common_ancestor_path(a: @child.id, b: @child.id)
        @json_message = JSON.parse(response.body)['message']
      end

      it 'should return that id as the lowest common ancestor' do
        expect(response).to have_http_status(:ok)
        expect(@json_message).to eq("{root_id: #{@root.id}, lowest_common_ancestor: #{@child.id}, depth: 2}")
      end
    end
  end

  describe 'GET /birds' do
    context 'with invalid id parameters' do
      before do
        # Generate a set of nodes
        root = create(:node)
        child1 = create(:node, parent: root)
        child2 = create(:node, parent: root)

        # Ensure that the parameter, a, is NOT equal to any node id
        @a = nil
        loop do
          @a = rand(1..1000)
          break unless [root.id, child1.id, child2.id].include?(@a)
        end

        # Make request
        get birds_path(node_ids: [@a, root.id, child1.id, child2.id])
        @json_message = JSON.parse(response.body)['message']
      end

      it 'should return an appropriate error message' do
        expect(response).to have_http_status(:bad_request)
        expect(@json_message).to eq("One or more invalid node ids provided. Please replace the following ids with valid node ids: #{@a}")
      end
    end

    context 'with valid id parameters' do
      before do
        # Generate a set of nodes for two trees, grouped by tree then depth
        #       root1                root2*
        #      /     \              /     \
        #    1a       1b*         1c       1d
        #   /  \     /  \        /  \     /  \
        # 2a*   2b 2c    2d*   2e    2f 2g    2h
        root1 = create(:node)

        child1a = create(:node, parent: root1)
        child1b = create(:node, parent: root1) # included in node_ids parameter

        child2a = create(:node, parent: child1a) # included in node_ids parameter
        child2b = create(:node, parent: child1a)
        child2c = create(:node, parent: child1b)
        child2d = create(:node, parent: child1b) # included in node_ids parameter

        root2 = create(:node) # included in node_ids parameter

        child1c = create(:node, parent: root2)
        child1d = create(:node, parent: root2)

        child2e = create(:node, parent: child1c)
        child2f = create(:node, parent: child1c)
        child2g = create(:node, parent: child1d)
        child2h = create(:node, parent: child1d)

        # Generate a set of birds for these trees, grouped by node
        #            ----root1----                           ----root2----
        #           /    (1,2)    \                         /     (8)*     \
        #   (3,4) 1a               1b ()               () 1c                1d
        #        /  \             /  \                   /  \              /  \
        # *(5) 2a    2b ()   () 2c    2d (6,7)*     () 2e    2f ()  *(9) 2g    2h (10)*
        bird1 = create(:bird, node: root1)
        bird2 = create(:bird, node: root1)

        bird3 = create(:bird, node: child1a)
        bird4 = create(:bird, node: child1a)

        bird5 = create(:bird, node: child2a) # expected in response

        bird6 = create(:bird, node: child2d) # expected in response
        bird7 = create(:bird, node: child2d) # expected in response

        bird8 = create(:bird, node: root2) # expected in response

        bird9 = create(:bird, node: child2g) # expected in response

        bird10 = create(:bird, node: child2h) # expected in response

        # Declare expected input and output
        node_ids = [child1b.id, child2a.id, child2d.id, root2.id]
        @bird_ids = [bird5.id, bird6.id, bird7.id, bird8.id, bird9.id, bird10.id]

        # Make request
        get birds_path(node_ids: node_ids)
        @json_message = JSON.parse(response.body)['message']
      end

      it 'should return the appropriate bird ids' do
        expect(response).to have_http_status(:ok)
        expect(@json_message).to eq("The ids for the birds which belong to the provided nodes or any of their descendants are: #{@bird_ids.join(', ')}")
      end
    end
  end

  describe 'POST /seed_data_from_csv' do
    context 'with data already present in the system' do
      before do
        # Generate a node which will prevent the seeding process
        create(:node)

        # Make request
        post seed_data_from_csv_path(node_path: 'spec/fixtures/nodes.csv', bird_path: 'spec/fixtures/birds.csv')
        @json_message = JSON.parse(response.body)['message']
      end

      it 'should return an appropriate error message' do
        expect(response).to have_http_status(:bad_request)
        expect(@json_message).to eq('Data already seeded. To avoid data complications, please execute /delete_all_data before attempting to re-seed data.')
      end
    end

    context 'with no data present in the system' do
      before do
        # Ensure no nodes or birds are present
        Bird.destroy_all
        Node.destroy_all
      end

      context 'and an invalid file path provided' do
        before do
          @invalid_path = 'spec/fixtures/invalid_file.csv'

          #Make request
          post seed_data_from_csv_path(node_path: @invalid_path, bird_path: 'spec/fixtures/birds.csv')
          @json_message = JSON.parse(response.body)['message']
        end

        it 'should return an appropriate error message' do
          expect(response).to have_http_status(:bad_request)
          expect(@json_message).to eq("One or more invalid file paths provided. Please replace the following paths with valid file paths: #{@invalid_path}")
        end
      end

      context 'and a valid file path provided' do
        before do
          # Make request; the node file specified here holds information representing the following tree:
          #      1  
          #    /   \
          #   2     3
          #  / \   / \
          # 4   5 6   7
          # And the bird file specified holds information adding the following birds to the tree:
          #        -------1-------
          #       /     (1,2)     \
          #  (3) 2                 3 (4,5)
          #     / \               / \
          # () 4   5 (6)   (7,8) 6   7 ()
          post seed_data_from_csv_path(node_path: 'spec/fixtures/nodes.csv', bird_path: 'spec/fixtures/birds.csv')
          @json_message = JSON.parse(response.body)['message']
        end

        it 'should create the data specified in the provided files' do
          expect(Node.count).to eq(7)
          expect(Node.find_by(id: 1).parent_id).to be_nil
          expect(Node.find_by(id: 2).parent_id).to eq(1)
          expect(Node.find_by(id: 3).parent_id).to eq(1)
          expect(Node.find_by(id: 4).parent_id).to eq(2)
          expect(Node.find_by(id: 5).parent_id).to eq(2)
          expect(Node.find_by(id: 6).parent_id).to eq(3)
          expect(Node.find_by(id: 7).parent_id).to eq(3)

          expect(Bird.count).to eq(8)
          expect(Bird.find_by(id: 1).node_id).to eq(1)
          expect(Bird.find_by(id: 2).node_id).to eq(1)
          expect(Bird.find_by(id: 3).node_id).to eq(2)
          expect(Bird.find_by(id: 4).node_id).to eq(3)
          expect(Bird.find_by(id: 5).node_id).to eq(3)
          expect(Bird.find_by(id: 6).node_id).to eq(5)
          expect(Bird.find_by(id: 7).node_id).to eq(6)
          expect(Bird.find_by(id: 8).node_id).to eq(6)

          expect(response).to have_http_status(:ok)
          expect(@json_message).to eq('Successfully seeded data from CSV!')
        end
      end
    end
  end

  describe 'DELETE /delete_all_data' do
    before do
      # Generate data to be deleted
      create_list(:node, 5)
      create_list(:bird, 3, node_id: Node.first.id)

      # Make request
      delete delete_all_data_path
      @json_message = JSON.parse(response.body)['message']
    end

    it 'should delete all data from the system' do
      expect(Node.count).to eq(0)
      expect(Bird.count).to eq(0)
      expect(response).to have_http_status(:ok)
      expect(@json_message).to eq('All data has been successfully deleted. You may now use /seed_data_from_csv?node_path=<path/to/nodes>&bird_path=<path/to/birds> to re-seed data.')
    end
  end
end
