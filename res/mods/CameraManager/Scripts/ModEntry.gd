## ---------------------------------------------------------
## CameraManager 模块（ModInterface 版本）
##
## 功能说明：
## - 管理游戏中的 Camera2D 节点
## - 提供相机缩放功能（zoom_in/zoom_out）
## - 支持相机方向移动（上下左右）
## - 可设置相机缩放范围和步长
## - 支持相机移动速度控制
## - 提供相机初始化和目标跟随接口
##
## 依赖：
## - ModInterface（基础接口）
##
## 调用方式（其他 Mod）：
## GameCore.mod_manager.call_mod("CameraManager", "init_game_scene_camera", camera_node)
## GameCore.mod_manager.call_mod("CameraManager", "zoom_in_camera")
## GameCore.mod_manager.call_mod("CameraManager", "move_camera", Vector2.RIGHT)
##
## ---------------------------------------------------------
extends ModInterface


## 生命周期：模块初始化
func _on_mod_init() -> void:
	super._on_mod_init()
	# 你可以在这里读取配置、初始化数据、注册事件等

## 生命周期：模块启用
func _on_mod_enable() -> void:
	super._on_mod_enable()
	# 入口场景已经实例化，可以开始逻辑

## 生命周期：模块禁用（未来支持）
func _on_mod_disable() -> void:
	super._on_mod_disable()
	# 清理 UI、暂停逻辑等

## 生命周期：模块卸载
func _on_mod_unload() -> void:
	super._on_mod_unload()
	# 清理资源、断开信号、保存数据等

## 生命周期：模块加载
func _on_mod_load() -> bool:
	var is_load_succeed = super._on_mod_load()
	# 子类实现
	return true

## 模块间通信
func _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
	super._on_mod_event(_mod_name, event_name, event_data)


# ---------------------------------------------------------
# 功能逻辑
# ---------------------------------------------------------

@export_category("camera")
@export var camera: Camera2D
@export var is_camera_moved = false
@export var cur_physics_process_delta = 0
@export var cur_process_delta = 0

func _process(delta: float) -> void:
	cur_process_delta = delta
func _physics_process(delta: float) -> void:
	is_camera_moved = false
	cur_physics_process_delta = delta

func init_game_scene_camera(_camera) -> void:
	camera = _camera
	camera_zoom = camera.get_zoom()
	camera_offset = camera.get_offset()


@export var camera_zoom: Vector2
@export var camera_zoom_step: Vector2 = Vector2(0.1,0.1)
@export var camera_zoom_min: Vector2 = Vector2(0.1,0.1)
@export var camera_zoom_max: Vector2 = Vector2(3,3)

func zoom_in_camera() -> void:
	if not camera_zoom:
		camera_zoom = camera.get_zoom()
	camera_zoom = camera_zoom + camera_zoom_step
	camera_zoom = Vector2(min(camera_zoom_max.x, camera_zoom.x), min(camera_zoom_max.y, camera_zoom.y))
	camera.set_zoom(camera_zoom)

func zoom_out_camera() -> void:
	if not camera_zoom:
		camera_zoom = camera.get_zoom()
	camera_zoom = camera_zoom - camera_zoom_step
	camera_zoom = Vector2(max(camera_zoom_min.x, camera_zoom.x), max(camera_zoom_min.y, camera_zoom.y))
	camera.set_zoom(camera_zoom)

@export var camera_offset: Vector2
@export var camera_move_step: Vector2 = Vector2(128, 128)

func move_camera(direction: Vector2) -> void:
	if is_camera_moved: return
	is_camera_moved = true
	#match direction:
		#GlobalEnv.E_Direction.UP:
			#camera.set_offset(camera_offset.lerp(Vector2(camera_offset.x, camera_offset.y - camera_move_step.y * 1/camera_zoom.x), 1.0 - exp(-cur_physics_process_delta * 10)))
		#GlobalEnv.E_Direction.DOWN:
			#camera.set_offset(camera_offset.lerp(Vector2(camera_offset.x, camera_offset.y + camera_move_step.y * 1/camera_zoom.x), 1.0 - exp(-cur_physics_process_delta * 10)))
		#GlobalEnv.E_Direction.LEFT:
			#camera.set_offset(camera_offset.lerp(Vector2(camera_offset.x - camera_move_step.x * 1/camera_zoom.x, camera_offset.y), 1.0 - exp(-cur_physics_process_delta * 10)))
		#GlobalEnv.E_Direction.RIGHT:
			#camera.set_offset(camera_offset.lerp(Vector2(camera_offset.x + camera_move_step.x * 1/camera_zoom.x, camera_offset.y), 1.0 - exp(-cur_physics_process_delta * 10)))
	camera.set_offset(camera_offset.lerp(Vector2(camera_offset.x + camera_move_step.x*1/camera_zoom.x*direction.x, camera_offset.y - camera_move_step.y*1/camera_zoom.y*direction.y), 1.0 - exp(-cur_physics_process_delta * 10)))
	camera_offset = camera.get_offset()

func move_up_camera() -> void:
	move_camera(Vector2.UP)

func move_down_camera() -> void:
	move_camera(Vector2.DOWN)

func move_left_camera() -> void:
	move_camera(Vector2.LEFT)

func move_right_camera() -> void:
	move_camera(Vector2.RIGHT)

func move_to_target(target: Node) -> void:
	pass

# ---------------------------------------------------------
# 外部访问
# ---------------------------------------------------------
