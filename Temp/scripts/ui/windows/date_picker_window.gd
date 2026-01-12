extends BaseWindow

class_name DatePickerWindow

signal on_date_pick(datetime: Dictionary)
signal on_confirm(datetime: Dictionary)
signal on_cancel()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	$WindowContent/VBoxContainer/MainContent/DatePicker.connect("on_date_pick", _on_date_pick)

func on_opened() -> void:
	super.on_opened()
	var date = Time.get_datetime_dict_from_system()
	$WindowContent/VBoxContainer/MainContent/DatePicker.set_datetime(date.year, date.month, date.day, date.hour, date.minute, date.second)

func on_closed() -> void:
	super.on_closed()

func connect_all_private_signals() -> void:
	super.connect_all_private_signals()
	$WindowContent/VBoxContainer/ButtomContent.connect("on_confirm", _on_confirm_button_pressed)
	$WindowContent/VBoxContainer/ButtomContent.connect("on_cancel", _on_cancel_button_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_date_picker_on_date_pick(datetime: Dictionary) -> void:
	_on_date_pick(datetime)

func _on_date_pick(datetime: Dictionary) -> void:
	emit_signal("on_date_pick", datetime)

func _on_cancel_button_pressed() -> void:
	close()


func _on_confirm_button_pressed() -> void:
	emit_signal("on_confirm", $WindowContent/VBoxContainer/MainContent/DatePicker.get_date_dict())
	close()
