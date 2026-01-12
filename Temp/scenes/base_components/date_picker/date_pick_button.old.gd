extends Button


class_name DatePickButton

@onready var DatePicker = $Buttom/DatePicker
signal on_date_pick(datetime: Dictionary)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_date_picker_position()
	DatePicker.connect("on_date_pick", _on_date_pick)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func update_date_picker_position() -> void:
	var viewport_rect = get_viewport_rect()
	print(viewport_rect)
	# 获取你想要检查的对象的全局位置和尺寸
	var object_position = global_position
	var object_size = get_rect().size  # 例如，使用get_rect()获取2D对象的大小
	
	# 检查对象是否在视口内
	if Rect2(object_position, object_size).intersects(viewport_rect):
		print("对象在屏幕内")
	else:
		print("对象不在屏幕内")


func _on_date_pick(datetime: Dictionary) -> void:
	emit_signal("on_date_pick", datetime)


func _on_pressed() -> void:
	DatePicker.visible = true
	
