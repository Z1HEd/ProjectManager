extends Control
class_name MainMenuController

@onready var active_tab = $HBoxContainer/TabArea/ActiveTab
@onready var unactive_tabs = $HBoxContainer/TabArea/UnactiveTabs

func open_tab(tab:Tab)->void:
	if active_tab.get_child_count() ==0:
		return
	
	active_tab.get_child(0)._on_close()
	
	active_tab.get_child(0).reparent(unactive_tabs)
	tab.reparent(active_tab)
	
	tab._on_open()
