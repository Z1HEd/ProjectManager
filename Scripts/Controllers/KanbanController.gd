extends Tab

@onready var create_task_popup : CreateTaskPopup = %CreateTaskPopup
@onready var confirm_critical_popup : ConfirmCriticalPopup = %ConfirmCriticalPopup

@onready var to_do_container : VBoxContainer = %ToDoContainer
@onready var in_progress_container : VBoxContainer = %InProgressContainer
@onready var done_container : VBoxContainer = %DoneContainer
@onready var cancelled_container : VBoxContainer = %CancelledContainer
@onready var error_label : Label = %ErrorLabel

@export var task_control_prefab := preload("res://Scenes/Elements/KanbanTask.tscn")

var tasks_data := {}
var tasks_controls := {}

func open():
	error_label.visible = false
	
	# clear containers
	for child in to_do_container.get_children():
		child.queue_free()
	for child in in_progress_container.get_children():
		child.queue_free()
	for child in done_container.get_children():
		child.queue_free()
	for child in cancelled_container.get_children():
		child.queue_free()
	tasks_controls = {}

	var _on_success = func(tasks: Dictionary):
		tasks_data = tasks
		for id in tasks_data.keys():
			update_task(id)

	var _on_fail = func(err):
		error_label.text = err
		error_label.visible = true
	
	Project.update_member_names()
	TaskService.get_all(Project.pid, _on_success, _on_fail)
	

func update_task(id:String):
	var task = tasks_data[id]

	var task_ctrl = tasks_controls.get(id,task_control_prefab.instantiate())
	tasks_controls[id] = task_ctrl
	
	var title = task["title"]
	var assignee_uid = task.get("assignedTo","")
	
	task_ctrl.call_deferred("set_info",title, assignee_uid, id)
	task_ctrl.set_callbacks(
			on_edit_task_pressed,
			on_more_task_pressed,
			on_delete_task_pressed)
	
	var status = task["status"]
	
	match status:
		"to_do":
			to_do_container.add_child(task_ctrl)
		"in_progress":
			in_progress_container.add_child(task_ctrl)
		"done":
			done_container.add_child(task_ctrl)
		"cancelled":
			cancelled_container.add_child(task_ctrl)
		_: push_error("INVALID TASK STATUS: "+status)

func on_edit_task_pressed(_task_id: String):
	pass

func on_more_task_pressed(_task_id: String):
	pass

func on_delete_task_pressed(task_id: String):
	confirm_critical_popup.visible = true
	
	confirm_critical_popup.set_info("Delete task?",
			'All data related to "%s" will be deleted irreversibly.'%\
					tasks_data[task_id]["title"]+
			'Enter "DELTE" to confirm',
			"DELETE")
	
	confirm_critical_popup.set_callbacks(func(_res):
			TaskService.delete_task(Project.pid,task_id))

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
