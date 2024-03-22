require 'csv'

class ApplicationController < ActionController::API
    def common_ancestor
        node_a = Node.find_by(id: params[:a])
        node_b = Node.find_by(id: params[:b])

        # Handle bad requests
        invalid_node_ids = []
        invalid_node_ids << params[:a] if node_a.nil?
        invalid_node_ids << params[:b] if node_b.nil?

        if invalid_node_ids.any?
            render status: :bad_request,
                   json: { message: "One or more invalid node ids provided. Please replace the following ids with valid node ids: #{invalid_node_ids.join(', ')}" }
            return
        end

        # Build paths from the root to each of the specified nodes
        path_a = node_a.find_path_from_root
        path_b = node_b.find_path_from_root

        # Use these paths to determine the lowest common ancestor, as well as its depth
        lowest_common_ancestor = nil
        depth = nil
        path_a.zip(path_b).each_with_index do |(a, b), index|
            if a == b
                lowest_common_ancestor = a
                depth = index + 1
            else
                break
            end
        end

        # If there is a lowest common ancestor, the root is the first step in either path built above
        #   Otherwise, the two nodes are on separate trees, and so the root is nil
        root_id = lowest_common_ancestor ? path_a.first : nil

        render status: :ok,
               json: { message: "{root_id: #{root_id || 'null'}, lowest_common_ancestor: #{lowest_common_ancestor || 'null'}, depth: #{depth || 'null'}}" }
    rescue StandardError => error
        render status: :internal_server_error,
               json: { message: "An error occurred while attempting to determine the common ancestor: #{error.message}" }
    end

    def seed_nodes_from_csv
        # If any nodes already exist, prevent further seeding
        if Node.count > 0
            render status: :bad_request,
                   json: { message: 'Node data already seeded. To avoid data complications, please execute /delete_all_nodes before attempting to re-seed node data.' }
            return
        end

        # Create nodes in an atomic manner
        ActiveRecord::Base.transaction do
            CSV.foreach(params[:path], headers: true) do |row|
                node = Node.create!(id: row['id'], parent_id: row['parent_id'])
            end
        end

        render status: :ok,
               json: { message: 'Successfully seeded nodes from CSV!' }
    rescue StandardError => error
        render status: :internal_server_error,
               json: { message: "An error occurred while attempting to seed nodes from CSV: #{error.message}" }
    end

    def delete_all_nodes
        Node.destroy_all
        render status: :ok,
               json: { message: 'All nodes have been successfully deleted. You may now use /seed_nodes_from_csv?path=<path/to/csv> to re-seed node data.'}
    rescue StandardError => error
        render status: :internal_server_error,
               json: { message: "An error occurred while attempting to delete nodes: #{error.message}" }
    end
end