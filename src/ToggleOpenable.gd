extends Openable

export (Array, String) var close_nodes

func open():
	var parent = get_parent()
	for c in close_nodes:
		var node = parent.get_node(c)
		node.close()
		
	.open()