# godot-mud-demo
基于 Godot 引擎的 MUD (多用户地牢) 演示项目，具有模块化架构和可扩展系统。

## 项目架构

### 核心组件

```
godot-mud-demo/
├── res/                     # 资源目录
│   ├── core/                # 核心系统文件
│   │   ├── Config/          # 配置文件
│   │   ├── Data/            # 核心数据文件
│   │   ├── Scenes/          # 核心场景
│   │   └── Scripts/         # 核心脚本
│   │       ├── Common/      # 通用工具
│   │       ├── Debug/       # 调试工具
│   │       ├── ModManager/  # Mod 管理系统
│   │       └── GameCore.gd  # 游戏核心
│   └── mods/                # 模块化扩展
│       ├── DefaultUnits/    # 默认游戏单位
│       ├── GameManager/     # 游戏状态管理
│       ├── PopupMessage/    # 消息弹窗系统
│       ├── SceneManager/    # 场景管理
│       ├── UnitManager/     # 单位管理
│       ├── WorldMapGenerator/ # 世界地图生成
│       └── mod_template/    # Mod 创建模板
├── Tools/                   # 开发工具
├── addons/                  # Godot 插件
└── project.godot            # 项目配置
```

### 完整项目目录结构

```
godot-mud-demo/
├── AI工作需求/               # AI 工作需求文档
│   └── v.0.1.0.md          # 版本 0.1.0 的工作需求
├── Tools/                    # 开发工具
│   └── get_current_time.py   # 获取当前时间的脚本
├── addons/                   # Godot 插件
│   ├── GD-Sync/              # 同步插件
│   ├── font/                 # 字体插件
│   ├── godot_state_charts/   # 状态图插件
│   ├── godot_ui_animations/  # UI 动画插件
│   ├── limboai/              # AI 插件
│   ├── liquidsimulator/       # 液体模拟器插件
│   ├── spirits/              # 精灵和 UI 资源
│   ├── tnowe_extra_controls/ # 额外控件插件
│   ├── windows_95_theme/     # Windows 95 主题插件
│   └── worldmap_builder/     # 世界地图构建器插件
├── examples/                 # 示例文件
│   ├── 0_default/            # 默认示例
│   └── 各种示例场景和脚本
├── res/                      # 资源目录
│   ├── core/                 # 核心系统文件
│   │   ├── Config/           # 配置文件
│   │   ├── Data/             # 核心数据文件
│   │   ├── Scenes/           # 核心场景
│   │   └── Scripts/          # 核心脚本
│   │       ├── Common/       # 通用工具
│   │       ├── Debug/        # 调试工具
│   │       ├── ModManager/   # Mod 管理系统
│   │       ├── SaveManager/  # 存档管理系统
│   │       ├── Settings/     # 设置系统
│   │       └── GameCore.gd   # 游戏核心
│   └── mods/                 # 模块化扩展
│       ├── DefaultLocations/ # 默认地点数据
│       ├── DefaultUnits/     # 默认游戏单位
│       ├── GameManager/      # 游戏状态管理
│       ├── PopupMessage/     # 消息弹窗系统
│       ├── SceneManager/     # 场景管理
│       ├── UnitManager/      # 单位管理
│       ├── WorldMapGenerator/ # 世界地图生成
│       ├── WorldMapInstanceManager/ # 世界地图实例管理
│       ├── WorldSceneManager/ # 世界场景管理
│       └── mod_template/     # Mod 创建模板
│           ├── Config/        # 模板配置文件
│           │   └── ModuleConfig.json # 模块配置文件
│           ├── Data/          # 模板数据文件
│           └── Scripts/       # 模板脚本
│               └── ModEntry.gd # 模块入口脚本
├── .gitattributes            # Git 属性文件
├── .gitignore                # Git 忽略文件
├── LICENSE                   # 许可证文件
├── README.md                 # 项目说明文件
├── change_log.md             # 变更日志
├── git.push.bat              # Git 推送脚本
├── icon.svg                  # 项目图标
├── icon.svg.import           # 图标导入配置
├── project.godot             # 项目配置文件
└── 项目目录结构.md            # 项目目录结构文档
```

