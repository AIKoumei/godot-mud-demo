# 基础规则

## 基础规则

1. 禁止在函数内部创建函数（包括 lambda 函数、匿名函数）
2. 禁止使用多行注释"""，"""注释内容"""，使用#注释
3. 函数注解、模块注解使用##

## 基础代码调用用例

1. 数组去重
   ```gdscript
   new_array = GameCore.ArrayTools.deduplicate(array)
   ```
2. 字典合并
   ```gdscript
   new_dict = GameCore.DictionaryTools.merge(dict_1, dict_2)
   ```
3. 时间获取
   ```gdscript
   time_string =  Time.get_datetime_string_from_system()
   ```
4. 调用其他模块
   ```gdscript
   result = GameCore.ModManager.call_mod(mod_name:String, method_name:String, ...args)
   ```

## 代码注释

1. 为文件适当添加注释
   - 给出配置
   - 给出输入输出的数据结构
   - 说明模块的功能
   - 给出模块的用例
   - 给出涉及模块的名称
2. 在文件头给出模块的主要功能以及对应方法
3. 给出功能的用例

## 模块交互

- 通过 GameCore.mod\_manager.call\_mod(mod\_name, method\_name, args) 调用其他模块的方法
- 不需要判断 Engine.has\_meta(mod\_name)
- 因为 GameCore.mod\_manager.call\_mod 已经判断了，如果模块不存在，不会调用空模块，所以不会报错。

# 文件生成规则

## 在生成 gdscript 的 md 文件的时候，有如下基础内容：

gdscript.md.template.md

## md 文件命名格式为：

- \[gdscript name].gd.README.md
- \[gdscript name].gd.dev.README.md

## md 内容

- \[gdscript name].gd.README.md
  - 内容是正常生成的 markdown 内容
- \[gdscript name].gd.dev.README.md
  - 是给开发者和 aiagent 看的内容，不需要严格按照 markdown 的风格
  - 内容严格按照该文档中"在生成 gdscript 的 md 文件的时候，有如下基础内容"部分生成，不需要 markdown 风格和额外内容
  - 除非开发者主动要求，否则不要添加额外内容

# 项目结构

...

# 模块 api

## GameCore

## ModManager

...

# 项目流程

只阐述流程，不代表代码具体名称和实现

- GameCore
  - load all mods
  - load locations
  - load entities
  - game scene
- start menu scene
  - button.new game
    - click
      to new game settings scene
- new game settings scene
  - text editor.game\_seed
  - button.start game
    - click
      - game manager.new game
      - to loading game scene
      - to game scene
- loading game scene
  - generate map
  - emit event.render map
  - emit event.render main ui
  - world map scene
- click map node
  - emit event.main ui.render target map node
- [ ] double click map node
  - [ ] move player to target map node position
    - [ ] map node passable = world map instance manager.check map node passable(
    ```json
    {
      map_instance_id: map_instance_id,
      map_position: target map node position,
    }
    ```
    )
    - [ ] if map node passable
      - [ ] play move animation
      - [ ] after move animation finished
        - [ ] world map instance manager.move player to target map node
        - [ ] world map instance manager.modify player position({
          player_entity_instance: player_entity_instance,
          map_position: target map node position,
        })
        - [ ] mud world system.check map node encounter
- new game
  - ...
- world map instance manager
  - check map node passable(args:Dictionary) -> bool
    - map_entity_instances = world map instance manager.get entities in map_position(
    ```json
    {
      map_instance_id: map_instance_id,
      map_position: map_position,
    }
    ```
    )
    - for map_entity_instance in map_entity_instances
      - for entity_instance in entity_instances_team
        - if mud world system.check passable conditions({
          entity_instance: entity_instance,
          map_entity_instance: map_entity_instance,
        })
    - return map node passable:bool
  - get entities in map_position(args:Dictionary) -> array[map_entity_instance]
    - args:
      - map_instance_id: map_instance_id
      - map_position: map_position
    - return: 
      - map_entity_instances:array[map_entity_instance]
    - function:
      - get map node in map_position
      - return map_entity_instances:array[map_entity_instance]
  - move player
    - move to neighbor map node
      - get neighbor map node by direction
      - check passable conditions
      - old_entity_instance = player_entity_instance.duplicate_deep()
      - modify player position
      - emit event.map_event.entity_move_event({
        entity_instance_id: player instance_id,
        from: old player position,
        to: neighbor map node,
        direction: direction,
        old_entity_instance: old_entity_instance,
      })
    - world map scene.recive entity\_move\_event
      play move animation
      - after move finished
        check encounter conditions
        if encounter something
        handle encounter
        get encounter config
        start battle
        game manager.start battle({
        ...
        })
        emit event.map\_event.encounter\_event({
        entity\_instance\_id: player instance\_id,
        encounter: encounter,
        ...
        })
    - move to target map node
      interaction system

# TODOLIST

- [ ] **地图数据结构**
  - [X] 地图模板（MapTemplate）使用**平铺列表**存储 map\_nodes
  - [X] 地图实例（MapInstance）在初始化时转为**XY 坐标分桶**（含 ids + dirty 标记）
  - [X] 只在加载时转换一次，运行时使用分桶快速查询
  - map instance 部分数据
    - 基础数据来源于 map manager 中的 map template，map instance 会直接拷贝一份 template，再做异化处理
    ```json
    {
      metadata:{...},
      data:{
        ...,
        map_nodes: {
          <!-- map_position -->
          "x,y": [
            <!-- map_node -->
            {
              entity_instance_id: entity_instance_id,
              entity_type: entity_type,
            },
            ...
          ],
        },
        <!-- 
          1. 在渲染 map_nodes[x,y] 并且 dirty=true 的时候，需要对 map_nodes[x,y] 中的 entity_instance 进行排序 
          2. 在 entity instance 的坐标改变后， entity instance manager 会 emit event，通知 map instance manager 进行 set map nodes dirty 标记
        -->
        map_nodes_dirty: {
          "x,y": true|false,
          ...
        },
        ...
      }
    }
    ```
  - 功能逻辑
    - 每一个 map_position 都有一个桶，桶中存储的是 entity_instance 列表，根据 render_order 排序
      - map_position 下没有 entity_instance 时，移除桶
      - 对桶添加/移除 entity instance 时，修改 map_nodes_dirty 中对应的 map_position 为 true
      - 渲染 map_position 时，如果 dirty=true，需要对桶中的 entity_instance 按 render_order 排序后，再进行渲染
    
- [ ] **实体坐标与渲染排序**
  - [ ] 实体增删/移动时：更新坐标桶，标记新旧桶为 dirty
  - [ ] 渲染阶段：只对 dirty 桶按**render\_order**排序
  - [ ] 排序后清空 dirty 标记
- [ ] **三层渲染架构**
  - [ ] 底层 Ground：地形/掉落物 → **MultiMeshInstance2D**
  - [ ] 中层 Creature：数码兽/角色/怪物 → **Sprite2D 实例**
  - [ ] 上层 Cover：树冠/屋顶/遮挡 → **MultiMeshInstance2D**
- [ ] &#x20;数码兽动画 JSON 结构
  - 设计思路
    - 支持高度压缩、不规则排布的图集
    - 支持每一帧宽高不一样（跳跃、攻击、变身、落地等动作）
    - 数据压缩：三级降级取值，不冗余
    - 取值优先级：单帧 frame\_w/h > 动作 frame\_w/h > 全局 frame\_w/h
    - 完整 JSON（体现可选性：普通动画不写局部 frame\_w/h）
    ```json
    {
      "atlas_path": "res://textures/digimon/agumon.png",
      "frame_w": 64,
      "frame_h": 64,
      "animations": {
        "idle": {
          "fps": 10,
          "loop": true,
          "frames": [
            {"x": 0, "y": 0},
            {"x": 64, "y": 0},
            {"x": 128, "y": 0}
          ]
        },
        "jump_attack": {
          "fps": 12,
          "loop": false,
          "frames": [
            {"x": 0, "y": 128, "frame_w": 64, "frame_h": 72},
            {"x": 64, "y": 128, "frame_w": 64, "frame_h": 80},
            {"x": 128,"y": 128, "frame_w": 64, "frame_h": 64}
          ]
        }
      }
    }
    ```
  - 取值规则（固定）
    - 单帧有 frame\_w / frame\_h → 优先使用
    - 单帧没有 → 使用动作的 frame\_w /frame\_h（可选，不写则跳过）
    - 动作也没有 → 使用根节点全局 frame\_w /frame\_h
    - 兼容所有帧尺寸变化动作，同时保证数据最小化
  - [ ] 动画加载逻辑
    - [ ] 读取 JSON，按三级降级规则计算每一帧 Rect2(x, y, frame\_w, frame\_h)
    - [ ] 动态创建 Animation，自动生成 region\_rect 关键帧
    - [ ] 加入 AnimationPlayer，不使用 .anim 资源文件
  - [ ] 动画状态机复用
    - [ ] 全局共用一套 AnimationTree 状态机
    - [ ] 所有数码兽共用状态结构，不重复编辑
    - [ ] 动画长度、帧率、帧数据由各自 JSON 决定
  - [ ] 动画播放控制
    - [ ] 支持播放 / 切换动画
    - [ ] 支持动态修改 speed\_scale
    - [ ] 监听 animation\_finished 信号，实现动画结束回调（攻击→待机、死亡→销毁等）
- [ ] 🎬 剧情演出系统
  - [ ] 全局剧情标识
    - [ ] GameManager.is\_cutscene\_playing: bool
    - [ ] 剧情开始设为 true，结束设为 false
  - [ ] 剧情输入拦截层（UI 顶层）
    - [ ] 结构：CanvasLayer + 全屏透明 ColorRect/Panel
    - [ ] CanvasLayer 设置较高层级（如 128），确保在所有 UI 之上
    - [ ] 控件 mouse\_filter = MOUSE\_FILTER\_STOP，拦截所有鼠标 / 触摸输入
    - [ ] 玩家输入脚本判断 is\_cutscene\_playing，跳过所有键盘 / 手柄操作
    - [ ] 剧情开始显示，剧情结束隐藏
  - [ ] 剧情角色定位
    - [ ] 给 Entity 增加固定 logic\_id（如 player、npc\_taiki）
    - [ ] 不依赖运行时动态 InstanceID
    - [ ] EntityManager.FindByLogicId(logic\_id) 查找并控制实体
    - [ ] 支持控制动态生成的 NPC 播放动画、移动、转向等

