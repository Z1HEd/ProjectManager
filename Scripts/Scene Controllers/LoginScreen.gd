extends Node

func _on_return_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Screens/WelcomeScreen.tscn")

func _on_sign_in_pressed() -> void:
	print("Signing in...")
	
	# Sign in code here
	
	print("Signed in!")
	
	get_tree().change_scene_to_file("res://Scenes/Screens/MainMenu.tscn")
