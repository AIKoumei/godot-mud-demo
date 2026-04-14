# mod.MudEntityInteractionSystem.Scripts.Core.MudEntityAction.gd 分析文档

## 基础规则

### 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

### 基础代码调用用例

- 数组去重
   ```gdscript
   new_array = GameCore.ArrayTools.deduplicate(array)
   ```

- 字典合并
   ```gdscript
   new_dict = GameCore.DictionaryTools.merge(dict_1, dict_2)
   ```

- 时间获取
   ```gdscript
   time_string =  Time.get_datetime_string_from_system()
   ```

- 调用其他模块
   ```gdscript
   result = GameCore.ModManager.call_mod(mod_name:String, method_name:String, ...args)
   ```

### 代码注释

- 为文件适当添加注释
   - 给出配置
   - 给出输入输出的数据结构
   - 说明模块的功能
   - 给出模块的用例
   - 给出涉及模块的名称

- 在文件头给出模块的主要功能以及对应方法

- 给出功能的用例

### 模块交互

- 通过 GameCore.mod_manager.call_mod(mod_name, method_name, args) 调用其他模块的方法
- 不需要判断 Engine.has_meta(mod_name)
- 因为 GameCore.mod_manager.call_mod 已经判断了，如果模块不存在，不会调用空模块，所以不会报错。

# 模块概述

## 模块名称
MudEntityAction

## 模块路径
res/mods/MudEntityInteractionSystem/Scripts/Core/MudEntityAction.gd

## 模块功能
实体动作基类，定义了实体间交互动作的标准接口。主要职责包括:
1. 定义动作的唯一标识符 (action_id)
2. 定义 UI 显示名称 (action_label)
3. 提供动作可行性判定接口 (can_perform)
4. 提供动作执行接口 (execute)
5. 作为所有具体动作的父类

## 模块依赖
- 无外部依赖

## 数据结构

### 动作数据结构
```gdscript
{
  "action_id": "action_unique_id",
  "action_label": "UI 显示名称"
}
```

### 实体数据结构
```gdscript
{
  "data": {
    "name": "实体名称"
  },
  "attributes": {...},
  "entity_type": "entity_type"
}
```

### 执行结果数据结构
```gdscript
{
  "status": "success|failure",
  "msg": "动作执行结果描述"
}
```

## 模块用例

```gdscript
# 示例 1：创建自定义动作类
class_name AttackAction extends MudEntityAction

func _init():
    action_id = "attack"
    action_label = "攻击"

func can_perform(source: Dictionary, target: Dictionary) -> bool:
    # 检查源实体是否有攻击能力
    var source_attributes = source.get("attributes", {})
    return source_attributes.get("can_attack", false)

func execute(source: Dictionary, target: Dictionary) -> Dictionary:
    # 计算伤害
    var damage = source.get("attributes", {}).get("attack", 10)
    # 对目标造成伤害
    target.get("attributes", {}).set("hp", target.get("attributes", {}).get("hp", 100) - damage)
    return {
        "status": "success",
        "msg": "%s 对 %s 造成了 %d 点伤害" % [source.data.name, target.data.name, damage]
    }

# 示例 2：创建治疗动作
class_name HealAction extends MudEntityAction

func _init():
    action_id = "heal"
    action_label = "治疗"

func can_perform(source: Dictionary, target: Dictionary) -> bool:
    # 检查源实体是否有治疗能力
    var source_attributes = source.get("attributes", {})
    return source_attributes.get("can_heal", false)

func execute(source: Dictionary, target: Dictionary) -> Dictionary:
    # 治疗目标
    var heal_amount = source.get("attributes", {}).get("heal_power", 20)
    target.get("attributes", {}).set("hp", min(100, target.get("attributes", {}).get("hp", 100) + heal_amount))
    return {
        "status": "success",
        "msg": "%s 为 %s 恢复了 %d 点生命值" % [source.data.name, target.data.name, heal_amount]
    }

# 示例 3：使用动作
var attack = AttackAction.new()
if attack.can_perform(player_entity, enemy_entity):
    var result = attack.execute(player_entity, enemy_entity)
    print(result.msg)

# 示例 4：检查动作可行性
var action = MudEntityAction.new()
action.action_id = "test_action"
action.action_label = "测试动作"
var can_perform = action.can_perform(entity1, entity2)
if can_perform:
    var result = action.execute(entity1, entity2)
    print(result.status)  # 输出：success
```

# 成员变量

- var action_id: String
  - 动作的唯一标识符
  - 用于区分不同的动作类型
  - 例如："attack", "heal", "talk", "trade"

- var action_label: String
  - UI 中显示的动作名称
  - 用于在菜单、按钮等 UI 元素中显示
  - 例如："攻击", "治疗", "对话", "交易"

# 成员方法

## 判定方法

