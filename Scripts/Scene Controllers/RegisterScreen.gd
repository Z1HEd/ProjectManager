extends Node

func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Screens/WelcomeScreen.tscn")
	
func _on_register_button_pressed() -> void:
	print("Signing up...")
	
	# Sign up code here
	
	print("Signed up!")
	
	get_tree().change_scene_to_file("res://Scenes/Screens/MainMenu.tscn")
