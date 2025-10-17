extends Node

# Adjust node paths to match your scene hierarchy:
# - LineEdit nodes named EmailInput, PasswordInput
# - Button node RegisterButton
# - Label ErrorLabel (optional)

@onready var email_input := $CenterContainer/VBoxContainer/VBoxContainer/Email/EmailInput
@onready var password_input := $CenterContainer/VBoxContainer/VBoxContainer/Password/PasswordInput
@onready var register_button := $CenterContainer/VBoxContainer/VBoxContainer/Buttons/RegisterButton
@onready var error_label := $CenterContainer/VBoxContainer/VBoxContainer/ErrorLabel

func _on_register_button_pressed() -> void:
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	error_label.text = ""
	if email == "" or password == "":
		_set_error_label("Email and password required")
		return
	register_button.disabled = true
	RegisterService.register_user(email, password, Callable(self, "_on_register_success"), Callable(self, "_on_register_fail"))

func _on_register_success(_session):
	register_button.disabled = false
	get_tree().change_scene_to_file("res://Scenes/Screens/MainMenu.tscn")

func _on_register_fail(err_msg: String):
	register_button.disabled = false
	_set_error_label(str(err_msg))

func _set_error_label(v = ""):
	if has_node("ErrorLabel"):
		$ErrorLabel.text = v

func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Screens/WelcomeScreen.tscn")
