@tool
extends DynamicTable
class_name CustomDynamicTable

# Same as jospic's DynamicTable, except:
# - instead of editing cells on double click - calls a callback, 
# - added optional mappers for displayed data

var edit_callback := func(_row_index):pass
var column_mappers : Dictionary[int,Callable] = {}

func _start_cell_editing(r: int, _col: int):
	edit_callback.call(r)

# override to show mapped text
func _draw_cell_text(cell_x: float, row_y: float, col: int, r_idx: int): # `row` rinominato a `r_idx`
	var cell_val = "" 
	if r_idx >=0 and r_idx < _data.size() and col >=0 and col < _data[r_idx].size(): # Aggiunto check limiti
		cell_val = str(_data[r_idx][col]) 
	
	# the only thing changed i added to the original code
	if column_mappers.has(col):
		cell_val = column_mappers[col].call(cell_val)
	
	var align_info = _align_text_in_cell(col)
	var h_align_val = align_info[1]
	var x_margin_val = align_info[2]
	
	var text_s = font.get_string_size(cell_val, h_align_val, _column_widths[col] - abs(x_margin_val) * 2, font_size) # Rinominato e corretto width per text
	var text_y_pos = row_y + row_height/2.0 + text_s.y/2.0 - (font_size/2.0 - 2.0) # Calcolo y per centrare meglio
	draw_string(font, Vector2(cell_x + x_margin_val, text_y_pos), cell_val, h_align_val, _column_widths[col] - abs(x_margin_val), font_size, default_font_color)

# override to set minimum size to fit mapped text, not actual content
func set_data(new_data: Array):
	# Memorizza una copia completa dei dati come master list
	_full_data = new_data.duplicate(true) 
	# La vista (_data) contiene riferimenti alle righe nella master list
	_data = _full_data.duplicate(false) 
	
	_total_rows = _data.size()
	# NOTE: idk why that was the way it was, but it stopped working for me 
	# after i refactored project/task/chat data fetching, so i changed it too
	#_visible_rows_range = [0, min(_total_rows, floor(self.size.y / row_height) if row_height > 0 else 0)]
	_visible_rows_range = [0,_total_rows]
	
	_selected_rows.clear()
	_anchor_row = -1
	_focused_row = -1
	_focused_col = -1
	
	var blank = false
	for row_data_item in _data:
		while row_data_item.size() < _total_columns:
			row_data_item.append(blank)
	
	for r in range(_total_rows):
		for col in range (_total_columns):
			var header_size = font.get_string_size(str(_get_header_text(col)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			var data_s = Vector2.ZERO
			
			if _is_progress_column(col):
				data_s = Vector2(default_minimum_column_width + 20, font_size)
			elif _is_checkbox_column(col):
				data_s = Vector2(default_minimum_column_width - 50, font_size)
			elif _is_image_column(col):
				data_s = Vector2(row_height, row_height)
			else:
				if r < _data.size() and col < _data[r].size():
					# CHANGED LINE
					data_s = font.get_string_size(str(_data[r][col]) if not column_mappers.has(col) else column_mappers[col].call(str(_data[r][col])), 
					HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			
			if (_column_widths[col] < max(header_size.x, data_s.x)):
				_column_widths[col] = max(header_size.x, data_s.x) + font_size * 4
				_min_column_widths[col] = _column_widths[col]
			
	_update_scrollbars()
	queue_redraw()

#override to filter along mapped values, not raw data
func _apply_filter(search_key: String):
	if not _filter_line_edit.visible: return
	
	_filter_line_edit.visible = false
	if _filtering_column == -1: return

	if search_key.is_empty():
		# Se la chiave è vuota, ripristina tutti i dati (rimuovi il filtro)
		_data = _full_data.duplicate(false)
		_filtering_column = -1
	else:
		var filtered_data = []
		var key_lower = search_key.to_lower()
		for row_data in _full_data:
			if _filtering_column < row_data.size() and row_data[_filtering_column] != null:
				var cell_value = str(row_data[_filtering_column]).to_lower() if \
					 not column_mappers.has(_filtering_column) else \
					column_mappers[_filtering_column].call(str(row_data[_filtering_column])).to_lower()
				if cell_value.contains(key_lower):
					filtered_data.append(row_data) # Aggiunge il riferimento
		_data = filtered_data

	# Resetta la vista
	_total_rows = _data.size()
	_v_scroll_position = 0
	_v_scroll.value = 0
	_selected_rows.clear()
	_previous_sort_selected_rows.clear()
	_focused_row = -1
	_last_column_sorted = -1 # Resetta l'ordinamento visuale
	
	_update_scrollbars()
	queue_redraw()

# override to tooltip to match mapped values... okay mapping raw->shown isnt as simple as i expected
func _update_tooltip(mouse_pos: Vector2):
	var current_cell = [-1, -1]
	var new_tooltip = ""

	if mouse_pos.y < header_height:
		var current_x = -_h_scroll_position
		for col in range(_total_columns):
			if col >= _column_widths.size(): continue
			var col_width = _column_widths[col]
			if mouse_pos.x >= current_x and mouse_pos.x < current_x + col_width:
				var header_text = _get_header_text(col)
				var _text_width = font.get_string_size(header_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				new_tooltip = header_text
				current_cell = [-2, col]
				break
			current_x += col_width
	else:
		var row = floor((mouse_pos.y - header_height) / row_height) + _visible_rows_range[0]
		if row >= 0 and row < _total_rows:
			var current_x = -_h_scroll_position
			for col in range(_total_columns):
				if col >= _column_widths.size(): continue
				var col_width = _column_widths[col]
				if mouse_pos.x >= current_x and mouse_pos.x < current_x + col_width:
					if not _is_image_column(col) and not _is_progress_column(col) and not _is_checkbox_column(col):
						# ONLY LINE CHANGED EXCEPT _text_width variable name- IDK why it doesnt show warning in source code
						var cell_text = str(get_cell_value(row, col)) if \
					 		not column_mappers.has(col) else \
							column_mappers[col].call(str(get_cell_value(row, col)))
						var _text_width = font.get_string_size(cell_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
						new_tooltip = cell_text
					current_cell = [row, col]
					break
				current_x += col_width

	if current_cell != _tooltip_cell:
		_tooltip_cell = current_cell
		self.tooltip_text = new_tooltip
