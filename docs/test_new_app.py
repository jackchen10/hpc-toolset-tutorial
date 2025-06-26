#!/usr/bin/env python3
"""
测试新添加的 Interactive Apps
检查应用配置文件的有效性
"""

import os
import sys
from pathlib import Path

def validate_yaml_file(file_path):
    """简单验证YAML文件格式"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # 基本YAML格式检查
        if not content.strip().startswith('---'):
            return False, "YAML should start with '---'"

        # 检查是否有基本的键值对
        lines = content.split('\n')
        has_key_value = any(':' in line for line in lines if line.strip() and not line.strip().startswith('#'))

        if not has_key_value:
            return False, "No key-value pairs found"

        return True, "Basic YAML format OK"
    except Exception as e:
        return False, f"Error: {e}"

def check_app_structure(app_path):
    """检查应用目录结构"""
    app_path = Path(app_path)
    
    if not app_path.exists():
        return False, f"App directory does not exist: {app_path}"
    
    required_files = ['manifest.yml', 'form.yml']
    missing_files = []
    
    for file_name in required_files:
        file_path = app_path / file_name
        if not file_path.exists():
            missing_files.append(file_name)
    
    if missing_files:
        return False, f"Missing required files: {', '.join(missing_files)}"
    
    # 检查可选文件
    optional_files = ['submit.yml.erb', 'template/script.sh.erb', 'icon.png']
    existing_optional = []
    
    for file_name in optional_files:
        file_path = app_path / file_name
        if file_path.exists():
            existing_optional.append(file_name)
    
    return True, f"Required files present. Optional files: {', '.join(existing_optional) if existing_optional else 'None'}"

def validate_manifest(manifest_path):
    """验证manifest.yml内容"""
    try:
        with open(manifest_path, 'r', encoding='utf-8') as f:
            content = f.read()

        required_fields = ['name:', 'category:', 'role:']
        missing_fields = []

        for field in required_fields:
            if field not in content:
                missing_fields.append(field.rstrip(':'))

        if missing_fields:
            return False, f"Missing required fields in manifest: {', '.join(missing_fields)}"

        if 'role: batch_connect' not in content:
            return False, "Role should be 'batch_connect'"

        # 提取应用名称
        app_name = "Unknown"
        for line in content.split('\n'):
            if line.strip().startswith('name:'):
                app_name = line.split(':', 1)[1].strip()
                break

        return True, f"Valid manifest for app: {app_name}"

    except Exception as e:
        return False, f"Error validating manifest: {e}"

def validate_form(form_path):
    """验证form.yml内容"""
    try:
        with open(form_path, 'r', encoding='utf-8') as f:
            content = f.read()

        if 'cluster:' not in content:
            return False, "Missing 'cluster' field in form.yml"

        if 'cluster: "hpc"' not in content and "cluster: 'hpc'" not in content and 'cluster: hpc' not in content:
            return False, "Cluster should be 'hpc'"

        return True, "Valid form configuration"

    except Exception as e:
        return False, f"Error validating form: {e}"

def main():
    """主函数"""
    if len(sys.argv) < 2:
        print("Usage: python test_new_app.py <app_directory>")
        print("Example: python test_new_app.py ondemand/rstudio")
        sys.exit(1)
    
    app_path = sys.argv[1]
    app_name = os.path.basename(app_path)
    
    print(f"Testing Interactive App: {app_name}")
    print("=" * 50)
    
    # 检查目录结构
    success, message = check_app_structure(app_path)
    print(f"Directory Structure: {'✓' if success else '✗'} {message}")
    
    if not success:
        sys.exit(1)
    
    # 验证manifest.yml
    manifest_path = Path(app_path) / 'manifest.yml'
    success, message = validate_yaml_file(manifest_path)
    print(f"Manifest YAML: {'✓' if success else '✗'} {message}")
    
    if success:
        success, message = validate_manifest(manifest_path)
        print(f"Manifest Content: {'✓' if success else '✗'} {message}")
    
    # 验证form.yml
    form_path = Path(app_path) / 'form.yml'
    success, message = validate_yaml_file(form_path)
    print(f"Form YAML: {'✓' if success else '✗'} {message}")
    
    if success:
        success, message = validate_form(form_path)
        print(f"Form Content: {'✓' if success else '✗'} {message}")
    
    # 检查submit.yml.erb
    submit_path = Path(app_path) / 'submit.yml.erb'
    if submit_path.exists():
        # ERB文件不能直接验证YAML，只检查存在性
        print(f"Submit Template: ✓ Found")
    else:
        print(f"Submit Template: ⚠ Not found (optional)")
    
    # 检查启动脚本
    script_path = Path(app_path) / 'template' / 'script.sh.erb'
    if script_path.exists():
        print(f"Start Script: ✓ Found")
    else:
        print(f"Start Script: ⚠ Not found (optional)")
    
    print("\n" + "=" * 50)
    print("Validation completed!")
    print("\nNext steps:")
    print("1. Run: docs/deploy_new_apps.bat")
    print("2. Visit: https://localhost:3443")
    print("3. Check Interactive Apps page")

if __name__ == "__main__":
    main()
