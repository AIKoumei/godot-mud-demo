
extends MarginContainer
class_name BaseContainerItem

@export var data_index: int = -1
@export var item_data: Dictionary

signal on_item_confirm()
signal on_item_cancel(index, data, item)
signal on_item_select(index, data, item)
signal on_item_data_changed(index, data, item)

@export var node_selected = null
@export var node_normal = null

func set_data_index(_data_index: int) -> void:
	data_index = _data_index

func set_data(_data_index: int, data: Dictionary) -> void:
	data_index = _data_index
	item_data = data
	on_item_data_changed.emit(data_index, item_data, self)

func cancel():
	if node_selected:
		node_selected.visible = false
	on_item_cancel.emit(data_index, item_data, self)
	
func select():
	if node_selected:
		node_selected.visible = true
	on_item_select.emit(data_index, item_data, self)
	
