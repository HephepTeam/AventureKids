extends Control

# Loreline runtime
var loreline: Loreline = Loreline.shared()
var options: LorelineOptions

@export var button_scene: PackedScene
@export var achievement_panel_scene: PackedScene

# Node references
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var output_table: HBoxContainer = $ScrollContainer/MarginContainer/OutputTable
@onready var content_column: VBoxContainer = $ScrollContainer/MarginContainer/OutputTable/ContentColumn
@onready var keeper_column: Control = $ScrollContainer/MarginContainer/OutputTable/KeeperColumn



# State
var script_data: LorelineScript
var bottom_spacer: Control



# Sounds
@onready var clic_choice: AudioStreamPlayer = $clicChoice

@onready var sound_list = {
	"appel_papa" : $Sfx/appel_papa,
	"ptit_dej" : $Sfx/ptitdej,
	"roof_crush": $Sfx/roof_crush,
	"giant_walk" : $Sfx/giant_walk,
	"giant_sigh" : $Sfx/giant_sigh,
	"gnome_panic" : $Sfx/gnome_panic,
	"gnome_aspiro" : $Sfx/gnome_aspiro,
	"gnome_steps" : $Sfx/gnome_pas,
	"weird_bird" : $Sfx/weird_bird,
	"toboggan": $Sfx/toboggan,
	"grumble" : $Sfx/grumble
	
}

# paths
	
@onready var paths ={
	"sorti_lit" : [false, "A quitté son lit"],
	"ptit_dej":[ false, "A pris à petit déjeuner"],
	"vu_geant":[ false, "A vu un géant"],
	"rendu_pipe":[ false, "A rendu la pipe géante"],
	"jette_pipe":[ false, "S'est débarassé de la pipe"],
	"toboggan":[ false, "A fait un tour en toboggan"],
	"reve_fait":[ false, "A fait un drôle de rêve"],
	"vu_lutins":[false, "A vu des lutins"],
	"papa_convaincu":[ false, "A convaincu son père"],
	"chasser_boule":[ false, "A pourchassé une drôle de boule"],
	"vu_oiseau_colline":[ false, "A fait de l'ornythologie"],
	"vu_fourmi_tunnel":[ false, "A visité une fourmillière"],
	"vaincu_pirate":[ false, "A défait une bande de pirates"],
	"visite_minecraft":[false, "A fait un tour dans un jeu vidéo"]
}

func _ready() -> void:
	if Globals.font_regular == null or Globals.font_semibold == null or Globals.font_italic == null:
		push_error("Loreline sample: missing font files in res://fonts/ (Outfit-Regular.ttf, Outfit-SemiBold.ttf, Literata-Italic.ttf)")
		printerr("Loreline sample: missing font files in res://fonts/")
		return

	# Remove default ScrollContainer panel padding
	scroll_container.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	# Style scrollbar — thin, subtle
	var scrollbar := scroll_container.get_v_scroll_bar()
	scrollbar.custom_minimum_size.x = 7
	var grabber_style := StyleBoxFlat.new()
	grabber_style.bg_color = Globals.BORDER_COLOR
	grabber_style.set_corner_radius_all(16)
	scrollbar.add_theme_stylebox_override("grabber", grabber_style)
	scrollbar.add_theme_stylebox_override("grabber_highlight", grabber_style)
	scrollbar.add_theme_stylebox_override("grabber_pressed", grabber_style)
	var scroll_bg := StyleBoxEmpty.new()
	scrollbar.add_theme_stylebox_override("scroll", scroll_bg)

	await get_tree().create_timer(1.0).timeout

	options = LorelineOptions.new()
	options.set_async_function("play_sound", _play_sound)
	# parse() returns a Signal you can await — it fires `completed(script)`
	# once parsing + all imports have resolved.
	var script = await loreline.parse("res://story/AventureEnfants.lor")
	
	if script == null:
		var err := "Loreline sample: failed to parse res://story/CoffeeShop.lor"
		push_error(err)
		printerr(err)
		return
		
	script_data = script
	_start_story()



func _play_sound(interp: LorelineInterpreter, args: Array, resolve: Callable) -> void:
	print(args)
	if args[0] in sound_list.keys():
		var sound = sound_list[args[0]]
		sound.pitch_scale = randf_range(0.9,1.1)
		sound.play()
		await sound.finished
	else:
		assert(false, "no sound called " + args[0]+" in sound list")
	resolve.call()

func _start_story() -> void:
	# Clear previous content
	for child in content_column.get_children():
		child.queue_free()
	keeper_column.custom_minimum_size.y = 0

	# Top padding spacer
	var top_spacer := Control.new()
	top_spacer.custom_minimum_size.y = Globals.TOP_PADDING
	content_column.add_child(top_spacer)

	# Bottom padding spacer (kept at end of content column)
	bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size.y = Globals.BOTTOM_PADDING
	content_column.add_child(bottom_spacer)

	var saved_data = SaveManager.load_from_file()
	if saved_data != null and !Globals.retry:
		var resumed := loreline.resume(script_data, _on_dialogue, _on_choice, _on_finished, saved_data[0],"",options)
	else:
		loreline.play(script_data, _on_dialogue, _on_choice, _on_finished, "", options)

