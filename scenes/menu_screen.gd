extends Control

@export var button_scene: PackedScene

var continue_run = false

func _ready():
	var save = SaveManager.load_from_file()
	if save != null:
		continue_run = true
	
	# Restart button
	var btn := button_scene.instantiate()
	if continue_run:
		btn.text = "Continuer"
	else:
		btn.text = "Nouvelle partie"
	btn.custom_minimum_size.x = 512
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.pressed.connect(_start_story)

	var center := CenterContainer.new()
	center.add_child(btn)
	$Background/MarginContainer/OutputTable/ContentColumn.add_child(center)
	
	if continue_run:
		var ctrl = Control.new()
		ctrl.custom_minimum_size.y = 256
		$Background/MarginContainer/OutputTable/ContentColumn.add_child(ctrl)
		btn = button_scene.instantiate()
		btn.text = "supprimer la sauvegarde"
		btn.custom_minimum_size.x = 512
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.pressed.connect(delete_progression)

		center = CenterContainer.new()
		center.add_child(btn)
		$Background/MarginContainer/OutputTable/ContentColumn.add_child(center)


func _start_story():
	#Globals.fade_music()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	pass

func delete_progression():
	SaveManager.delete_file()
	get_tree().reload_current_scene()
	pass
