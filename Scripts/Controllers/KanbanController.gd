extends Tab

@onready var create_task_popup : CreateTaskPopup = %CreateTaskPopup
@onready var confirm_critical_popup : ConfirmCriticalPopup = %ConfirmCriticalPopup
@onready var view_edit_task_popup :ViewEditTaskPopup= %ViewEditTaskPopup

@onready var to_do_container : VBoxContainer = %ToDoContainer
@onready var in_progress_container : VBoxContainer = %InProgressContainer
@onready var done_container : VBoxContainer = %DoneContainer
@onready var cancelled_container : VBoxContainer = %CancelledContainer

@export var task_control_prefab := preload("res://scenes/UIElements/KanbanTask.tscn")

var tasks_controls := {}  # map id -> Control
var user_role := ""

func _ready():
	_clear()

func open():
	user_role = Project.user_role
	
	Project.tasks_updated.connect(update_task_data)
	Project.project_updated.connect(on_project_updated)
	update_task_data(Project.tasks_data)

func close():
	_clear()
	Project.tasks_updated.disconnect(update_task_data)
	Project.project_updated.disconnect(on_project_updated)

func _clear():
	for child in to_do_container.get_children():
		child.queue_free()
	for child in in_progress_container.get_children():
		child.queue_free()
	for child in done_container.get_children():
		child.queue_free()
	for child in cancelled_container.get_children():
		child.queue_free()
	tasks_controls = {}

func on_project_updated():
	if Project.user_role != user_role:
		open()

func update_task_data(updated: Dictionary):
	for task_id in updated.keys():
		update_task_control(task_id)

func update_task_control(id:String):
	
	if !Project.tasks_data.has(id) and tasks_controls.has(id):
		tasks_controls[id].queue_free()
		return
		
	var task = Project.tasks_data[id]
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
		func(a: KanbanTask, b: KanbanTask): 
			return Project.tasks_data[a.task_id]["updatedAt"]>\
					Project.tasks_data[b.task_id]["updatedAt"]
	)
	
	for node in container.get_children():
		container.remove_child(node)

	for node in children:
		container.add_child(node)

#region Task actions callbacks
func on_edit_task_pressed(_task_id: String):
	view_edit_task_popup.visible = true
	view_edit_task_popup.initialize(_task_id,
			Project.tasks_data[_task_id],Project.user_role)

func on_delete_task_pressed(task_id: String):
	confirm_critical_popup.visible = true
	
	confirm_critical_popup.set_info("Delete task?",
			'All data related to "%s" will be deleted irreversibly.'%\
					Project.tasks_data[task_id]["title"]+
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