# --- Signal Handlers ---

func _on_dialogue(interp: LorelineInterpreter, character: String, text: String, _tags: Array, advance: Callable) -> void:
	
	var saved_data = []
	saved_data.append(interp.save_state())
	saved_data.append(paths)
	SaveManager.save_to_file(saved_data)

	
	# Add spacing before new dialogue if content exists (> 2 because of top_spacer + bottom_spacer)
	if content_column.get_child_count() > 2:
		var spacer := Control.new()
		spacer.custom_minimum_size.y = Globals.LINE_SPACING
		_add_content(spacer)

	if character != "":
		# Resolve display name
		var temp = interp.get_character_field(character, "name")
		var display_name: String
		if temp != null:
			display_name = temp
			if display_name != "":
				character = display_name
		else:
			display_name = character

		# Character name + dialogue on same line (matching Unity/web)
		var label := RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.add_theme_font_override("normal_font", Globals.font_regular)
		label.add_theme_font_override("bold_font", Globals.font_semibold)
		label.add_theme_font_size_override("normal_font_size", Globals.FONT_SIZE)
		label.add_theme_font_size_override("bold_font_size", Globals.FONT_SIZE)
		label.add_theme_color_override("default_color", Globals.TEXT_COLOR)
		var col = Color("f35838ff")
		label.text = "[b][color=#"+col.to_html() +"]" + character + " : " + "[/color][/b]" + text
		_add_content(label)
		_fade_in(label)
	else:
		# Narrative text — italic, muted
		var text_label := Label.new()
		text_label.text = text
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_label.add_theme_font_override("font", Globals.font_italic)
		text_label.add_theme_font_size_override("font_size", Globals.FONT_SIZE)
		text_label.add_theme_color_override("font_color", Globals.TEXT_MUTED)
		_add_content(text_label)
		_fade_in(text_label)

	_update_keeper()
	_smooth_scroll_to_bottom()

	# Auto-advance after delay (matching Unity/web)
	await get_tree().create_timer(Globals.DIALOGUE_DELAY).timeout
	advance.call()


func _on_choice(_interp: LorelineInterpreter, options: Array, select: Callable) -> void:
	# Delay before showing choices (matching Unity/web)
	await get_tree().create_timer(Globals.CHOICE_DELAY).timeout

	# Add spacing
	var spacer := Control.new()
	spacer.custom_minimum_size.y = Globals.SECTION_SPACING
	_add_content(spacer)

	var choices_container := VBoxContainer.new()
	choices_container.add_theme_constant_override("separation", Globals.CHOICE_SPACING)
	_add_content(choices_container)
	Globals.fade_music()	
	for i in range(options.size()):
		var option: Dictionary = options[i]
		var enabled: bool = option["enabled"]
		if not enabled:
			continue

		#var btn := Button.new()
		var btn = button_scene.instantiate()
		btn.text = option["text"]
		btn.pressed.connect(_on_button_pressed)

		# Text colors
		btn.add_theme_color_override("font_color", Globals.TEXT_COLOR)
		btn.add_theme_color_override("font_hover_color", Globals.TEXT_COLOR)
		btn.add_theme_color_override("font_pressed_color", Globals.TEXT_COLOR)

		var index := i
		var container_ref := choices_container
		btn.pressed.connect(_on_choice_selected.bind(index, btn, container_ref, select))

		choices_container.add_child(btn)

		# Fade in all buttons simultaneously
		btn.modulate.a = 0
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(btn, "modulate:a", 1.0, Globals.FADE_DURATION)

	_update_keeper()
	_smooth_scroll_to_bottom()


func _on_choice_selected(index: int, selected_btn: Button, container: VBoxContainer, select: Callable) -> void:
	# Prevent double-clicks
	for child in container.get_children():
		if child is Button:
			child.disabled = true

	# Phase 1 (0ms): Highlight selected, fade out others
	var highlight_style := StyleBoxFlat.new()
	highlight_style.bg_color = Globals.CHOICE_BG_KEPT
	highlight_style.border_color = Globals.ACCENT_PURPLE
	highlight_style.set_border_width_all(4)
	highlight_style.set_corner_radius_all(32)
	highlight_style.set_content_margin_all(20)
	highlight_style.content_margin_left = 28
	highlight_style.content_margin_right = 28
	selected_btn.add_theme_stylebox_override("disabled", highlight_style)
	selected_btn.add_theme_color_override("font_disabled_color", Globals.TEXT_COLOR)

	for child in container.get_children():
		if child is Button and child != selected_btn:
			var fade := create_tween()
			fade.tween_property(child, "modulate:a", 0.0, 0.25)

	# Phase 2 (300ms): Slide selected button to top of container
	await get_tree().create_timer(0.3).timeout
	var offset: float = selected_btn.global_position.y - container.global_position.y
	if offset > 0:
		var slide := create_tween()
		slide.set_ease(Tween.EASE_IN_OUT)
		slide.set_trans(Tween.TRANS_CUBIC)
		slide.tween_property(selected_btn, "position:y", selected_btn.position.y - offset, 0.35)

	# Phase 3 (700ms): Hide others, reset position, continue
	await get_tree().create_timer(0.4).timeout
	for child in container.get_children():
		if child is Button and child != selected_btn:
			child.visible = false
	# Reset position offset — VBox now places button at top, so net visual change is zero
	selected_btn.position.y = 0

	select.call(index)


