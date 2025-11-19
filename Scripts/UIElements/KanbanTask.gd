extends Control
class_name KanbanTask

@onready var name_label := %NameLabel
@onready var assignee_label :=%AssigneeLabel

@onready var edit_button := %EditButton
@onready var delete_button := %DeleteButton

@export var icon_details := preload("res://Assets/Icons/More.png")

var task_id := ""
var task_status :="to-do"

var on_edit : Callable
var on_delete : Callable

var _press_pos: Vector2 = Vector2.ZERO

func set_info(_task_id:String,_task_status:String):
	task_id = _task_id
	task_status = _task_status

func set_displayed_info(task_name:String, assignee_uid:String):
	name_label.text = task_name
	if assignee_uid =="":
		assignee_label.text = "Assigned: None"
	else:
		assignee_label.text ="Assigned: %s" % Project.get_member_name(assignee_uid)
	
	if Project.user_role == "owner" or Project.user_role =="manager":
		delete_button.visible=true
	elif assignee_uid != Session.uid:
		edit_button.icon = icon_details

#region dragging
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_pos = event.position
		else:
			_press_pos = Vector2.ZERO

# Godot calls this automatically when a drag starts over this Control
func _get_drag_data(_at_position: Vector2) -> Variant:
	var data := {"task_id": task_id, "status": task_status}
	var preview := _make_drag_preview()
	set_drag_preview(preview)
	DragManager.start_drag(data)
	return data

func _make_drag_preview() -> Control:
	return duplicate()
#endregion

#region callbacks
# I do that instead of Callable.bind because i dont want to create 2 copies of
# Callables for every task - which there may be hundreds to load at one moment
func set_callbacks(_on_edit:Callable, _on_delete:Callable):
	on_edit = _on_edit
	on_delete = _on_delete

func _on_edit_button_pressed() -> void:
	on_edit.call(task_id)

func _on_delete_button_pressed() -> void:
	on_delete.call(task_id)
#endregion
