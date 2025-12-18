extends VBoxContainer

@export var status:="to_do"
var ghost: Control = null

func _enter_tree() -> void:
	DragManager.drag_started.connect(on_drag_started)
	DragManager.drag_ended.connect(on_drag_ended)

func _exit_tree() -> void:
	DragManager.drag_started.disconnect(on_drag_started)
	DragManager.drag_ended.disconnect(on_drag_ended)

func on_drag_started(_data):
	for child in get_children():
		child.mouse_filter = MOUSE_FILTER_PASS
		child.mouse_behavior_recursive = MOUSE_BEHAVIOR_DISABLED

func on_drag_ended():
	for child in get_children():
		child.mouse_filter = MOUSE_FILTER_STOP
		child.mouse_behavior_recursive = MOUSE_BEHAVIOR_INHERITED

func _can_drop_data(_position: Vector2, data) -> bool:
	if not DragManager.dragging:
		return false
	
	if !data.has("task_id"):
		return false
	
	DragManager.set_ghost_column(null if data["status"] == status else self )
	return true

func _drop_data(_position: Vector2, data) -> void:
	DragManager.clear_ghost()
	var task_id = data.get("task_id", null)
	if task_id == null:
		return
	TaskService.update_status(Project.pid,task_id,status)

# Ghost helpers (used by DragManager)
func ensure_ghost() -> void:
	if ghost:
		return
	ghost = _make_simple_ghost()
	add_child(ghost)
	move_child(ghost, 0)
	ghost.modulate = Color(1,1,1,0.6)

func remove_ghost() -> void:
	if ghost:
		ghost.queue_free()
		ghost = null

func _make_simple_ghost() -> Control:
	var c = PanelContainer.new()
	var l = Label.new()
	l.text = "Change status"
	c.add_child(l)
	c.custom_minimum_size = Vector2(200, 60)
	c.mouse_filter = MOUSE_FILTER_PASS
	c.mouse_behavior_recursive = MOUSE_BEHAVIOR_DISABLED
	return c
