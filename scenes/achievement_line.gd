extends HBoxContainer

@export var OK_texture = Texture2D
@export var NOK_texture = Texture2D

@onready var label: Label = $Label
@onready var state_icon: TextureRect = $StateIcon

func _ready():
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_override("font", Globals.font_regular)
		label.add_theme_font_size_override("font_size", Globals.FONT_SIZE)
		label.add_theme_color_override("font_color", Globals.TEXT_COLOR)

func set_text(text: String):
	label.text = text
	
func set_state(state: bool):
	if state:
		state_icon.texture = OK_texture
		state_icon.modulate = Color(0.47, 0.808, 0.0, 1.0)
	else:
		state_icon.texture = NOK_texture
		state_icon.modulate = Color(0.998, 0.29, 0.239, 1.0)
