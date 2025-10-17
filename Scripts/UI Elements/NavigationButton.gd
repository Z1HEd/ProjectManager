@tool
extends Button
class_name NavigationButton

@export var tab : Control : set = set_tab
@export var menu : MainMenu : set=set_menu

func _ready() -> void:
	if !Engine.is_editor_hint() or menu:
		return
	if get_tree().edited_scene_root is MainMenu:
		menu=get_tree().edited_scene_root

func _pressed() -> void:
	if not tab:
		return
	menu.open_tab(tab)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	if not menu: 
		warnings.append("Could not find menu node in the scene!")
	if not tab:
		warnings.append("No tab set to navigate!")
	return warnings

func set_tab(control)->void:
	tab=control
	update_configuration_warnings()

func set_menu(control)->void:
	menu=control
	update_configuration_warnings()
