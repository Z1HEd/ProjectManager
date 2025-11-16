extends Tab

@onready var create_task_popup : CreateTaskPopup = %CreateTaskPopup

func open():
	pass

func _on_create_to_do_button_pressed() -> void:
	create_task_popup.initialize(0)
	create_task_popup.visible = true

func _on_create_in_progress_button_pressed() -> void:
	create_task_popup.initialize(1)
	create_task_popup.visible = true

func _on_create_done_button_pressed() -> void:
	create_task_popup.initialize(2)
	create_task_popup.visible = true

func _on_create_cancelled_button_pressed() -> void:
	create_task_popup.initialize(3)
	create_task_popup.visible = true
