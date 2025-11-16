extends Control
class_name KanbanTask

@onready var name_label := %NameLabel
@onready var assignee_label :=%AssigneeLabel

@onready var more_button := %MoreButton
@onready var edit_button := %EditButton
@onready var delete_button := %DeleteButton

var task_id := ""

var on_edit : Callable
var on_more : Callable
var on_delete : Callable

func set_info(task_name:String, assignee_uid:String, _task_id : String):
	name_label.text = task_name
	if assignee_uid =="":
		assignee_label.text = "Assigned: None"
	else:
		assignee_label.text ="Assigned: %s" % Project.get_member_name(assignee_uid)
	task_id = _task_id
	
	if Project.user_role == "owner" or Project.user_role =="manager":
		edit_button.visible=true
		delete_button.visible=true
	elif assignee_uid == Session.uid:
		edit_button.visible = true
	else:
		more_button.visible = true

# I do that instead of Callable.bind because i dont want to create 3 copies of
# Callables for every task - which there may be hundreds to load at one moment
func set_callbacks(_on_edit:Callable, _on_more:Callable, _on_delete:Callable):
	on_edit = _on_edit
	on_more = _on_more
	on_delete = _on_delete

func _on_edit_button_pressed() -> void:
	on_edit.call(task_id)

func _on_more_button_pressed() -> void:
	on_more.call(task_id)

func _on_delete_button_pressed() -> void:
	on_delete.call(task_id)
