@tool
extends EditorPlugin

var DynamicTable = load("res://addons/dynamic_table/dynamic_table.gd")

func _enter_tree():
	add_custom_type("DynamicTable", "Control", DynamicTable, load("res://addons/dynamic_table/icon.svg"))

func _exit_tree():
	remove_custom_type("DynamicTable")
