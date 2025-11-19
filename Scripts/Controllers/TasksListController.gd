extends Tab

@onready var create_task_popup : CreateTaskPopup = %CreateTaskPopup
@onready var confirm_critical_popup : ConfirmCriticalPopup = %ConfirmCriticalPopup
@onready var view_edit_task_popup :ViewEditTaskPopup= %ViewEditTaskPopup

@onready var tasks_container : VBoxContainer = %TasksContainer

@onready var error_label : Label = %ErrorLabel

@export var task_control_prefab := preload("res://Scenes/Elements/ListTask.tscn")


var tasks_data := {}
var tasks_controls := {} # map id -> Control
# not needed for sorting here, but for starting a listener
var latest_updated_at := 0

func open():
	error_label.visible = false
	return
	for child in tasks_container.get_children():
		child.queue_free()
	
	var _on_fail = func(err):
		error_label.text = err
		error_label.visible = true
	
	var _on_success = func(tasks: Dictionary):
		update_task_data(tasks)
		TaskService.start_listening(Project.pid,latest_updated_at,update_task_data,_on_fail)
	
	Project.update_member_names()
	TaskService.get_all(Project.pid, _on_success, _on_fail)

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
	
	var task_ctrl = tasks_controls.get(id,task_control_prefab.instantiate())
	task_ctrl.set_id(id)
	task_ctrl.call_deferred("set_displayed_info",task)
	task_ctrl.set_callbacks(
			on_edit_task_pressed,
			on_delete_task_pressed)

#region Task actions callbacks
func on_edit_task_pressed(_task_id: String):
	view_edit_task_popup.visible = true
	view_edit_task_popup.initialize(_task_id,tasks_data[_task_id],Project.user_role)

func on_delete_task_pressed(task_id: String):
	confirm_critical_popup.visible = true
	
	confirm_critical_popup.set_info("Delete task?",
			'All data related to "%s" will be deleted irreversibly.'%\
					tasks_data[task_id]["title"]+
			'Enter "DELTE" to confirm',
			"DELETE")
	
	confirm_critical_popup.set_callbacks(func(_res):
			TaskService.delete_task(Project.pid,task_id))
#endregion