#### 目录说明

- **AI工作需求/**: 存储 AI 开发的工作需求文档，按版本号组织
- **Tools/**: 开发工具和脚本，用于辅助项目开发
- **addons/**: Godot 插件，提供各种额外功能和工具
- **examples/**: 示例文件和场景，用于演示各种功能
- **res/**: 核心资源目录，包含游戏的主要内容
  - **core/**: 核心系统文件，包含游戏的基础框架
  - **mods/**: 模块化扩展，包含各种功能模块
    - **mod_template/**: Mod 创建模板，用于快速创建新的功能模块
- **根目录文件**: 项目配置和文档文件

#### 核心模块说明

- **GameCore**: 游戏核心，负责初始化和协调各个系统
- **ModManager**: 模块管理器，负责加载和管理各种功能模块
- **SceneManager**: 场景管理器，负责场景的加载和切换
- **UnitManager**: 单位管理器，负责游戏单位的创建和管理
- **WorldMapGenerator**: 世界地图生成器，负责生成游戏世界地图
- **WorldMapInstanceManager**: 世界地图实例管理器，负责管理地图实例和相关功能
- **WorldSceneManager**: 世界场景管理器，负责场景的渲染和更新
- **DefaultLocations**: 默认地点数据，提供游戏的初始地点信息
- **DefaultUnits**: 默认单位数据，提供游戏的初始单位信息
- **GameManager**: 游戏管理器，负责游戏状态的管理
- **PopupMessage**: 弹窗消息系统，负责显示各种消息提示


## 系统工作流程

### 1. 游戏初始化
#  **GameCore.gd** 初始化核心系统
#  **ModManager** 加载所有启用的 mods
#  **SceneManager** 准备初始场景

### 2. Mod 加载流程
```
GameCore.gd → ModManager.gd → [ModEntry.gd 文件] → ModuleConfig.json
```

#  **GameCore** 触发 mod 加载
#  **ModManager** 扫描 mod 目录
#  每个 mod 的 **ModEntry.gd** 文件被执行
#  **ModuleConfig.json** 定义 mod 元数据和依赖关系

### 3. 位置管理系统
LocationManager 模块使用基于关系的层级结构处理游戏世界位置：

```
Locations.json → LocationManager → Relationships → 位置树
```

#  **Locations.json** 包含位置数据和关系
#  **LocationManager** 加载并处理位置数据
#  **Relationships** 定义父子连接
#  **位置树** 用于导航和显示

### 4. 场景管理
```
SceneManager → GameScenes → UIScenes → 场景过渡
```

#  **SceneManager** 管理场景加载/卸载
#  **GameScenes** 包含游戏环境
#  **UIScenes** 处理用户界面元素
#  **场景过渡** 提供平滑的场景切换

### 5. 单位管理
```
UnitManager → DefaultUnits → Units.json → 单位实例
```

#  **UnitManager** 处理单位创建和管理
#  **DefaultUnits** 提供基础单位定义
#  **Units.json** 包含单位数据
#  **单位实例** 在游戏中创建

## 关键特性

### 模块化架构
- **可扩展的 Mod 系统**：无需修改核心代码即可添加新功能
- **依赖管理**：Mod 可以依赖其他 Mod
- **数据驱动设计**：配置文件控制游戏行为

### 位置系统
- **基于关系的层级结构**：通过关系连接位置
- **JSON 数据结构**：易于编辑和扩展位置数据
- **多种查询方法**：通过 ID、类型或关系搜索位置

### 开发工具
- **Python 脚本**：Tools 目录中的实用脚本
- **调试工具**：内置调试功能
- **插件支持**：集成各种 Godot 插件

## 可用工具
- `Tools/get_current_time.py` - 获取当前系统时间的实用脚本，格式为 yyyy-MM-dd HH:mm:ss

## 使用指南

### 运行项目
#  在 Godot 引擎中打开项目
#  运行主场景 (`res/core/Scenes/GameScenes/main.tscn`)
#  游戏将初始化并加载所有启用的 mods

### 创建新 Mod
#  复制 `mod_template` 目录
#  将其重命名为你的 mod 名称
#  编辑 `ModuleConfig.json` 填写你的 mod 详情
#  在 `ModEntry.gd` 中实现你的 mod 逻辑
5. 添加任何额外的资源或数据文件

### 位置管理
#  向 `Data/Locations.json` 添加新位置
#  在 `relationships` 部分定义关系
#  在代码中使用 LocationManager API 访问位置：
   - `get_location(id)` - 通过 ID 获取位置
   - `get_location_children(id)` - 获取子位置
   - `add_relationship(parent_id, child_id)` - 添加新关系

## 项目状态
- **核心系统**：已实现
- **Mod 系统**：已实现
- **位置系统**：已实现，使用基于关系的层级结构
- **场景系统**：已实现
- **单位系统**：已实现
- **世界生成**：开发中

## 未来计划
- 增强世界地图生成
- 添加更多 mod 模板
- 实现多人游戏支持
- 扩展基于位置的任务和事件

## 贡献
欢迎 fork 项目并提交 pull requests 来添加新功能或修复 bug。

## 许可证
详见 LICENSE 文件。

## TODO 列表

### 核心系统
- **SaveManager**
  - 未来拓展功能

- **ModManager**
  - 通过 GameCore/GameSceneLayerManager 来控制挂载 mod 节点的位置
  - 实现更完整的热禁用逻辑

### 世界场景管理
- **WorldSceneManager**
  - 摄像机跟随、单位动画更新等

- **WorldMapInstanceManager**
  - 天气变化、单位 AI、掉落物刷新等

### UI 系统
- **CyclableContainer**
  - 实现多行多列的布局
  - 计算当前项目在网格中的位置，考虑间距
  - 确保项目大小不会小于其 custom_minimum_size
  - 排序方向优化

- **WindowManager**
  - 实现关闭所有窗口的功能
  - 实现窗口排序逻辑

- **TaskPanel**
  - 实现每帧更新处理逻辑
  - 实现根据搜索文本过滤任务列表的逻辑
  - 实现筛选对话框，允许用户选择筛选条件
  - 实现任务编辑逻辑，打开编辑界面并传入任务数据
  - 实现任务删除逻辑，包括确认对话框和数据删除

- **TaskEditPanel**
  - 实现保存任务数据的逻辑
  - 实现加载任务数据到表单的逻辑
  - 实现任务数据验证逻辑
  - 实现表单重置逻辑

- **MealPanel**
  - 实现 UI 初始化逻辑
  - 实现点餐数据刷新功能
  - 实现菜品添加到订单功能
  - 实现从订单移除菜品功能
  - 实现订单总价计算功能
  - 实现订单提交功能

- **RecipePanel**
  - 实现 UI 初始化逻辑
  - 实现菜谱列表刷新功能
  - 实现菜谱项 UI 创建功能
  - 实现菜谱搜索功能
  - 实现添加菜谱功能
  - 实现菜谱详情查看功能
  - 实现菜谱编辑功能
  - 实现菜谱删除功能

- **ProfilePanel**
  - 实现 UI 初始化逻辑
  - 实现用户数据加载功能
  - 实现用户信息更新功能
  - 实现密码修改功能
  - 实现设置保存功能
  - 实现关于信息显示功能
  - 实现退出登录功能

- **InventoryPanel**
  - 实现 UI 初始化逻辑
  - 实现库存列表刷新功能
  - 实现库存项 UI 创建功能
  - 实现添加食材功能
  - 实现库存预警显示功能
  - 实现食材数量更新功能
  - 实现食材移除功能

- **IngredientItem**
  - _refresh_inventory_list 方法在 main_ui.gd 中未实现

### 插件
- **WorldMapBuilder**
  - 仅在视图实际更改时更新
  - 使 180 度快照一致
  - 为绝对弧度设置器提供安全弧度

- **DiceRoller**
  - 各种优化和改进
