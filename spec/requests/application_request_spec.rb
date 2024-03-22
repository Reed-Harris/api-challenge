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

  describe 'POST /seed_nodes_from_csv' do
    context 'with nodes already present in the system' do
      before do
        # Generate a node which will prevent the seeding process
        create(:node)

        # Make request
        post seed_nodes_from_csv_path(path: 'spec/fixtures/nodes.csv')
        @json_message = JSON.parse(response.body)['message']
      end

      it 'should return an appropriate error message' do
        expect(response).to have_http_status(:bad_request)
        expect(@json_message).to eq('Node data already seeded. To avoid data complications, please execute /delete_all_nodes before attempting to re-seed node data.')
      end
    end

    context 'with no nodes present in the system' do
      before do
        # Ensure no nodes are present
        Node.destroy_all
      end

      context 'and an invalid file path provided' do
        before do
          #Make request
          post seed_nodes_from_csv_path(path: 'spec/fixtures/invalid_file.csv')
          @json_message = JSON.parse(response.body)['message']
        end

        it 'should return an appropriate error message' do
          expect(response).to have_http_status(:internal_server_error)
          expect(@json_message).to match(/An error occurred while attempting to seed nodes from CSV: /)
        end
      end

      context 'and a valid file path provided' do
        before do
          # Make request; the file specified here holds information representing the following tree:
          #      1  
          #    /   \
          #   2     3
          #  / \   / \
          # 4   5 6   7
          post seed_nodes_from_csv_path(path: 'spec/fixtures/nodes.csv')
          @json_message = JSON.parse(response.body)['message']
        end

        it 'should create the nodes specified in the provided file' do
          expect(Node.count).to eq(7)
          expect(Node.find_by(id: 1).parent_id).to be_nil
          expect(Node.find_by(id: 2).parent_id).to eq(1)
          expect(Node.find_by(id: 3).parent_id).to eq(1)
          expect(Node.find_by(id: 4).parent_id).to eq(2)
          expect(Node.find_by(id: 5).parent_id).to eq(2)
          expect(Node.find_by(id: 6).parent_id).to eq(3)
          expect(Node.find_by(id: 7).parent_id).to eq(3)
          expect(response).to have_http_status(:ok)
          expect(@json_message).to eq('Successfully seeded nodes from CSV!')
        end
      end
    end
  end

  describe 'DELETE /delete_all_nodes' do
    before do
      # Generate nodes to be deleted
      create_list(:node, 5)

      # Make request
      delete delete_all_nodes_path
      @json_message = JSON.parse(response.body)['message']
    end

    it 'should delete all nodes from the system' do
      expect(Node.count).to eq(0)
      expect(response).to have_http_status(:ok)
      expect(@json_message).to eq('All nodes have been successfully deleted. You may now use /seed_nodes_from_csv?path=<path/to/csv> to re-seed node data.')
    end
  end
end
