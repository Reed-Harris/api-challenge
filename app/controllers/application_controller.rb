require 'csv'

class ApplicationController < ActionController::API
  def common_ancestor
    node_a = Node.find_by(id: params[:a])
    node_b = Node.find_by(id: params[:b])

    # Handle bad requests
    invalid_parameter_values = []
    invalid_parameter_values << params[:a] if node_a.nil?
    invalid_parameter_values << params[:b] if node_b.nil?

    if invalid_parameter_values.any?
      render status: :bad_request,
             json: {
               message: 'One or more invalid parameter values provided. Please replace the following ' \
                        "parameter values with valid node ids: #{invalid_parameter_values.join(', ')}"
             }
      return
    end

    sql = <<-SQL
      WITH RECURSIVE path_a AS (
        SELECT id, parent_id, 1 AS level, ARRAY[id] AS visited_nodes
        FROM nodes
        WHERE id = #{node_a.id}
        UNION ALL
        SELECT n.id, n.parent_id, path_a.level + 1 AS level, visited_nodes || n.id
        FROM nodes n
        INNER JOIN path_a ON path_a.parent_id = n.id
        WHERE NOT (n.id = ANY(path_a.visited_nodes))
      ),
      path_b AS (
        SELECT id, parent_id, 1 AS level, ARRAY[id] AS visited_nodes
        FROM nodes
        WHERE id = #{node_b.id}
        UNION ALL
        SELECT n.id, n.parent_id, path_b.level + 1 AS level, visited_nodes || n.id
        FROM nodes n
        INNER JOIN path_b ON path_b.parent_id = n.id
        WHERE NOT (n.id = ANY(path_b.visited_nodes))
      ),
      root AS (
        SELECT path_a.id
        FROM path_a
        JOIN path_b ON path_b.id = path_a.id
        WHERE path_a.parent_id IS NULL
        LIMIT 1
      ),
      lowest_common_ancestor AS (
        SELECT path_a.id
        FROM path_a
        JOIN path_b ON path_b.id = path_a.id
        ORDER BY path_a.level ASC
        LIMIT 1
      ),
      depth AS (
        SELECT MAX(path_a.level) - MIN(path_a.level) + 1 AS depth
        FROM path_a
        JOIN path_b ON path_b.id = path_a.id
      )
      SELECT (SELECT id FROM root) AS root_id,
        (SELECT id FROM lowest_common_ancestor) AS lowest_common_ancestor,
        (SELECT depth FROM depth) AS depth;
    SQL
    result = ActiveRecord::Base.connection.execute(sql).first.symbolize_keys

    render status: :ok,
           json: {
             root_id: result[:root_id],
             lowest_common_ancestor: result[:lowest_common_ancestor],
             depth: result[:depth]
           }
  rescue StandardError => e
    render status: :internal_server_error,
           json: { message: "An error occurred while attempting to determine the common ancestor: #{e.message}" }
  end

  def birds
    nodes = Node.where(id: params[:node_ids])

    # Handle bad requests
    invalid_parameter_values = params[:node_ids] - nodes.map(&:id).map(&:to_s)
    if invalid_parameter_values.any?
      render status: :bad_request,
             json: {
               message: 'One or more invalid parameter values provided. Please replace the following ' \
                        "parameter values with valid node ids: #{invalid_parameter_values.join(', ')}"
             }
      return
    end

    sql = <<-SQL
      WITH RECURSIVE nodes_subselect AS (
        SELECT id
        FROM nodes
        WHERE id IN (#{nodes.map(&:id).join(',')})
        UNION
        SELECT n.id
        FROM nodes n
        INNER JOIN nodes_subselect ON nodes_subselect.id = n.parent_id
      ),
      birds_subselect AS (
        SELECT birds.id
        FROM birds
        INNER JOIN nodes_subselect ON nodes_subselect.id = node_id
      )
      SELECT id
      FROM birds_subselect;
    SQL
    bird_ids = ActiveRecord::Base.connection.execute(sql).map { |row| row['id'].to_i }.sort

    render status: :ok,
           json: { bird_ids: }
  rescue StandardError => e
    render status: :internal_server_error,
           json: { message: "An error occurred while attempting to determine the list of birds: #{e.message}" }
  end

  def generate_csv_for_seeding
    node_filename = params[:node_filename].split('/').last.chomp('.csv')
    bird_filename = params[:bird_filename].split('/').last.chomp('.csv')
    number_of_trees = params[:number_of_trees].to_i
    number_of_nodes_per_tree = params[:number_of_nodes_per_tree].to_i
    number_of_birds_per_tree = params[:number_of_birds_per_tree].to_i

    # Handle bad requests
    invalid_parameter_values = []
    invalid_parameter_values << params[:number_of_trees] unless number_of_trees.positive?
    invalid_parameter_values << params[:number_of_nodes_per_tree] unless number_of_nodes_per_tree.positive?
    invalid_parameter_values << params[:number_of_birds_per_tree] unless number_of_birds_per_tree.positive?

    if invalid_parameter_values.any?
      render status: :bad_request,
             json: {
               message: 'One or more invalid parameter values provided. Please replace the following ' \
                        "parameter values with positive integers: #{invalid_parameter_values.join(', ')}"
             }
      return
    end

    # Prepare data for writing to CSV
    node_data = []
    bird_data = []
    number_of_trees.times do |number_of_trees_added|
      # Determine next available id for current tree's root node
      root_id = number_of_trees_added * number_of_nodes_per_tree + 1

      # Add current tree's root node to data object
      node_data << [root_id, nil]

      # Build non-root nodes for current tree
      (number_of_nodes_per_tree - 1).times do |number_of_nodes_added_for_this_tree|
        # Determine next available id for current node
        node_id = root_id + number_of_nodes_added_for_this_tree + 1

        # Randomly select a node from current tree to be the parent of the current node
        parent_id = rand(root_id...node_id)

        # Add current node to data object
        node_data << [node_id, parent_id]
      end

      # Build birds for current tree
      number_of_birds_per_tree.times do |number_of_birds_added_for_this_tree|
        # Determine next available id for current bird
        bird_id = number_of_trees_added * number_of_birds_per_tree + number_of_birds_added_for_this_tree + 1

        # Randomly select a node from current tree to be the current bird's node
        node_id = rand(root_id...(root_id + number_of_nodes_per_tree))

        # Add current bird to data object
        bird_data << [bird_id, node_id]
      end
    end

    # Write data to CSV
    CSV.open(File.join(Rails.root, "public/#{node_filename}.csv"), 'w') do |csv|
      csv << %w[id parent_id]

      node_data.each do |row|
        csv << row
      end
    end
    CSV.open(File.join(Rails.root, "public/#{bird_filename}.csv"), 'w') do |csv|
      csv << %w[id node_id]

      bird_data.each do |row|
        csv << row
      end
    end

    render status: :ok,
           json: {
             message: 'Successfully generated CSV files for seeding. You may now use ' \
                      '/seed_data_from_csv?node_path=public/<node_filename>&bird_path=public/<bird_filename> ' \
                      'to seed data. '
           }
  rescue StandardError => e
    render status: :internal_server_error,
           json: { message: "An error occurred while attempting to generate CSVs for seeding: #{e.message}" }
  end

  def seed_data_from_csv
    # If any nodes or birds already exist, prevent further seeding
    if Node.count.positive? || Bird.count.positive?
      render status: :bad_request,
             json: {
               message: 'Data already seeded. To avoid data complications, please execute ' \
                        '/delete_all_data before attempting to re-seed data.'
             }
      return
    end

    # Handle bad requests by verifying both files exist before beginning data creation
    invalid_parameter_values = []
    invalid_parameter_values << params[:node_path] unless File.exist?(params[:node_path])
    invalid_parameter_values << params[:bird_path] unless File.exist?(params[:bird_path])

    if invalid_parameter_values.any?
      render status: :bad_request,
             json: {
               message: 'One or more invalid parameter values provided. Please replace the following parameter ' \
                        "values with valid file paths: #{invalid_parameter_values.join(', ')}"
             }
      return
    end

    # Parse CSVs and build data objects
    node_data = []
    CSV.foreach(params[:node_path], headers: true) do |row|
      node_data << { id: row['id'], parent_id: row['parent_id'] }
    end
    bird_data = []
    CSV.foreach(params[:bird_path], headers: true) do |row|
      bird_data << { id: row['id'], node_id: row['node_id'] }
    end

    # Build SQL queries
    current_timestamp = Time.now.utc.strftime("'%Y-%m-%d %H:%M:%S'")
    node_values = node_data.map do |row|
      "(#{row[:id]}, #{row[:parent_id] || 'NULL'}, #{current_timestamp}, #{current_timestamp})"
    end.join(', ')
    bird_values = bird_data.map do |row|
      "(#{row[:id]}, #{row[:node_id]}, #{current_timestamp}, #{current_timestamp})"
    end.join(', ')
    node_sql = "INSERT INTO nodes (id, parent_id, created_at, updated_at) VALUES #{node_values};"
    bird_sql = "INSERT INTO birds (id, node_id, created_at, updated_at) VALUES #{bird_values};"

    # Execute sql queries in a transaction to ensure atomicity
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute(node_sql)
      ActiveRecord::Base.connection.execute(bird_sql)
    end

    render status: :ok,
           json: { message: 'Successfully seeded data from CSV!' }
  rescue StandardError => e
    render status: :internal_server_error,
           json: { message: "An error occurred while attempting to seed data from CSV: #{e.message}" }
  end

  def delete_all_data
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE birds, nodes;')

    render status: :ok,
           json: {
             message: 'All data has been successfully deleted. You may now use ' \
                      '/seed_data_from_csv?node_path=<path/to/nodes>&bird_path=<path/to/birds> to re-seed data.'
           }
  rescue StandardError => e
    render status: :internal_server_error,
           json: { message: "An error occurred while attempting to delete data: #{e.message}" }
  end
end
