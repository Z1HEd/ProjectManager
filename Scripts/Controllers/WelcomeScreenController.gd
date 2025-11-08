extends Control

func on_authenticated():
	get_tree().change_scene_to_file("res://Scenes/Screens/MainMenu.tscn")

func _ready() -> void:
	Session.on_authenticated.connect(on_authenticated)

	if Session.is_logged_in():
		call_deferred("on_authenticated")

func _on_register_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Screens/RegisterScreen.tscn")

func _on_login_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Screens/LoginScreen.tscn")
