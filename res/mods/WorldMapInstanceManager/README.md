# WorldMapInstanceManager 模块说明

## 功能概述

WorldMapInstanceManager 模块负责管理世界地图的运行时实例，主要功能包括：

- 管理多个 location 的运行时实例（map_data + state）
- 从 WorldMapManager 复制静态地图数据，生成可修改的实例
- 负责地图玩法层的运行时数据（破坏、建造、掉落、单位位置等）
- 维护实体在地图上的位置信息
- 提供地图实例的 CRUD 操作接口

## Map Instance 数据结构

### 核心数据结构

Map Instance 存储在 `_mud_map_instances` 字典中，键为 `location_id` 或 `map_instance_id`，值为包含以下字段的字典：

```gdscript
{
	"metadata": {
		"generated_at": "2026-02-08T21:20:17",
		"grid_bounds": {
			"max_x": 23,
			"max_y": 24,
			"min_x": 3,
			"min_y": 3
		},
		"map_id": "naked_beach_(まるだしビーチ_marudashi_bīchi)",
		"map_name": "Naked Beach (まるだしビーチ Marudashi Bīchi)",
		"version": "1.1"
	},
	"data": {
		"blocks": {                         # 区块数据
			"block_0": {
				"building_name": "联盟大厅",
				"building_type": "union_room",
				"h": 5,                      # 高度
				"w": 5                       # 宽度
				"nodes": {
					"10,10": true,           # 建筑占据的节点
				},
				"pos": {
					"x": 7,                   # 建筑起始位置
					"y": 8
				},
			}
			# 更多区块...
		},
		"path_connection_indexer": {         # 路径连接索引
			"10,27": 5,                      # 位置 -> 连接类型
			# 更多连接...
		},
		"rooms": {                           # 房间数据
			"10,10": {
				"attributes": {
					"color": "69e779ff",
					"parent_block_id": "block_0"
				},
				"description": "这是一个 联盟大厅。",
				"entities": {},
				"exits": {
					"east": "11,10",
					"north": "10,9",
					"south": "10,11",
					"west": "9,10"
				},
				"title": "未命名区域",
				"type": "union_room"
			}
			# 更多房间...
		}
	},
}
```

### 辅助数据结构

#  **实体位置信息** (`_entity_positions`)

   ```gdscript
   {
	   "map_instance_id": {
		   "x_y": {
			   "entity_instance_id": {}
		   }
	   }
   }
   ```

#  **地图实体索引表** (`_entity_by_map`)

   ```gdscript
   {
	   "map_instance_id": {
		   "entity_instance_id": {}
	   }
   }
   ```

#  **实体地图索引表** (`_map_by_entity`)

   ```gdscript
   {
	   "entity_instance_id": "map_instance_id"
   }
   ```

## 主要接口方法

### 1. 获取地图实例

```gdscript
# 获取指定位置的地图实例
func get_instance(location_id: String) -> Dictionary

# 获取当前地图实例
func get_current_instance() -> Dictionary

# 获取所有地图实例
func get_all_mud_map_instances() -> Dictionary
```

### 2. 实体管理

```gdscript
# 根据地图实例 ID 获取所有实体实例 ID
func get_entities_by_map(map_instance_id: String) -> Array

# 设置实体位置
func set_entity_position(entity_instance_id: String, cfg: Dictionary) -> void

# 根据配置创建实体
func create_entity(cfg: Dictionary) -> Dictionary
```

### 3. 地图数据修改

```gdscript
# 合并格子数据（用于破坏、建造、掉落等）
func merge_tile_data(location_id: String, x: int, y: int, data: Dictionary) -> void
```

### 4. 地图生成与初始化

```gdscript
# 生成所有位置的地图实例
func gen_all_locations()

# 初始化地图实体
func init_mud_map_entities()
```

### 5. 地图保存

```gdscript
# 保存所有地图实例数据
func save_all_location_instances()
```

## 工作流程

#  **地图生成**：WorldMapManager 生成地图模板
#  **实例创建**：WorldMapInstanceManager 接收地图模板并创建可修改的实例
#  **实体初始化**：WorldMapInstanceManager 初始化地图中的实体
#  **运行时管理**：维护地图状态和实体位置
5. **数据持久化**：保存地图实例数据到文件

## 事件处理

### 监听的事件

- `WorldMapManager.after_gen_all_location_map_finished`：地图生成完成
- `EntityInstanceManager.entity_created`：实体创建
- `EntityInstanceManager.entity_destroyed`：实体销毁
- `SceneManager.SaveAllMapInstanceData`：保存地图数据

### 发送的事件

- `init_one_mud_map_entities`：单个地图实体初始化完成
- `after_gen_all_locations_finished`：所有地图生成和初始化完成

## 示例用法

### 创建地图实例

```gdscript
# 生成所有地图实例
GameCore.mod_manager.call_mod("WorldMapInstanceManager", "gen_all_locations")

# 获取指定地图实例
var map_instance = GameCore.mod_manager.call_mod("WorldMapInstanceManager", "get_instance", "file_island")
```

### 管理实体位置

```gdscript
# 设置实体位置
GameCore.mod_manager.call_mod("WorldMapInstanceManager", "set_entity_position", "player_001", {
	"map_instance_id": "file_island",
	"map_position": Vector2i(10, 10)
})

# 获取地图上的所有实体
var entities = GameCore.mod_manager.call_mod("WorldMapInstanceManager", "get_entities_by_map", "file_island")
```

### 修改地图数据

```gdscript
# 破坏一个格子
GameCore.mod_manager.call_mod("WorldMapInstanceManager", "merge_tile_data", "file_island", 5, 5, {
	"breakable": false,
	"drop": { "item": "wood", "amount": 1 }
})
```

## 注意事项

#  **数据结构兼容性**：地图实例数据结构可能会随着版本更新而变化，请确保使用最新的接口方法。

#  **性能考虑**：对于大型地图，实体数量可能会很多，使用时应注意性能优化。

#  **数据持久化**：地图实例数据会在 `save_all_location_instances` 调用时保存，建议在适当的时机调用此方法。

#  **实体管理**：实体的创建和销毁会自动更新地图索引表，无需手动维护。

5. **坐标系统**：地图使用二维网格坐标系统，单位为格子。

## 版本历史

- **v1.0.0**：初始版本，实现基本的地图实例管理功能
- **v1.1.0**：添加实体位置管理和索引功能
- **v1.2.0**：优化地图数据结构，支持区块和房间层次结构
- **v1.3.0**：添加路径连接索引，支持更复杂的地图导航
- **v1.4.0**：更新地图数据结构，优化建筑表示和房间属性