func _on_finished(_interp: LorelineInterpreter) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = Globals.SECTION_SPACING * 2
	_add_content(spacer)

	#test affichage des achievements
	var saved_data = SaveManager.load_from_file()
	if saved_data[0] != "":
		var dejson = JSON.parse_string(saved_data[0])
		var fields = dejson["state"]["fields"]
		for path in paths.keys():
			if path in fields:
				paths[path][0] = paths[path][0] || fields[path]
		
	var inst = achievement_panel_scene.instantiate()
	_add_content(inst)
	inst.init_with_data(paths)
	_fade_in(inst)
	
	spacer = Control.new()
	spacer.custom_minimum_size.y = Globals.SECTION_SPACING * 2
	_add_content(spacer)

	# Restart button
	var btn := Button.new()
	btn.text = "Recommencer"
	btn.add_theme_font_override("font", Globals.font_regular)
	btn.add_theme_font_size_override("font_size", Globals.CHOICE_FONT_SIZE)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER

	var style := StyleBoxFlat.new()
	style.bg_color = Globals.CHOICE_BG
	style.border_color = Globals.ACCENT_PURPLE
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	style.content_margin_left = 20
	style.content_margin_right = 20
	btn.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate()
	hover_style.bg_color = Globals.GLOW_BG
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.add_theme_color_override("font_color", Globals.ACCENT_PURPLE)
	btn.add_theme_color_override("font_hover_color", Globals.TEXT_COLOR)
	btn.pressed.connect(_start_story)

	Globals.retry = true
	
	
	var center := CenterContainer.new()
	center.add_child(btn)
	_add_content(center)

	_fade_in(center)
	_update_keeper()
	_smooth_scroll_to_bottom()


# File handler example for custom loading (encrypted files, network, etc.):
# func _handle_file(path: String) -> String:
# 	var f := FileAccess.open(path, FileAccess.READ)
# 	if f == null: return ""
# 	return _decrypt(f.get_buffer(f.get_length()))


# --- Helpers ---

func _add_content(node: Control) -> void:
	content_column.add_child(node)
	content_column.move_child(bottom_spacer, -1)


func _fade_in(node: Control) -> void:
	node.modulate.a = 0
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(node, "modulate:a", 1.0, Globals.FADE_DURATION)


func _update_keeper() -> void:
	await get_tree().process_frame
	var content_height := content_column.size.y
	if content_height > keeper_column.custom_minimum_size.y:
		keeper_column.custom_minimum_size.y = content_height


func _smooth_scroll_to_bottom() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var scrollbar := scroll_container.get_v_scroll_bar()
	var target: float = scrollbar.max_value - scrollbar.page
	var current: float = scroll_container.scroll_vertical
	if target <= current + 1.0:
		return
	var dist: float = target - current
	var duration: float = clampf(dist * 0.0012, Globals.SCROLL_MIN_DURATION, Globals.SCROLL_MAX_DURATION)
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(scroll_container, "scroll_vertical", int(target), duration)


func _gradient_bbcode(text: String) -> String:
	# 3-stop gradient matching Unity/web: #ff5eab → #8b5cf6 → #56a0f6
	var r0 := 255.0; var g0 := 94.0;  var b0 := 171.0  # #ff5eab (pink)
	var r1 := 139.0; var g1 := 92.0;  var b1 := 246.0  # #8b5cf6 (purple)
	var r2 := 86.0;  var g2 := 160.0; var b2 := 246.0  # #56a0f6 (blue)
	var t_min := 0.30
	var t_max := 0.70
	var result := ""
	var text_len := text.length()
	for i in range(text_len):
		var t: float = 0.4 if text_len <= 1 else t_min + (t_max - t_min) * float(i) / float(text_len - 1)
		var r: float; var g: float; var b: float
		if t <= 0.4:
			var s := t / 0.4
			r = r0 + (r1 - r0) * s
			g = g0 + (g1 - g0) * s
			b = b0 + (b1 - b0) * s
		else:
			var s := (t - 0.4) / 0.6
			r = r1 + (r2 - r1) * s
			g = g1 + (g2 - g1) * s
			b = b1 + (b2 - b1) * s
		var hex := "%02x%02x%02x" % [roundi(r), roundi(g), roundi(b)]
		result += "[color=#" + hex + "]" + text[i] + "[/color]"
	return result
	
func _on_button_pressed():
	clic_choice.play()
