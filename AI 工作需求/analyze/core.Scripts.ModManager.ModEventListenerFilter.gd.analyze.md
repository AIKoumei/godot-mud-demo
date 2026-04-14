# core.Scripts.ModManager.ModEventListenerFilter.gd 分析文档

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
ModEventListenerFilter

## 模块路径
res/core/Scripts/ModManager/ModEventListenerFilter.gd

## 模块功能
模块事件监听过滤器，用于精确控制模块间的事件监听。支持按模块名称、事件名称和监听类型进行过滤。主要职责包括:
1. 定义模块过滤类型 (ANY/TARGET)
2. 定义事件过滤类型 (ANY/TARGET)
3. 定义监听类型 (ALWAYS/ONCE)
4. 提供链式配置接口
5. 实现匹配逻辑

## 模块依赖
- 无外部依赖

## 枚举定义

### ModFilterType (模块过滤类型)
```gdscript
{
  "ANY": "ANY",       # 监听所有模块
  "TARGET": "TARGET"  # 只监听指定模块
}
```

### EventFilterType (事件过滤类型)
```gdscript
{
  "ANY": "ANY",       # 监听所有事件
  "TARGET": "TARGET"  # 只监听指定事件
}
```

### ListenType (监听类型)
```gdscript
{
  "ALWAYS": "ALWAYS",  # 始终监听
  "ONCE": "ONCE"       # 只监听一次
}
```

## 数据结构

### 过滤器配置
```gdscript
{
  "mod_filter_type": "TARGET",  # 模块过滤类型
  "mod_name": "MyMod",          # 目标模块名称
  "event_filter_type": "TARGET",# 事件过滤类型
  "event_name": "my_event",     # 目标事件名称
  "listen_type": "ONCE"         # 监听类型
}
```

## 模块用例

```gdscript
# 示例 1：创建监听所有模块的所有事件 (始终监听)
var filter = ModEventListenerFilter.new()
# 默认就是 ANY/ANY/ALWAYS

# 示例 2：监听特定模块的特定事件 (只监听一次)
var filter = ModEventListenerFilter.new() \
    .set_mod_filter_type(ModEventListenerFilter.ModFilterType.TARGET) \
    .set_mod_name("MyMod") \
    .set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET) \
    .set_event_name("my_event") \
    .set_listen_type(ModEventListenerFilter.ListenType.ONCE)

# 示例 3：监听特定模块的所有事件
var filter = ModEventListenerFilter.new() \
    .set_mod_filter_type(ModEventListenerFilter.ModFilterType.TARGET) \
    .set_mod_name("MyMod") \
    .set_event_filter_type(ModEventListenerFilter.EventFilterType.ANY)

# 示例 4：监听所有模块的特定事件
var filter = ModEventListenerFilter.new() \
    .set_mod_filter_type(ModEventListenerFilter.ModFilterType.ANY) \
    .set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET) \
    .set_event_name("global_event")

# 示例 5：检查是否匹配
if filter.matches("MyMod", "my_event"):
    print("事件匹配，执行监听逻辑")

# 示例 6：链式调用
var filter = ModEventListenerFilter.new()
filter.set_mod_name("MyMod").set_event_name("my_event").set_listen_type("ONCE")

# 示例 7：获取配置值
var mod_name = filter.get_mod_name()
var event_name = filter.get_event_name()
var listen_type = filter.get_listen_type()
```

# 成员变量

## 模块过滤
- var mod_filter_type: String = ModFilterType.ANY
  - 模块过滤类型
  - ANY: 监听所有模块
  - TARGET: 只监听指定模块

- var mod_name: String = ""
  - 目标模块名称
  - 当 mod_filter_type 为 TARGET 时生效

## 事件过滤
- var event_filter_type: String = EventFilterType.ANY
  - 事件过滤类型
  - ANY: 监听所有事件
  - TARGET: 只监听指定事件

- var event_name: String = ""
  - 目标事件名称
  - 当 event_filter_type 为 TARGET 时生效

## 监听类型
- var listen_type: String = ListenType.ALWAYS
  - 监听类型
  - ALWAYS: 始终监听
  - ONCE: 只监听一次

# 成员方法

## Getter 方法

- get_mod_filter_type() -> String
  - @return String: 模块过滤类型
  - functions:
    - 返回 mod_filter_type

- get_mod_name() -> String
  - @return String: 模块名称
  - functions:
    - 返回 mod_name

- get_event_filter_type() -> String
  - @return String: 事件过滤类型
  - functions:
    - 返回 event_filter_type

- get_event_name() -> String
  - @return String: 事件名称
  - functions:
    - 返回 event_name

- get_listen_type() -> String
  - @return String: 监听类型
  - functions:
    - 返回 listen_type

## Setter 方法 (链式调用)

