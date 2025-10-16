extends Control
class_name MainMenu

@onready var active_tab = $HBoxContainer/ActiveTab
@onready var unactive_tabs = $UnactiveTabs

func open_tab(tab:Control)->void:
	if active_tab.get_child_count() ==0:
		return
		
	# assume max one active tab
	active_tab.get_child(0).reparent(unactive_tabs)
	tab.reparent(active_tab)
