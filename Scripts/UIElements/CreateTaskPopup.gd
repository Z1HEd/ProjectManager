extends Control
class_name CreateTaskPopup

@onready var name_input : LineEdit = %NameEdit
@onready var description_input : TextEdit = %DescriptionEdit
@onready var status_input : OptionButton = %StatusOptionButton
@onready var priority_input : OptionButton = %PriorityOptionButton
@onready var assignee_input : OptionButton = %AssigneeOptionButton

@onready var create_button : Button = %SubmitButton

@onready var error_label := %ErrorLabel

func initialize(initial_status: int):
	name_input.text = ""
	description_input.text = ""
	status_input.select(initial_status)

func _on_submit_success(_res):
	visible = false

func _on_submit_fail(err_msg: String):
	error_label.text = err_msg
	error_label.visible = true
	create_button.disabled = false

func _on_submit_button_pressed() -> void:
	error_label.visible = false
	
	var title = name_input.text.strip_edges()
	var description = description_input.text.strip_edges()
	if title == "":
		error_label.text = "Task must have a title!"
		error_label.visible = true
		return

	var status = _get_status()
	var priority = _get_priority()
	var assignee_uid := _get_assignee_uid()
	
	create_button.disabled = true
	TaskService.add_task(
			Project.pid, 
			title, 
			description, 
			assignee_uid, 
			priority, 
			status, 
			_on_submit_success, 
			_on_submit_fail)

func _on_cancel_button_pressed() -> void:
	visible = false

func _get_status()->String:
	match status_input.get_selected():
		0: return "to_do"
		1: return "in_progress"
		2: return "done"
		3: return "cancelled"
	return ""

func _get_priority()->String:
	match priority_input.get_selected():
		0: return "low"
		1: return "medium"
		2: return "high"
		3: return "critical"
	return ""

func _get_assignee_uid()->String:
	if assignee_input.get_selected() == -1 :
		return ""
	var assignee_name = assignee_input.get_item_text(assignee_input.get_selected())
	for uid in Project.members_names.keys():
		if Project.members_names[uid] == assignee_name:
			return uid
	return ""
