# README

## API OVERVIEW

This project is a simple API which deals with adjacency trees made up of nodes, each of which has its own id, as well as the id of its parent, which is optional.
Any given node may also have any number of birds associated with it. A node can have 0 birds, but a bird *must* have an associated node.
After first cloning this repository, the user will need to utilize the `/seed_data_from_csv` endpoint in order to populate the database with both nodes and birds.
For convenience, there is also the `/generate_csv_for_seeding` endpoint which will create a CSV which can then be used as input for the `/seed_data_from_csv` endpoint,
as well as the `/delete_all_data` endpoint which will fully empty the nodes and birds tables, so that the `/seed_data_from_csv` endpoint can be used once again.

## SETUP INSTRUCTIONS

### Dependencies

* ruby 3.3.0

* Rails 7.1.3.2

* PostgreSQL

### Steps for first-time setup

* clone the repository (`git clone https://github.com/Reed-Harris/api-challenge.git`) and navigate into the project directory

* run `bundle install`

* update (or create if it doesn't exist yet) the root-level file `.env` to contain the following keys:

  * `API_CHALLENGE_DATABASE_USERNAME=<your database username>`

  * `API_CHALLENGE_DATABASE_PASSWORD=<your database password>`

* run `rake db:create`

* run `rake db:migrate`

* run `rails s` to start the server, and access the endpoints using your method of choice. I mostly used the Postman application.

## ENDPOINT OVERVIEW

This API has the following 5 endpoints:

* `/common_ancestor?a=<node_id>&b=<node_id>`

* `/birds?node_ids[]=<node_id>&node_ids[]=<node_id>&node_ids[]=<node_id>`

* `/generate_csv_for_seeding?node_filename=<filename>&bird_filename=<filename>&number_of_trees=<number>&number_of_nodes_per_tree=<number>&number_of_birds_per_tree=<number>`

* `/seed_data_from_csv?node_path=<path/to/nodes>&bird_path=<path/to/birds>`

* `/delete_all_data`

### Detailed Endpoint Instructions

`/common_ancestor` takes in two node ids as parameters `a` and `b`. These nodes do not need to be part of the same tree.
If these two nodes are part of the same tree, the response will include the id of the tree's root, the id of the two nodes' lowest common ancestor, and the depth of that lowest common ancestor.
If these two nodes are NOT part of the same tree, all of these values will instead be "null".

`/birds` takes in an array of node ids as an array parameter `node_ids[]`. These nodes do not need to be part of the same tree.
The response will be a list of ids of any bird which belongs to one of the specified nodes, as well as any nodes which are descendant from the specified nodes.

`/generate_csv_for_seeding` takes in five parameters: `node_filename`, `bird_filename`, `number_of_trees`, `number_of_nodes_per_tree`, and `number_of_birds_per_tree`.
The resulting files will both end up in the public directory of the app structure, with the names provided in the two filename parameters.
The other three parameters will allow the user to specify the amount of nodes and birds to be created, and how to split them up among the various tree structures.

`/seed_data_from_csv` takes in two relative file paths as parameters `node_path` and `bird_path`.
The files at these locations should be CSV files with the information necessary to create nodes and birds, respectively.
The node file should have a header line containing "id,parent_id", and each subsequent line should contain the id of the node to create, as well as the id of the node's intended parent, which is optional.
The bird file should have a header line containing "id,node_id", and each subsequent line should contain the id of the bird to create, as well as the id of the bird's associated node, which is required.
It should be noted that this endpoint is not usable while the database contains any birds or nodes. This is to prevent any awkward and unintentional data problems.

`/delete_all_data` does not take in any parameters. It will simply wipe all nodes and birds from the database, so that the seed endpoint can be utilized once again.