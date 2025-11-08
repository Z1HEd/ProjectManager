extends Control

@onready var name_input : LineEdit =%NameInput
@onready var email_input : LineEdit = %EmailInput
@onready var password_input : LineEdit = %PasswordInput
@onready var register_button : Button = $CenterContainer/VBoxContainer/VBoxContainer/Buttons/RegisterButton
@onready var error_label : Label = %ErrorLabel

func _on_register_button_pressed() -> void:
	var email = email_input.text.strip_edges()
	var user_name = name_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	error_label.text = ""
	if email == "":
		error_label.text="Email is required!"
		return
	if user_name.length()<3:
		error_label.text="Name should be at least 3 characters long!"
		return
	if password.length()<6:
		error_label.text="Password should be at least 6 characters long!"
		return
	register_button.disabled = true
	UserService.register(email,user_name, password, _on_register_success, _on_register_fail)

func _on_register_success(_session):
	register_button.disabled = false
	get_tree().change_scene_to_file("res://Scenes/Screens/MainMenu.tscn")

func _on_register_fail(err_msg: String):
	register_button.disabled = false
	error_label.text=err_msg

func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Screens/WelcomeScreen.tscn")
