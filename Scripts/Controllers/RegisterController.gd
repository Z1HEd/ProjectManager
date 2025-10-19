extends Control

@onready var email_input : LineEdit = $CenterContainer/VBoxContainer/VBoxContainer/Email/EmailInput
@onready var password_input : LineEdit = $CenterContainer/VBoxContainer/VBoxContainer/Password/PasswordInput
@onready var register_button : Button = $CenterContainer/VBoxContainer/VBoxContainer/Buttons/RegisterButton
@onready var error_label : Label = $CenterContainer/VBoxContainer/VBoxContainer/ErrorLabel

func _on_register_button_pressed() -> void:
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	error_label.text = ""
	if email == "" or password == "":
		error_label.text="Email and password required"
		return
	register_button.disabled = true
	RegisterService.register_user(email, password, Callable(self, "_on_register_success"), Callable(self, "_on_register_fail"))

func _on_register_success(_session):
	register_button.disabled = false
	get_tree().change_scene_to_file("res://Scenes/Screens/MainMenu.tscn")

func _on_register_fail(err_msg: String):
	register_button.disabled = false
	error_label.text=err_msg

func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Screens/WelcomeScreen.tscn")
