extends Control
class_name MainMenuController

@onready var dashboard = %Dashboard
@onready var active_tab = %ActiveTab
@onready var unactive_tabs = %UnactiveTabs
@onready var summary_tab : Tab = %Summary
@onready var chat_tab : Tab = %TeamChat
@onready var no_projects_selected_tab : Tab = %NoProjectSelected

func _ready():
	
	var _on_project_opened = func():
		open_tab(summary_tab)
		dashboard.set_project_buttons_enabled(true)
	
	var _on_project_closed = func():
		dashboard.set_project_buttons_enabled(false)
		open_tab(no_projects_selected_tab)
	
	Project.project_opened.connect(_on_project_opened)
	Project.project_closed.connect(_on_project_closed)
	Project.menu_controller = self
	Notifications.start_listening()

func open_tab(tab:Tab)->void:
	if active_tab.get_child_count() ==0:
		return
	
	active_tab.get_child(0).close()
	
	active_tab.get_child(0).reparent(unactive_tabs)
	tab.reparent(active_tab)
	
	tab.open()

func is_chat_open()->bool:
	return active_tab.get_child(0) == chat_tab
