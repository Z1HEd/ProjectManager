extends Node

@onready var email_input : LineEdit = %EmailInput
@onready var password_input : LineEdit = %PasswordInput
@onready var login_button : Button = %LoginButton
@onready var error_label : Label = %ErrorLabel

func _on_login_button_pressed() -> void:
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	error_label.text = ""
	if email == "" or password == "":
		error_label.text="Email and password required"
		return
	login_button.disabled = true
	UserService.login(email, password, _on_register_success, _on_register_fail)

func _on_register_success(_session):
	login_button.disabled = false
	get_tree().change_scene_to_file("res://Scenes/Screens/MainMenu.tscn")

func _on_register_fail(err_msg: String):
	login_button.disabled = false
	error_label.text=err_msg

func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Screens/WelcomeScreen.tscn")
