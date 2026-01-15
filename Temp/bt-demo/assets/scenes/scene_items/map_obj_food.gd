extends BaseSceneItem


class_name MapObjFood


@onready var sprite = $Sprite2D


@export var eat_times_remaining = 5	## 剩余被进食次数
@export var eat_value = 10.0 ## 每次进食获得的饱腹感
@export var born_position = Vector2.ZERO ## 出生点，创建道具后最终放置的地点
@export var expiry_time = 180 ## 保质期的剩余时间（second）

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	self.entity.born_position = born_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if expiry_time>0:
		expiry_time -= delta
	if expiry_time <= 0:
		play_food_go_bad()
	if eat_times_remaining <= 0:
		NodePoolManager.drop_to_trush(self, NodePoolManager.E_PoolObjType.MapObj_Food)
		return
	match state:
		E_StateMachine_State.Initiating:
			play_init_animation()
	#match state:
		#E_StateMachine_State.Ini


func _on_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
	if not body is BaseDigimon:return
	body = body as BaseDigimon
	var event = MapObjFoodEvent.new()
	event.entity_uid = self.entity.UID
	body.handle_map_obj_event()


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	pass # Replace with function body.


# ##############################################################################
# funcs
# ##############################################################################


func empty():
	super.empty()


func reactive():
	super.reactive()
	sprite.set_self_modulate(Color(1.0, 1.0, 1.0, 1.0))
	state_machine.send_event("ToInitiating")


func init_entity():
	super.init_entity()


func update_entity():
	super.update_entity()
	self.entity.eat_times_remaining = eat_times_remaining
	self.entity.eat_value = eat_value


func play_init_animation():
	pass


## 食物变质
func play_consume():
	pass


## 进食消耗
func consume_by(digimon: BaseDigimon):
	if eat_times_remaining <= 0: return
	eat_times_remaining -= 1
	digimon.satiety += get_eat_value()
	update_entity()
	play_consume()


## 获取饱腹感，会受到变质的影响
func get_eat_value():
	return eat_value if expiry_time > 0 else eat_value*0.5 


## 食物变质
func is_bad_food():
	return expiry_time <= 0


## 食物变质
func play_food_go_bad():
	sprite.set_self_modulate(Color(0.0, 0.0, 0.0, 0.761))


# ##############################################################################
# state machine
# ##############################################################################


@export_category("StateMachine")
enum E_StateMachine_State {
	Initiating
	,OnInitiating
	,Ready
}
@onready var state_machine = $StateMachine
@export var state = E_StateMachine_State.Initiating

func _on_initiating_state_entered() -> void:
	state = E_StateMachine_State.Initiating


func _on_on_initiating_state_entered() -> void:
	state = E_StateMachine_State.OnInitiating


func _on_ready_state_entered() -> void:
	state = E_StateMachine_State.Ready


# ##############################################################################
# END
# ##############################################################################
