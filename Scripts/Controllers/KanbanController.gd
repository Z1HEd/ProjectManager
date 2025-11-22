extends Tab

@onready var create_task_popup : CreateTaskPopup = %CreateTaskPopup
@onready var confirm_critical_popup : ConfirmCriticalPopup = %ConfirmCriticalPopup
@onready var view_edit_task_popup :ViewEditTaskPopup= %ViewEditTaskPopup

@onready var to_do_container : VBoxContainer = %ToDoContainer
@onready var in_progress_container : VBoxContainer = %InProgressContainer
@onready var done_container : VBoxContainer = %DoneContainer
@onready var cancelled_container : VBoxContainer = %CancelledContainer
@onready var error_label : Label = %ErrorLabel

@export var task_control_prefab := preload("res://Scenes/Elements/KanbanTask.tscn")

var tasks_data := {}
var tasks_controls := {}  # map id -> Control
var latest_updated_at :=0

func open():
	error_label.visible = false
	
	for child in to_do_container.get_children():
		child.queue_free()
	for child in in_progress_container.get_children():
		child.queue_free()
	for child in done_container.get_children():
		child.queue_free()
	for child in cancelled_container.get_children():
		child.queue_free()
	tasks_controls = {}
	latest_updated_at = 0
	
	var _on_fail = func(err):
		error_label.text = err
		error_label.visible = true
	
	var _on_success = func(tasks: Dictionary):
		update_task_data(tasks)
		TaskService.start_listening(Project.pid,latest_updated_at,update_task_data,_on_fail)
	
	Project.update_member_names()
	TaskService.get_all(Project.pid, _on_success, _on_fail)

func close():
	TaskService.stop_listening(Project.pid)

func update_task_data(updated: Dictionary):
	for task_id in updated.keys():
		var patch = updated[task_id]
		
		if patch == null:
			tasks_data.erase(task_id)
		elif tasks_data.has(task_id):
			tasks_data[task_id].merge(patch, true)
		else:
			tasks_data[task_id] = patch.duplicate(true)

		if tasks_data.has(task_id) and tasks_data[task_id].has("updatedAt"):
			var task_updated_at = tasks_data[task_id]["updatedAt"]
			if task_updated_at > latest_updated_at:
				latest_updated_at = task_updated_at

		update_task_control(task_id)


func update_task_control(id:String):
	
	if !tasks_data.has(id) and tasks_controls.has(id):
		tasks_controls[id].queue_free()
		return
		
	var task = tasks_data[id]
	var title = task["title"]
	var assignee_uid = task.get("assignedTo","")
	
	var task_ctrl = tasks_controls.get(id,task_control_prefab.instantiate())
	task_ctrl.set_info(id,task["status"])
	task_ctrl.call_deferred("set_displayed_info",title, assignee_uid)
	task_ctrl.set_callbacks(
			on_edit_task_pressed,
			on_delete_task_pressed)
	var status = task["status"]
	var container: VBoxContainer
	
	match status:
		"to_do":
			container = to_do_container
		"in_progress":
			container = in_progress_container
		"done":
			container = done_container
		"cancelled":
			container = cancelled_container
	
	if (tasks_controls.has(id)):
		task_ctrl.reparent(container)
	else:
		container.add_child(task_ctrl)
	
	tasks_controls[id] = task_ctrl
	sort_container(container)

func sort_container(container:VBoxContainer):
	var children := container.get_children()
	
	children.sort_custom(
		# For descending order use > 0
		func(a: KanbanTask, b: KanbanTask): 
			return tasks_data[a.task_id]["updatedAt"]>\
					tasks_data[b.task_id]["updatedAt"]
	)
	
	for node in container.get_children():
		container.remove_child(node)

	for node in children:
		container.add_child(node)

#region Task actions callbacks
func on_edit_task_pressed(_task_id: String):
	view_edit_task_popup.visible = true
	view_edit_task_popup.initialize(_task_id,tasks_data[_task_id],Project.user_role)

func on_delete_task_pressed(task_id: String):
	confirm_critical_popup.visible = true
	
	confirm_critical_popup.set_info("Delete task?",
			'All data related to "%s" will be deleted irreversibly.'%\
					tasks_data[task_id]["title"]+
			' Enter "DELETE" to confirm',
			"DELETE")
	
	confirm_critical_popup.set_callbacks(func(_res):
			TaskService.delete_task(Project.pid,task_id))
#endregion

#region Create task callbacks
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
#endregion
