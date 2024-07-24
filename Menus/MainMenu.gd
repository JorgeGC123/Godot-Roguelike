extends Control

func _on_SinglePlayer_pressed():
	SceneTransistor.start_transition_to("res://Game.tscn")


func _on_Quit_pressed():
	 get_tree().quit()


func _on_Multiplayer_pressed():
	SceneTransistor.start_transition_to("res://Menus/Multiplayer.tscn")


func _on_CreateCharacter_pressed():
	SceneTransistor.start_transition_to("res:////Menus/CreateCharacter.tscn")
