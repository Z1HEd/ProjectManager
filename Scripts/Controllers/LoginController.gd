extends Node

@onready var email_input : LineEdit = %EmailInput
@onready var password_input : LineEdit = %PasswordInput
@onready var login_button : Button = %LoginButton

func _on_login_button_pressed() -> void:
	
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if email == "" or password == "":
		AppNotifications.push("Email and password required")
		return
		
	login_button.disabled = true
	
	var _on_success = func(_session):
		login_button.disabled = false
		AppNotifications.push("Signed in as %s" % Session.email)
		get_tree().change_scene_to_file("res://scenes/Screens/MainMenu.tscn")
	
	var _on_register_fail = func(_err_msg: String):
		login_button.disabled = false
	
	UserService.login(email, password, _on_success, _on_register_fail)

func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Screens/WelcomeScreen.tscn")