- can_perform(_source: Dictionary, _target: Dictionary) -> bool
  - @args:
    - _source: 源实体数据字典
    - _target: 目标实体数据字典
  - @return bool: 是否可以执行该动作
  - functions:
    - 默认实现：始终返回 true
    - 子类应重写此方法实现具体的判定逻辑
    - 判定条件可能包括:
      - 实体类型是否匹配
      - 实体状态是否允许
      - 距离是否足够
      - 冷却时间是否结束
      - 资源是否充足

## 执行方法

- execute(source: Dictionary, target: Dictionary) -> Dictionary
  - @args:
    - source: 源实体数据字典
    - target: 目标实体数据字典
  - @return Dictionary: 执行结果，包含 status 和 msg
  - functions:
    - 默认实现：返回成功消息
    - 子类应重写此方法实现具体的执行逻辑
    - 执行内容可能包括:
      - 修改实体属性 (HP, MP, 状态等)
      - 触发动画效果
      - 播放音效
      - 发送事件通知
      - 记录日志

# 数据文件

- 无直接依赖的数据文件

# 模块交互

## 调用的其他模块
- 无

## 被其他模块调用
- MudEntityInteractionSystem: 调用 can_perform() 和 execute()

## 发送的事件
- 无

# 核心流程

## 动作执行流程
```
1. 创建动作实例
   - var action = CustomAction.new()
   - 设置 action_id 和 action_label

2. 判定是否可执行
   - if action.can_perform(source, target):
     - 检查源实体和目标实体的状态
     - 检查距离、冷却、资源等条件

3. 执行动作
   - var result = action.execute(source, target)
   - 执行具体逻辑
   - 返回结果字典

4. 处理结果
   - if result.status == "success":
     - 显示成功消息
     - 播放动画/音效
   - else:
     - 显示失败消息
     - 处理失败逻辑
```

## 子类实现流程
```
1. 继承 MudEntityAction
   - class_name CustomAction extends MudEntityAction

2. 初始化 action_id 和 action_label
   - func _init():
       action_id = "custom"
       action_label = "自定义动作"

3. 重写 can_perform() 方法
   - func can_perform(source, target) -> bool:
       # 实现判定逻辑
       return true/false

4. 重写 execute() 方法
   - func execute(source, target) -> Dictionary:
       # 实现执行逻辑
       return {"status": "success", "msg": "..."}
```

# 架构设计

## 策略模式
- MudEntityAction 作为策略接口
- 每个具体动作是一个独立的策略
- 可以在运行时切换不同的动作

## 开闭原则
- 对扩展开放：可以轻松添加新的动作类型
- 对修改关闭：不需要修改现有代码

## 数据结构设计

### 实体数据字典
```gdscript
{
  "data": {
    "name": "实体名称"
  },
  "attributes": {
    "hp": 100,
    "mp": 50,
    "attack": 10,
    "defense": 5
  },
  "entity_type": "human",
  "instance_id": "entity_001"
}
```

### 执行结果字典
```gdscript
{
  "status": "success",  # 或 "failure"
  "msg": "动作执行成功",
  "data": {  # 可选的额外数据
    "damage": 10,
    "critical": true
  }
}
```

## 扩展性设计

### 动作类型
- 攻击类动作：AttackAction, MagicAction
- 辅助类动作：HealAction, BuffAction
- 交互类动作：TalkAction, TradeAction
- 移动类动作：MoveAction, TeleportAction

### 判定条件
- 实体类型检查
- 距离检查
- 状态检查 (眩晕、沉默等)
- 资源检查 (MP, 物品等)
- 冷却检查

### 执行效果
- 属性修改
- 状态施加
- 动画播放
- 音效播放
- 事件触发

# 使用场景

## 1. 战斗系统
- 物理攻击
- 魔法攻击
- 防御
- 逃跑

## 2. 交互系统
- 对话
- 交易
- 组队
- 交易

## 3. 技能系统
- 主动技能
- 被动技能
- 终极技能

## 4. 任务系统
- 接受任务
- 完成任务
- 放弃任务

# TODO

- [ ] 添加动作冷却机制
  - [ ] cooldown_time 属性
  - [ ] is_on_cooldown() 方法

- [ ] 添加动作消耗机制
  - [ ] cost 属性 (MP, HP, 物品等)
  - [ ] can_afford() 方法

- [ ] 添加动作范围机制
  - [ ] range 属性
  - [ ] check_range() 方法

- [ ] 添加动作优先级机制
  - [ ] priority 属性
  - [ ] 用于 AI 决策

- [ ] 添加动作动画和音效
  - [ ] animation_path 属性
  - [ ] sound_path 属性
  - [ ] play_effects() 方法

- [ ] 添加动作日志系统
  - [ ] 记录动作历史
  - [ ] 支持回放和调试
