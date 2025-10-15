extends Control

func _on_register_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Screens/RegisterScreen.tscn")

func _on_login_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Screens/LoginScreen.tscn")

func _on_test_connection_button_pressed() -> void:
	%FirebaseManager.test_connection()
	
