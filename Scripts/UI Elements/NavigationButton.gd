@tool
extends Button
class_name NavigationButton

@export var tab : Control
@export var menu : MainMenu

func _ready() -> void:
	if !Engine.is_editor_hint() or menu:
		return
	await get_tree().process_frame
	print(get_tree().current_scene)
	if get_tree().root.get_child(0) is MainMenu:
		menu=get_tree().root.get_child(0)

func _get_configuration_warnings() -> PackedStringArray:
	if menu: 
		return []
	return ["Could not find menu node in the scene!"]
