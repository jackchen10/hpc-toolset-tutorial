# VS Code Server 应用修复报告

## 问题描述

用户在点击 VS Code Server 应用时遇到错误：

```
Failed to stage the template with the following error:
sending incremental file list
rsync: change_dir "/var/www/ood/apps/sys/vscode/template" failed: No such file or directory (2)
```

## 问题原因

VS Code Server 应用缺少必要的配置文件：

1. 缺少 `submit.yml.erb` 文件
2. 缺少 `template/` 目录
3. 缺少 `template/script.sh.erb` 启动脚本

## 解决方案

### 1. 创建完整的 VS Code Server 配置

已创建以下文件：

- `ondemand/vscode/submit.yml.erb` - 作业提交配置
- `ondemand/vscode/template/script.sh.erb` - 启动脚本
- 修复了 `ondemand/vscode/form.yml` 的 YAML 格式

### 2. VS Code Server 启动脚本特性

启动脚本包含以下功能：

- 自动下载和安装 code-server
- 生成安全密码
- 动态分配端口
- 配置工作目录
- 禁用遥测和自动更新

### 3. 部署步骤

```bash
# 1. 验证配置
python docs/test_new_app.py ondemand/vscode

# 2. 复制到容器
docker cp ondemand/vscode ondemand:/var/www/ood/apps/sys/

# 3. 重启服务
docker restart ondemand
```

## 验证修复

1. 访问 https://localhost:3443
2. 进入 Interactive Apps
3. 点击 "VS Code Server"
4. 应该能正常显示配置表单

## 注意事项

### VS Code Server 资源需求

- 内存：建议至少 2GB
- CPU：建议至少 2 核心
- 网络：需要下载 code-server (~100MB)

### 首次启动时间

- 首次启动需要下载 code-server，可能需要 2-5 分钟
- 后续启动会更快

### 替代方案

如果 VS Code Server 仍有问题，可以考虑：

1. 使用内置的 File Editor
2. 使用 Jupyter Notebook 的编辑功能
3. 部署更简单的文本编辑器应用

## 故障排除

### 如果应用仍然失败

1. **检查容器日志**：

   ```bash
   docker logs ondemand --tail 50
   ```

2. **检查应用文件**：

   ```bash
   docker exec ondemand ls -la /var/www/ood/apps/sys/vscode/
   ```

3. **验证模板文件**：
   ```bash
   docker exec ondemand ls -la /var/www/ood/apps/sys/vscode/template/
   ```

### 常见错误

1. **Template not found**: 确保 template 目录存在
2. **Permission denied**: 检查文件权限
3. **Download failed**: 检查网络连接

## 成功标志

修复成功后，VS Code Server 应该：

1. 在 Interactive Apps 页面正常显示
2. 点击后显示配置表单
3. 能够成功提交作业
4. 启动后提供 VS Code 界面

## 最新更新 (2025-06-25)

### 第二次修复尝试

用户报告仍然遇到变量未定义错误：

```
undefined local variable or method `working_dir'
```

### 解决方案

1. **修复了 ERB 模板中的变量访问**：

   - 使用 `defined?(working_dir)` 检查变量是否存在
   - 提供了默认的 HOME 目录作为工作目录

2. **创建了替代应用**：
   - **Text Editor** (`ondemand/text-editor/`) - 基于 Jupyter Lab 的简单文本编辑器
   - 更稳定，依赖更少
   - 提供良好的文件编辑体验

### 推荐使用顺序

1. **首选**: Text Editor - 稳定可靠的文本编辑器
2. **次选**: RStudio Server - 完整的 R 开发环境
3. **备选**: VS Code Server - 功能强大但配置复杂

现在用户有多个选择来满足不同的开发需求！
