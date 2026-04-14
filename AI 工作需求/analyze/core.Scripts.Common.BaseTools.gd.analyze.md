# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

- 位置字符串转 Vector2i
   ```gdscript
   var pos = GameCore.BaseTools.pos_str_to_veci("10,20")
   # 结果：Vector2i(10, 20)
   ```

- Vector2i 转位置字符串
   ```gdscript
   var pos_str = GameCore.BaseTools.veci_to_pos_str(Vector2i(10, 20))
   # 结果："10,20"
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
BaseTools

## 模块路径
res://core/Scripts/Common/BaseTools.gd

## 模块功能
基础工具类，提供坐标字符串与 Vector2i 之间的转换方法

## 涉及模块
- GameCore: 通过 GameCore.BaseTools 调用

# 成员变量

无

# 成员方法

- pos_str_to_veci(str: String) -> Vector2i
   - @param str: 位置字符串，格式为"x,y"
   - @return Vector2i: 转换后的二维向量
   - 功能说明：
      - 将逗号分隔的字符串解析为 Vector2i
      - 使用 split 分割字符串
      - 将分割结果转换为整数
   - 用例：
      ```gdscript
      var pos = GameCore.BaseTools.pos_str_to_veci("10,20")
      # 结果：Vector2i(10, 20)
      ```

- veci_to_pos_str(vec: Vector2i) -> String
   - @param vec: 二维向量
   - @return String: 位置字符串，格式为"x,y"
   - 功能说明：
      - 将 Vector2i 转换为逗号分隔的字符串
      - 使用字符串格式化
   - 用例：
      ```gdscript
      var pos_str = GameCore.BaseTools.veci_to_pos_str(Vector2i(10, 20))
      # 结果："10,20"
      ```

# 数据文件

无
