#!/usr/bin/env python3
import os
import re
import sys

def update_markdown_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # 替换 0. 开头的标题
    content = re.sub(r'^0\.(.*?)$', r'# \1', content, flags=re.MULTILINE)
    
    # 替换 0.0.1. 等多级标题
    content = re.sub(r'^0\.0\.1\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    content = re.sub(r'^0\.0\.2\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    
    # 替换 0.1. 等标题
    content = re.sub(r'^0\.1\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    content = re.sub(r'^0\.2\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    content = re.sub(r'^0\.3\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    content = re.sub(r'^0\.4\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    content = re.sub(r'^0\.5\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    
    # 替换 0.1.1. 等标题
    content = re.sub(r'^0\.1\.1\.(.*?)$', r'1. \1', content, flags=re.MULTILINE)
    content = re.sub(r'^0\.1\.2\.(.*?)$', r'2. \1', content, flags=re.MULTILINE)
    content = re.sub(r'^0\.1\.3\.(.*?)$', r'3. \1', content, flags=re.MULTILINE)
    
    # 替换 1.0. 等标题
    content = re.sub(r'^1\.0\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    content = re.sub(r'^1\.1\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    content = re.sub(r'^1\.2\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    content = re.sub(r'^1\.3\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    
    # 替换 1.3.1. 等标题
    content = re.sub(r'^1\.3\.1\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    content = re.sub(r'^1\.3\.1\.1\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    content = re.sub(r'^1\.3\.1\.2\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    content = re.sub(r'^1\.3\.1\.3\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    
    # 替换 2.1. 等标题
    content = re.sub(r'^2\.1\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    content = re.sub(r'^2\.2\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    content = re.sub(r'^3\.1\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    content = re.sub(r'^3\.2\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    content = re.sub(r'^4\.1\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    content = re.sub(r'^4\.1\.1\.(.*?)$', r'## \1', content, flags=re.MULTILINE)
    
    # 替换剩下的 1.、2.、3.、4. 等一级标题为 #
    content = re.sub(r'^1\.(.*?)$', r'# \1', content, flags=re.MULTILINE)
    content = re.sub(r'^2\.(.*?)$', r'# \1', content, flags=re.MULTILINE)
    content = re.sub(r'^3\.(.*?)$', r'# \1', content, flags=re.MULTILINE)
    content = re.sub(r'^4\.(.*?)$', r'# \1', content, flags=re.MULTILINE)
    
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated: {filepath}")
        return True
    return False

def find_markdown_files(directory):
    markdown_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.md'):
                filepath = os.path.join(root, file)
                # 跳过 addons 目录下的文件
                if 'addons' in filepath.replace('\\', '/').split('/'):
                    continue
                markdown_files.append(filepath)
    return markdown_files

def main():
    project_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    print(f"Scanning directory: {project_dir}")
    
    markdown_files = find_markdown_files(project_dir)
    print(f"Found {len(markdown_files)} markdown files")
    
    updated_count = 0
    for filepath in markdown_files:
        try:
            if update_markdown_file(filepath):
                updated_count += 1
        except Exception as e:
            print(f"Error processing {filepath}: {e}")
    
    print(f"\nTotal files updated: {updated_count}")

if __name__ == '__main__':
    main()
