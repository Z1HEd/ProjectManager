extends Control
class_name ListTask

@onready var name_label := %NameLabel
@onready var assignee_label :=%AssigneeLabel

@onready var edit_button := %EditButton
@onready var delete_button := %DeleteButton

@export var icon_details := preload("res://Assets/Icons/More.png")

var task_id := ""

var on_edit : Callable
var on_delete : Callable

func set_info(_task_id:String):
	task_id = _task_id

func set_displayed_info(data:Dictionary):
	
	name_label.text = data["title"]
	if data["assignedTo"] =="":
		assignee_label.text = "Assigned: None"
	else:
		assignee_label.text ="Assigned: %s" % Project.get_member_name(data["assignedTo"])
	
	if Project.user_role == "owner" or Project.user_role =="manager":
		delete_button.visible=true
	elif data["assignedTo"] != Session.uid:
		edit_button.icon = icon_details

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
