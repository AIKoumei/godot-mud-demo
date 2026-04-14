#  基础规则
# 1. 代码注释
# 1.1. 为文件适当添加注释
    给出配置
    给出输入输出的数据结构
    说明模块的功能
    给出模块的用例
    给出涉及模块的名称
# 1.2. 在文件头给出模块的主要功能以及对应方法
# 1.3. 给出功能的用例
# 2. location 配置文件："%s/Data/Locations.json" % GameCore.mod_manager.loaded_mods[mod_name].path
# 3. 基础代码内容：
    extends ModInterface
#  功能概要
##  模块提供接收字典数据，批量注册 location 的配置方法
    例如，读取 Locations.json 文件，将文件内容交给 regist_locations_from_json 方法
    例如，读取 Locations.json 文件，将文件内容交给 regist_relationships_from_json 方法
##  在 _on_mod_enable 阶段加载 Locations.json 文件，将文件内容交给 regist_from_json 方法
#  成员变量
#  成员方法
##  regist_locations_from_json
    通过文件内容，注册所有 location 的配置
## 1. 提供 location 的增删改查方法
##  regist_relationships_from_json
    通过文件内容，注册所有 location 的关系配置
## 1. 提供 relationship 的增删改查方法
# 3. regist_from_json
    通过文件内容，注册所有的配置
        包括 location 的配置
        包括 location 的关系配置
#  数据文件
##  该模块目录下的 Data/Locations.json 文件，是该模块的地点配置文件
## 1. 该文件有部分数据为：
    {
        "metadata": {
            "version": "1.0",
            "generated_at": "YYYY-MM-DD HH:MM:SS",
            "total_locations": 874,
            "total_relationships": 821
        },
        "data": {
            "locations": {
                "Location Name": {
                    "name": "Location Name",
                    "Kanji/Kana": {
                        "content": "地点的日文名称",
                        "url": "相关链接"
                    },
                    "inhabitants": {
                        "Location Name": [
                            {
                                "text": "居民名称",
                                "url": "居民的维基链接"
                            }
                        ]
                    },
                    "url": "地点的维基链接",
                    "introduce": "地点的简要介绍",
                    "description": "地点的详细描述",
                    "type": {
                        "content": "地点类型（如Park、Continent、Arena等）",
                        "url": "相关链接"
                    },
                    "location_level_type": "地点级别类型（如Location、Continent、Area）",
                    "mud_map_type": "地图类型（如wilderness、town）"
                }
            }
        }
    }

    说明：
    - metadata：包含文件的元数据信息
        - version：文件版本号
        - generated_at：生成时间，格式为YYYY-MM-DD HH:MM:SS
        - total_locations：地点总数
        - total_relationships：关系总数
    - data：包含地点数据
        - locations：所有地点的字典，键为地点名称
            - 每个地点包含：
                - name：地点名称
                - Kanji/Kana：日文名称（可选，可能为空字符串）
                    - content：日文内容
                    - url：相关链接
                - inhabitants：居民信息
                    - 键为地点名称，值为居民数组
                    - 每个居民包含text（居民名称）和url（居民链接）
                - url：地点的维基链接
                - introduce：地点的简要介绍
                - description：地点的详细描述
                - type：地点类型
                    - content：类型名称
                    - url：相关链接
                - location_level_type：地点级别类型
                - mud_map_type：地图类型
