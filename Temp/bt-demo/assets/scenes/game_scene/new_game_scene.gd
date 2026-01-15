extends Node2D


@export var page_data = [
	preload("res://assets/spirits/scenes/new_game_scene/Digimonchampionship_logo.png")
	,preload("res://assets/spirits/scenes/new_game_scene/Game_digimonchampionship_cover.jpg")
	,preload("res://assets/spirits/scenes/new_game_scene/Game_digimonworldchampionship_cover.jpg")
	,preload("res://assets/spirits/scenes/new_game_scene/640px-Victorygreymon.jpg")
	,preload("res://assets/spirits/scenes/new_game_scene/400px-Victorygreymon_new_century.png")
	
]

@onready var first_image = $UILayer/FirstImage
@onready var second_image = $UILayer/SecondImage
@onready var RollPlayerStateMachine = $RollPlayerStateMachine

enum E_RollPlayerState {
	Rolling
	,Idle
}

var roll_player_state = E_RollPlayerState.Idle


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.play_BGM(AudioManager.STATIC_RES.digimon_bgm_19)
	first_image.texture = page_data[cur_play_index]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


var cur_play_index = 0
var roll_tween
func _unhandled_input(event: InputEvent) -> void:
	if roll_player_state == E_RollPlayerState.Idle:
		if Input.is_action_just_pressed("KEY_OK"):
			next_page()
	if Input.is_action_just_pressed("KEY_MENU"):
		on_skip_button_pressed()
		#if event is InputEventMouseButton:
			#if event.is_pressed():
				#if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
					#next_page()
					#Viewport.set_input_as_handled()
		#elif event is InputEventKey:
			#if event.is_pressed()
	

func next_page():
	print("next_page", cur_play_index, page_data.size())
	cur_play_index += 1
	if cur_play_index >= page_data.size():
		on_skip_button_pressed()
		return
	second_image.texture = page_data[cur_play_index]
	roll_tween = get_tree().create_tween()
	roll_tween.tween_property(first_image, "position:y", -720, 2)
	roll_tween.parallel().tween_property(second_image, "position:y", 0, 2).from(720)
	roll_tween.finished.connect(func():
		var a = first_image
		first_image = second_image
		second_image = a
		second_image.position.y = 720
		RollPlayerStateMachine.send_event("ToIdle")
	)
	roll_tween.play()
	RollPlayerStateMachine.send_event("ToRolling")


func _on_idle_state_entered() -> void:
	self.roll_player_state = E_RollPlayerState.Idle


func _on_rolling_state_entered() -> void:
	self.roll_player_state = E_RollPlayerState.Rolling


func _on_skip_button_pressed() -> void:
	on_skip_button_pressed()


func on_skip_button_pressed():
	var event = GameStartEvent.new()
	event.game_start_type = GameStartEvent.E_GameStartType.NewGame
	GameManager.SetGameStartEvent(event)
	SceneManager.to_game_scene("AutoGameSceneAfterLoadGameScene")
