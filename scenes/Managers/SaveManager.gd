extends Node

const path = "user://save_game.dat"

func save_to_file(content):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(content))


func load_from_file():
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var j = JSON.new()
		var erreur = j.parse(file.get_line())
		if erreur == OK:	
			var content = j.data
			return content
	else:
		print(FileAccess.get_open_error())
		return null

func delete_file():
	var dir = DirAccess.remove_absolute(path)
