extends Control

@export var button_scene: PackedScene
@onready var progression_layer: CanvasLayer = $ProgressionLayer
@onready var achievement_panel: VBoxContainer = %AchievementPanel

var continue_run = false


func _ready():
	var save = SaveManager.load_from_file()
	if save != null and !Globals.story_ended:
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
		ctrl.custom_minimum_size.y = 64
		$Background/MarginContainer/OutputTable/ContentColumn.add_child(ctrl)
		btn = button_scene.instantiate()
		btn.text = "afficher la progression"
		btn.custom_minimum_size.x = 512
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.pressed.connect(show_progress)

		center = CenterContainer.new()
		center.add_child(btn)
		$Background/MarginContainer/OutputTable/ContentColumn.add_child(center)
		
		ctrl = Control.new()
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
	for path in Globals.paths.keys():
		Globals.paths[path][0] = false
	get_tree().reload_current_scene()
	pass

func show_progress():
	#test affichage des achievements
	var saved_data = SaveManager.load_from_file()
	if saved_data[0] != "":
		var dejson = JSON.parse_string(saved_data[0])
		var fields = dejson["state"]["fields"]
		for path in Globals.paths.keys():
			if path in fields:
				Globals.paths[path][0] = Globals.paths[path][0] || fields[path]
		
	achievement_panel.init_with_data(Globals.paths)
	
	progression_layer.show()
	
func hide_progress():
	progression_layer.hide()


func _on_choice_button_pressed() -> void:
	hide_progress()
