extends VBoxContainer

@export var achievement_line: PackedScene

func init_with_data(data):
	for path in data.keys():
		var line = achievement_line.instantiate()
		add_child(line)
		line.set_text(data[path][1])
		line.set_state(data[path][0])
		
		
