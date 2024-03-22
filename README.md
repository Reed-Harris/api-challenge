# README

## API OVERVIEW

This project is a simple API which deals with adjacency trees made up of nodes, each of which has its own id, as well as the id of its parent, which is optional.
Any given node may also have any number of birds associated with it.
After first cloning this repository, the user will need to utilize the `/seed_data_from_csv` endpoint in order to populate the database with both nodes and birds.
For convenience, there is also the `/delete_all_data` endpoint.

## ENDPOINT OVERVIEW

This API has the following 4 endpoints:

* `/common_ancestor?a=<node_id>&b=<node_id>`

* `/birds?node_ids[]=<node_id>&node_ids[]=<node_id>&node_ids[]=<node_id>`

* `/seed_data_from_csv?node_path=<path/to/nodes>&bird_path=<path/to/birds>`

* `/delete_all_data`

### Detailed Endpoint Instructions

`/common_ancestor` takes in two node ids as parameters `a` and `b`. These nodes do not need to be part of the same tree.
If these two nodes are part of the same tree, the response will include the id of the tree's root, the id of the two nodes' lowest common ancestor, and the depth of that lowest common ancestor.
If these two nodes are NOT part of the same tree, all of these values will instead be "null".

`/birds` takes in an array of node ids as an array parameter `node_ids[]`. These nodes do not need to be part of the same tree.
The response will be a list of ids of any bird which belongs to one of the specified nodes, as well as any nodes which are descendant from the specified nodes.

`/seed_data_from_csv` takes in two relative file paths as parameters `node_path` and `bird_path`.
The files at these locations should be CSV files with the information necessary to create nodes and birds, respectively.
The node file should have a header line containing "id,parent_id", and each subsequent line should contain the id of the node to create, as well as the id of the node's intended parent, which is optional.
The bird file should have a header line containing "id,node_id", and each subsequent line should contain the id of the bird to create, as well as the id of the bird's associated node, which is required.
It should be noted that this endpoint is not usable while the database contains any birds or nodes. This is to prevent any awkward and unintentional data problems.

`/delete_all_data` does not take in any parameters. It will simply wipe all nodes and birds from the database, so that the seed endpoint can be utilized once again.