class Node < ApplicationRecord
    belongs_to :parent, class_name: 'Node', optional: true
    has_many :children, class_name: 'Node', foreign_key: 'parent_id'
    has_many :birds

    # No matter what, we add the current node to the path being built
    #   If the current node does NOT have a parent, it is the root, so the path is reversed (now the root will be at the beginning) and then returned
    #   Otherwise, we want to use recursion to move further up the tree toward the root
    def find_path_from_root(path = [])
        path << id
        return path.reverse unless parent

        parent.find_path_from_root(path)
    end

    # Build a list of the node's ancestors, then determine if any ancestor is present in the list of nodes
    def descendant_of_any?(node_ids)
        get_ancestor_ids.each do |ancestor_id|
            return true if node_ids.include?(ancestor_id)
        end

        false
    end

    # If the current node has no parent, the root has been reached, and no more ancestor ids need to be added to the list
    #   Otherwise, add the current node's parent_id to the list, and use recursion to move further up the tree
    def get_ancestor_ids(ancestor_ids = [])
        return ancestor_ids unless parent
        ancestor_ids << parent.id
        parent.get_ancestor_ids(ancestor_ids)
    end

    # Start with birds for the current node.
    #   For each child of the current node, use recursion to build a list of birds for that child, concatenating the results with the current node's list
    def get_bird_ids()
        bird_ids = birds.map(&:id)
        children.each do |child|
            bird_ids.concat(child.get_bird_ids)
        end
        bird_ids
    end
end
