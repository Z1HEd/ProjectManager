extends Button
class_name QuitButton
# A button that closes the application when pressed

func _ready() -> void:
	pressed.connect(_quit)

func _quit() -> void:
	get_tree().quit()
