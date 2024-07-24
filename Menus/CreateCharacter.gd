extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var sprite: Node2D = get_node("Sprite")

# Called when the node enters the scene tree for the first time.
func _ready():
	var current_skin = SavedData.skin
	var base_path = "res://Art/v1.1 dungeon crawler 16x16 pixel pack/heroes/portrait_{0}/".format([current_skin])
	var texture_path = base_path + "{0}.png".format([current_skin])
	print(texture_path)
	sprite.texture = load(texture_path)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Back_pressed():
	SceneTransistor.start_transition_to("res://Menus/MainMenu.tscn")

func _on_Create_pressed():
	SceneTransistor.start_transition_to("res://Menus/EditCharacter.tscn")
