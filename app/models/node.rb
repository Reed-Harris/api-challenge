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
end
