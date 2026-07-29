extends Node

# Fonts
@export var font_regular: Font
@export var font_semibold: Font
@export var font_italic: Font

# Sizing
const FONT_SIZE := 54
const CHOICE_FONT_SIZE := 58
const LINE_SPACING := 32	
const CHOICE_SPACING := 16
const SECTION_SPACING := 18*2
const FADE_DURATION := 0.45
const SCROLL_MIN_DURATION := 0.25
const SCROLL_MAX_DURATION := 0.6
const DIALOGUE_DELAY := 0.6
const CHOICE_DELAY := 0.5
const TOP_PADDING := 30
const BOTTOM_PADDING := 200

# Colors
const BG_COLOR := Color("#273142")
const TEXT_COLOR := Color("#f0eef5")
const TEXT_MUTED := Color("#c0bdd0")
const TEXT_DIM := Color("#6b6580")
const ACCENT_PURPLE := Color("ce5640ff")
const BORDER_COLOR := Color("#2e2a3a")
const BORDER_HOVER := Color("#f0eef5")
const GLOW_BG := Color(0.545, 0.361, 0.965, 0.1)
const CHOICE_BG := Color("4c5475ff")
const CHOICE_BG_KEPT := Color("e33c00cc")


#gameplay
var retry = false

# paths
	
@onready var paths ={
	"sorti_lit" : [false, "A quitté son lit"],
	"ptit_dej":[ false, "A pris à petit déjeuner"],
	"rendu_pipe":[ false, "A rendu sa pipe a un géant"],
	"toboggan":[ false, "A fait un tour en toboggan"],
	"vu_lutins":[false, "A vu des lutins"],
	"papa_convaincu":[ false, "A convaincu son père"],
	"tour_velo" : [false, "A fait un tour à vélo"],
	"chasser_boule":[ false, "A pourchassé une drôle de boule"],
	"vu_oiseau_colline":[ false, "A fait de l'ornythologie"],
	"vu_fourmi_tunnel":[ false, "A visité une fourmillière"],
	"vaincu_pirate":[ false, "A défait une bande de pirates"],
	"visite_minecraft":[false, "A fait un tour dans un jeu vidéo"]
}


func fade_music():
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property($music, "volume_db", -80.0, 5.0)
