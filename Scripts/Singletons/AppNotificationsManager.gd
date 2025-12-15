extends Node

@export var notification_scene: PackedScene = preload("res://scenes/UIElements/AppNotification.tscn")
var _layer: CanvasLayer = null
var _container: VBoxContainer = null
var _spacing := 8
var _max_stack := 6

func _ensure_root() -> void:
	if _layer != null:
		return
	_layer = CanvasLayer.new()
	get_tree().get_root().add_child(_layer)

	_container = VBoxContainer.new()
	_layer.add_child(_container)

	_container.set_anchors_and_offsets_preset(
		Control.LayoutPreset.PRESET_BOTTOM_RIGHT,
		Control.LayoutPresetMode.PRESET_MODE_KEEP_WIDTH,
		16
	)
	_container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_container.grow_vertical = Control.GROW_DIRECTION_BEGIN
	# set vertical gap between children
	_container.add_theme_constant_override("separation", _spacing)


func push(message: String) -> void:
	_ensure_root()
	
	if _container.get_child_count() >= _max_stack:
		_container.get_child(0).queue_free()

	var _notification : AppNotificationControl = notification_scene.instantiate()
	_container.add_child(_notification)
	
	_notification.call_deferred("start",message)
