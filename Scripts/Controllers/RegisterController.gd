extends Control

@onready var name_input : LineEdit =%NameInput
@onready var email_input : LineEdit = %EmailInput
@onready var password_input : LineEdit = %PasswordInput
@onready var register_button : Button = %RegisterButton

func _on_register_button_pressed() -> void:
	var email = email_input.text.strip_edges()
	var user_name = name_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if email == "":
		AppNotifications.push("Email is required!")
		return
	if user_name.length()<3:
		AppNotifications.push("Name should be at least 3 characters long!")
		return
	if password.length()<6:
		AppNotifications.push("Password should be at least 6 characters long!")
		return
		
	register_button.disabled = true
	
	var _on_success = func(_session):
		register_button.disabled = false
		get_tree().change_scene_to_file("res://scenes/Screens/MainMenu.tscn")

	var _on_fail = func(_err_msg: String):
		register_button.disabled = false
	
	UserService.register(email,user_name, password, _on_success, _on_fail)



func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Screens/WelcomeScreen.tscn")
