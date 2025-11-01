extends Node
class_name ProjectSelectionButton

signal project_selected
signal more_pressed

func _on_button_pressed() -> void:
	project_selected.emit()

func _on_more_pressed() -> void:
	more_pressed.emit()
