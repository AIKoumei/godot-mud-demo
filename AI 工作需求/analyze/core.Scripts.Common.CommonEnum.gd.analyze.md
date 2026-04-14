# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

- 访问场景路径枚举
   ```gdscript
   var logo_path = CommonEnum.ScenePath.LogoScene
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
CommonEnum

## 模块路径
res://core/Scripts/Common/CommonEnum.gd

## 模块功能
公共枚举定义（可能废弃）
存储场景路径等公共常量

## 涉及模块
- 全局可用

# 成员变量

- ScenePath: Dictionary
   ```json
   {
      "LogoScene": "LogoScene",
      "LoadingScene": "LoadingScene",
      "StartMenuScene": "StartMenuScene"
   }
   ```
   - 说明：场景路径映射（可能废弃）

# 成员方法

无

# 数据文件

无
