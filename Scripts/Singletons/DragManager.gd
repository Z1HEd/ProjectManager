extends Node

var dragging: bool = false
var drag_data: Dictionary = {}
var current_ghost_column: Node = null

signal drag_started(data)
signal drag_ended()

func start_drag(data: Dictionary) -> void:
	dragging = true
	drag_data = data
	drag_started.emit(data)

func end_drag() -> void:
	dragging = false
	drag_data = {}
	drag_ended.emit()
	_clear_ghost_internal()

# Called by columns to set which column should show the ghost
func set_ghost_column(col: Node) -> void:
	if current_ghost_column == col:
		return
	_clear_ghost_internal()
	current_ghost_column = col
	if current_ghost_column:
		current_ghost_column.ensure_ghost()

func clear_ghost() -> void:
	_clear_ghost_internal()
	current_ghost_column = null

func _clear_ghost_internal() -> void:
	if current_ghost_column:
		current_ghost_column.remove_ghost()
		current_ghost_column = null

func _process(_delta: float) -> void:
	if dragging and not Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_LEFT):
		end_drag()
