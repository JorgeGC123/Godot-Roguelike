extends Control

var game_started: bool = false


onready var create_dialog: AcceptDialog = get_node("CreateDialog")
onready var create_dialog_label: Label = create_dialog.get_node("ScrollContainer/VBoxContainer/Label")
onready var create_dialog_player_list: VBoxContainer = create_dialog.get_node("ScrollContainer/VBoxContainer/PlayerList")

onready var join_dialog: WindowDialog = get_node("JoinDialog")
onready var join_room_label: Label = join_dialog.get_node("WaitScrollContainer/VBoxContainer/Label")
onready var join_player_list: VBoxContainer = join_dialog.get_node("WaitScrollContainer/VBoxContainer/PlayerList")


func update_room(room_id: int) -> void:
	if Client.is_creator:
		create_dialog_label.text = "Room id: " + str(room_id)
	else:
		join_room_label.text = "Room id: " + str(room_id)
		join_dialog.connected_ok()


func _on_CreateButton_pressed() -> void:
	Client.create_room()
	create_dialog.popup_centered()
	
	
func _on_JoinButton_pressed() -> void:
	join_dialog.popup_centered()


func _on_popup_hide() -> void:
	print(get_tree().network_peer != null)
	print(game_started)
	if not game_started and get_tree().network_peer != null:
		print("a tomar xculo")
		Client.stop()


func add_player_to_ui(name: String) -> void:
	if Client.is_creator:
		create_dialog_player_list.add_player(name)
	else:
		join_player_list.add_player(name)
		
		
func remove_player(index: int) -> void:
	if Client.is_creator:
		create_dialog_player_list.remove_player(index)
	else:
		join_player_list.remove_player(index)


func remove_all_players() -> void:
	if Client.is_creator:
		create_dialog_player_list.remove_all()
		create_dialog.hide()
	else:
		join_player_list.remove_all()
		join_dialog.hide()


func _on_CreateDialog_confirmed() -> void:
	print("shit negro")
	Client.start_game()
