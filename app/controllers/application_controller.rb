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

    def birds
        nodes = Node.where(id: params[:node_ids])

        # Handle bad requests
        invalid_node_ids = params[:node_ids].map(&:to_i) - nodes.map(&:id)
        if invalid_node_ids.any?
            render status: :bad_request,
                   json: { message: "One or more invalid node ids provided. Please replace the following ids with valid node ids: #{invalid_node_ids.join(', ')}" }
            return
        end

        # Remove any redundant descendant nodes, so that we don't process the same tree portions multiple times
        nodes = nodes.reject { |node| node.descendant_of_any?(nodes.map(&:id)) }

        # Assess each remaining node, as well as all descendants, to build a list of birds
        bird_ids = []
        nodes.each do |node|
            bird_ids.concat(node.get_bird_ids)
        end

        render status: :ok,
               json: { message: "The ids for the birds which belong to the provided nodes or any of their descendants are: #{bird_ids.sort.join(', ')}" }
    rescue StandardError => error
        render status: :internal_server_error,
               json: { message: "An error occurred while attempting to determine the common ancestor: #{error.message}" }
    end

    def seed_data_from_csv
        # If any nodes or birds already exist, prevent further seeding
        if Node.count > 0 || Bird.count > 0
            render status: :bad_request,
                   json: { message: 'Data already seeded. To avoid data complications, please execute /delete_all_data before attempting to re-seed data.' }
            return
        end

        # Handle bad requests by verifying both files exist before beginning data creation
        invalid_file_paths = []
        invalid_file_paths << params[:node_path] unless File.exist?(params[:node_path])
        invalid_file_paths << params[:bird_path] unless File.exist?(params[:bird_path])

        if invalid_file_paths.any?
            render status: :bad_request,
                   json: { message: "One or more invalid file paths provided. Please replace the following paths with valid file paths: #{invalid_file_paths.join(', ')}" }
            return
        end

        # Create nodes and birds in an atomic manner
        ActiveRecord::Base.transaction do
            CSV.foreach(params[:node_path], headers: true) do |row|
                Node.create!(id: row['id'], parent_id: row['parent_id'])
            end
            CSV.foreach(params[:bird_path], headers: true) do |row|
                Bird.create!(id: row['id'], node_id: row['node_id'])
            end
        end

        render status: :ok,
               json: { message: 'Successfully seeded data from CSV!' }
    rescue StandardError => error
        render status: :internal_server_error,
               json: { message: "An error occurred while attempting to seed data from CSV: #{error.message}" }
    end

    def delete_all_data
        ActiveRecord::Base.transaction do
            Bird.destroy_all
            Node.destroy_all
        end
        render status: :ok,
               json: { message: 'All data has been successfully deleted. You may now use /seed_data_from_csv?node_path=<path/to/nodes>&bird_path=<path/to/birds> to re-seed data.'}
    rescue StandardError => error
        render status: :internal_server_error,
               json: { message: "An error occurred while attempting to delete data: #{error.message}" }
    end
end
