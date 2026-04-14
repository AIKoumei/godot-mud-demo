# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

- 初始化相机
   ```gdscript
   GameCore.ModManager.call_mod("CameraManager", "init_game_scene_camera", camera_node)
   ```

- 缩放相机
   ```gdscript
   GameCore.ModManager.call_mod("CameraManager", "zoom_in_camera")
   GameCore.ModManager.call_mod("CameraManager", "zoom_out_camera")
   ```

- 移动相机
   ```gdscript
   GameCore.ModManager.call_mod("CameraManager", "move_camera", Vector2.RIGHT)
   ```

## 代码注释

- 为文件适当添加注释
   - 给出配置
   - 给出输入输出的数据结构
   - 说明模块的功能
   - 给出模块的用例
   - 给出涉及模块的名称

- 在文件头给出模块的主要功能以及对应方法

- 给出功能的用例

## 模块交互

- 通过 GameCore.mod_manager.call_mod(mod_name, method_name, args) 调用其他模块的方法
- 不需要判断 Engine.has_meta(mod_name)
- 因为 GameCore.mod_manager.call_mod 已经判断了，如果模块不存在，不会调用空模块，所以不会报错。

# 模块概述

## 模块名称
CameraManager

## 模块路径
res://mods/CameraManager/Scripts/ModEntry.gd

## 模块功能
相机管理模块，管理游戏中的 Camera2D 节点，提供相机缩放、移动、跟随等功能

## 涉及模块
- ModInterface: 基础接口

# 成员变量

- camera: Camera2D
   - 相机节点

- is_camera_moved: bool
   - 相机是否已移动

- cur_physics_process_delta: float
   - 物理帧时间间隔

- cur_process_delta: float
   - 逻辑帧时间间隔

- camera_zoom: Vector2
   - 相机缩放值

- camera_zoom_step: Vector2
   - 相机缩放步长，默认 Vector2(0.1, 0.1)

- camera_zoom_min: Vector2
   - 相机最小缩放值，默认 Vector2(0.1, 0.1)

- camera_zoom_max: Vector2
   - 相机最大缩放值，默认 Vector2(3, 3)

- camera_offset: Vector2
   - 相机偏移值

- camera_move_step: Vector2
   - 相机移动步长，默认 Vector2(128, 128)

# 成员方法

- _on_mod_init() -> void
   - @return void
   - 功能说明：
      - 模块初始化时调用

- _on_mod_enable() -> void
   - @return void
   - 功能说明：
      - 模块启用时调用

- _on_mod_disable() -> void
   - @return void
   - 功能说明：
      - 模块禁用时调用
      - 清理 UI、暂停逻辑等

- _on_mod_unload() -> void
   - @return void
   - 功能说明：
      - 模块卸载时调用
      - 清理资源、断开信号、保存数据等

- _on_mod_load() -> bool
   - @return bool: 加载是否成功
   - 功能说明：
      - 模块加载时调用

- _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void
   - @param _mod_name: 发送事件的模块名
   - @param event_name: 事件名称
   - @param event_data: 事件数据
   - @return void
   - 功能说明：
      - 处理模块间通信

- _process(delta: float) -> void
   - @param delta: 帧时间间隔
   - @return void
   - 功能说明：
      - 记录逻辑帧时间

- _physics_process(delta: float) -> void
   - @param delta: 帧时间间隔
   - @return void
   - 功能说明：
      - 重置相机移动标记
      - 记录物理帧时间

- init_game_scene_camera(_camera: Camera2D) -> void
   - @param _camera: 相机节点
   - @return void
   - 功能说明：
      - 初始化游戏场景相机
      - 设置相机节点
      - 记录初始缩放和偏移

- zoom_in_camera() -> void
   - @return void
   - 功能说明：
      - 放大相机
      - 增加缩放值
      - 限制在最大缩放值内

- zoom_out_camera() -> void
   - @return void
   - 功能说明：
      - 缩小相机
      - 减少缩放值
      - 限制在最小缩放值内

- move_camera(direction: Vector2) -> void
   - @param direction: 移动方向
   - @return void
   - 功能说明：
      - 移动相机
      - 根据方向调整偏移
      - 使用插值平滑移动

- move_up_camera() -> void
   - @return void
   - 功能说明：
      - 向上移动相机

- move_down_camera() -> void
   - @return void
   - 功能说明：
      - 向下移动相机

- move_left_camera() -> void
   - @return void
   - 功能说明：
      - 向左移动相机

- move_right_camera() -> void
   - @return void
   - 功能说明：
      - 向右移动相机

- move_to_target(target: Node) -> void
   - @param target: 目标节点
   - @return void
   - 功能说明：
      - 移动相机到目标
      - TODO: 未实现

# 数据文件

- ModuleConfig.json: 模块配置文件

## 相机控制

### 缩放控制
- 步长：0.1
- 最小值：0.1
- 最大值：3.0

### 移动控制
- 步长：128 像素
- 使用插值平滑移动
- 考虑缩放比例影响
