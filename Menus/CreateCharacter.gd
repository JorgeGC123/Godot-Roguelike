extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var sprite: Node2D = get_node("VBoxContainer/Sprite")

# Called when the node enters the scene tree for the first time.
func _ready():
	if SavedData.skin == 1:
		sprite.texture = load("res://Art/v1.1 dungeon crawler 16x16 pixel pack/heroes/CharacterCreator/1.png")
	if SavedData.skin == 2:
		sprite.texture = load("res://Art/v1.1 dungeon crawler 16x16 pixel pack/heroes/CharacterCreator/2.png")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Back_pressed():
	SceneTransistor.start_transition_to("res://Menus/MainMenu.tscn")

func _on_Create_pressed():
	SceneTransistor.start_transition_to("res://Menus/EditCharacter.tscn")
