# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

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

# 基础逻辑/基础功能

- 声明全局种子，GameCore.Settings.GameSettings.WorldSeed，所有方法的随机数都基于这个种子，每个步骤的随机数都基于全局种子，确保可重复生成相同结果。

## 基础代码内容：
```gdscript
extends ModInterface
```

## 提供功能
模块入口，继承ModInterface基类

# 成员变量
- 待分析

# 成员方法
- _on_mod_load() -> bool
   - @return bool: 是否加载成功
   - functions:
      - 模块加载时调用

- _on_mod_enable() -> void
   - @return void
   - functions:
      - 模块启用时调用

- _on_mod_disable() -> void
   - @return void
   - functions:
      - 模块禁用时调用

- _on_mod_unload() -> void
   - @return void
   - functions:
      - 模块卸载时调用

# 数据文件
- ModuleConfig.json: 模块配置文件
