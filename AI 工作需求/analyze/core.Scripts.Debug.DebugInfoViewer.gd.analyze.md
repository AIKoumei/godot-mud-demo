# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

无

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
DebugInfoViewer

## 模块路径
res://core/Scripts/Debug/DebugInfoViewer.gd

## 模块功能
调试信息查看器，显示 FPS 和 DrawCalls 性能指标图表

## 涉及模块
- GameCore: 通过 CanvasLayer 显示

# 成员变量

- max_history: int = 200
   - 最大历史记录数

- sample_interval: float = 0.1
   - 采样间隔（秒）

- fps_color: Color
   - FPS 图表颜色

- dc_color: Color
   - DrawCalls 图表颜色

- bg_color: Color
   - 背景颜色

- axis_color: Color
   - 坐标轴颜色

- fps_history: Array[float]
   - FPS 历史记录数组

- dc_history: Array[int]
   - DrawCalls 历史记录数组

- _time_accum: float
   - 时间累积器

- _last_fps: int
   - 上次记录的 FPS

- _last_dc: int
   - 上次记录的 DrawCalls

# 成员方法

- _ready() -> void
   - @return void
   - 功能说明：
      - 初始化调试查看器
      - 连接绘图信号
      - 连接按钮信号

- _process(delta: float) -> void
   - @param delta: 帧时间间隔
   - @return void
   - 功能说明：
      - 每帧采样 FPS 和 DrawCalls
      - 更新图表显示

- _record_metrics() -> void
   - @return void
   - 功能说明：
      - 记录性能指标
      - 获取 FPS 和 DrawCalls
      - 更新历史记录数组
      - 更新标题显示

- _on_fps_draw() -> void
   - @return void
   - 功能说明：
      - 绘制 FPS 图表

- _on_dc_draw() -> void
   - @return void
   - 功能说明：
      - 绘制 DrawCalls 图表

- _draw_graph(viewer: Control, data: Array, color: Color) -> void
   - @param viewer: 绘图控件
   - @param data: 数据数组
   - @param color: 图表颜色
   - @return void
   - 功能说明：
      - 通用图表绘制函数
      - 绘制坐标轴和刻度
      - 绘制数据曲线

- _on_show_pressed() -> void
   - @return void
   - 功能说明：
      - 显示调试视图

- _on_hide_pressed() -> void
   - @return void
   - 功能说明：
      - 隐藏调试视图

# 数据文件

无