- set_mod_filter_type(value: String) -> ModEventListenerFilter
  - @args:
    - value: 模块过滤类型
  - @return ModEventListenerFilter: 自身引用 (支持链式调用)
  - functions:
    - 设置 mod_filter_type
    - 返回 self

- set_mod_name(value: String) -> ModEventListenerFilter
  - @args:
    - value: 模块名称
  - @return ModEventListenerFilter: 自身引用
  - functions:
    - 设置 mod_name
    - 返回 self

- set_event_filter_type(value: String) -> ModEventListenerFilter
  - @args:
    - value: 事件过滤类型
  - @return ModEventListenerFilter: 自身引用
  - functions:
    - 设置 event_filter_type
    - 返回 self

- set_event_name(value: String) -> ModEventListenerFilter
  - @args:
    - value: 事件名称
  - @return ModEventListenerFilter: 自身引用
  - functions:
    - 设置 event_name
    - 返回 self

- set_listen_type(value: String) -> ModEventListenerFilter
  - @args:
    - value: 监听类型
  - @return ModEventListenerFilter: 自身引用
  - functions:
    - 设置 listen_type
    - 返回 self

## 匹配方法

- matches(from_mod: String, incoming_event: String) -> bool
  - @args:
    - from_mod: 触发事件的模块名称
    - incoming_event: 事件名称
  - @return bool: 是否匹配
  - functions:
    - 1. 检查模块匹配:
       - 如果 mod_filter_type == TARGET 且 mod_name != from_mod
       - 返回 false
    - 2. 检查事件匹配:
       - 如果 event_filter_type == TARGET 且 event_name != incoming_event
       - 返回 false
    - 3. 都匹配，返回 true

# 数据文件

- 无直接依赖的数据文件

# 模块交互

## 调用的其他模块
- 无

## 被其他模块调用
- ModManager: 注册事件监听时使用过滤器
- Mod 模块：创建过滤器配置

## 发送的事件
- 无

# 核心流程

## 过滤器配置流程
```
1. 创建 ModEventListenerFilter 实例
2. 使用链式调用设置过滤条件:
   - set_mod_filter_type()
   - set_mod_name()
   - set_event_filter_type()
   - set_event_name()
   - set_listen_type()
3. 将过滤器注册到 ModManager
```

## 事件匹配流程
```
1. 事件触发时，ModManager 遍历所有注册的过滤器
2. 对每个过滤器调用 matches(from_mod, incoming_event)
3. 检查模块匹配:
   - ANY: 总是匹配
   - TARGET: 检查 mod_name == from_mod
4. 检查事件匹配:
   - ANY: 总是匹配
   - TARGET: 检查 event_name == incoming_event
5. 都匹配则触发监听回调
6. 如果 listen_type == ONCE，移除该监听器
```

## 链式调用流程
```
1. 创建过滤器: var filter = ModEventListenerFilter.new()
2. 链式设置: filter.set_mod_name("MyMod").set_event_name("my_event")
3. 每个 setter 返回 self
4. 支持连续调用
5. 最后返回配置好的过滤器实例
```

# 架构设计

## 过滤器模式
- 使用多个过滤条件组合
- 支持 AND 逻辑 (所有条件都满足)
- 灵活配置监听规则

## 链式调用设计
- 所有 setter 返回 self
- 支持流畅的链式语法
- 提高代码可读性

## 枚举设计
- 使用 const 字典模拟枚举
- 类型安全
- 易于扩展

## 匹配逻辑
- 两级过滤 (模块 + 事件)
- 支持通配 (ANY)
- 支持精确匹配 (TARGET)

## 监听类型
- ALWAYS: 永久监听
- ONCE: 一次性监听
- 自动管理监听器生命周期

# 使用场景

## 1. 精确事件监听
- 监听特定模块的特定事件
- 避免不必要的事件处理
- 提高性能

## 2. 全局事件监听
- 监听所有模块的特定事件
- 实现全局事件总线
- 跨模块通信

## 3. 模块内事件监听
- 只监听本模块的事件
- 模块隔离
- 减少干扰

## 4. 一次性事件监听
- 初始化事件
- 触发器事件
- 自动清理监听器

## 5. 事件调试
- 监听所有事件
- 记录事件日志
- 调试模块交互

# TODO

- [ ] 添加更多监听类型
  - [ ] UNTIL_DISABLED: 直到模块禁用
  - [ ] N_TIMES: 监听 N 次

- [ ] 添加事件优先级
  - [ ] priority: int
  - [ ] 高优先级先处理

- [ ] 添加事件拦截
  - [ ] can_cancel: bool
  - [ ] 支持取消事件

- [ ] 添加事件转换
  - [ ] transform(event_data)
  - [ ] 修改事件数据

- [ ] 支持正则表达式匹配
  - [ ] mod_pattern: String
  - [ ] event_pattern: String
