extends Control
class_name MainMenuController

@onready var dashboard = %Dashboard
@onready var active_tab = %ActiveTab
@onready var unactive_tabs = %UnactiveTabs
@onready var summary_tab : Tab = %Summary

func _ready():
	
	var _on_project_opened = func():
		open_tab(summary_tab)
		dashboard.set_project_buttons_enabled(true)
		
	
	var _on_project_closed = func():
		dashboard.set_project_buttons_enabled(false)
	
	CurrentProject.project_opened.connect(_on_project_opened)
	CurrentProject.project_closed.connect(_on_project_closed)

func open_tab(tab:Tab)->void:
	if active_tab.get_child_count() ==0:
		return
	
	active_tab.get_child(0)._on_close()
	
	active_tab.get_child(0).reparent(unactive_tabs)
	tab.reparent(active_tab)
	
	tab._on_open()
