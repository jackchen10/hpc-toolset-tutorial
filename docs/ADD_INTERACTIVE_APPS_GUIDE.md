# Open OnDemand Interactive Apps 添加指南

## 概述

Open OnDemand Interactive Apps 允许用户通过 Web 界面启动和访问各种 HPC 应用程序。目前系统中有两个应用：

- **HPC Desktop** (桌面环境)
- **Jupyter Notebook** (数据科学环境)

## Interactive Apps 结构

每个 Interactive App 都需要以下文件：

### 必需文件

1. **manifest.yml** - 应用元数据和描述
2. **form.yml** - 用户界面表单配置
3. **submit.yml.erb** - 作业提交模板
4. **template/script.sh.erb** - 启动脚本模板

### 可选文件

- **icon.png** - 应用图标
- **view.html.erb** - 自定义视图模板
- **template/before.sh.erb** - 启动前脚本
- **template/after.sh** - 清理脚本

## 添加新应用的步骤

### 步骤 1: 创建应用目录

在 `ondemand/` 目录下创建新应用目录，例如添加 RStudio：

```bash
mkdir ondemand/rstudio
```

### 步骤 2: 创建 manifest.yml

```yaml
---
name: RStudio Server
category: Interactive Apps
subcategory: Servers
role: batch_connect
description: |
  This app will launch an RStudio Server session on a compute node.
```

### 步骤 3: 创建 form.yml

```yaml
---
cluster: "hpc"

attributes:
  modules: ""
  memory:
    widget: "number_field"
    max: 2000
    min: 500
    step: 500
    value: 1000
    label: "Memory (MB)"
    help: "Amount of memory to allocate"
    display: true

  bc_num_hours:
    display: true
    max: 8
    value: 2

  bc_num_slots:
    display: true
    max: 1
    value: 1

form:
  - memory
  - bc_num_hours
  - bc_num_slots
```

### 步骤 4: 创建 submit.yml.erb

```yaml
---
batch_connect:
  template: "template/script.sh.erb"
  conn_params:
    - host
    - port
    - password
script:
  accounting_id: "<%= bc_account %>"
  queue_name: "<%= bc_queue.blank? ? "compute" : bc_queue %>"
  wall_time: "<%= bc_num_hours.to_i * 3600 %>"
  email_on_started: true
  job_name: "rstudio_server"
  native:
    - "--nodes=1"
    - "--ntasks-per-node=<%= bc_num_slots.to_i %>"
    - "--mem=<%= memory.to_i %>M"
```

### 步骤 5: 创建启动脚本

创建 `template/script.sh.erb`：

```bash
#!/bin/bash

# 设置环境变量
export TMPDIR="${TMPDIR:-/tmp}"
export TMP="${TMP:-/tmp}"

# 生成随机密码
password=$(openssl rand -base64 32)
export RSTUDIO_PASSWORD="${password}"

# 设置端口
port=$(python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')

# 启动RStudio Server
echo "Starting RStudio Server on port ${port}"
echo "Password: ${password}"

# 创建临时配置
mkdir -p "${TMPDIR}/rstudio-server"
cat > "${TMPDIR}/rstudio-server/rserver.conf" << EOF
www-port=${port}
auth-none=0
auth-pam-helper-path=pam-helper
auth-stay-signed-in-days=30
auth-timeout-minutes=0
auth-login-page-html=login.html
EOF

# 启动服务
/usr/lib/rstudio-server/bin/rserver \
  --server-config-file="${TMPDIR}/rstudio-server/rserver.conf" \
  --www-port="${port}" \
  --auth-none=0 \
  --auth-pam-helper-path=pam-helper

echo "RStudio Server started on $(hostname):${port}"
```

## 常见应用模板

### 1. VS Code Server

```bash
# 在 ondemand/ 目录下
mkdir vscode
cd vscode

# manifest.yml
cat > manifest.yml << 'EOF'
---
name: VS Code Server
category: Interactive Apps
subcategory: Servers
role: batch_connect
description: |
  Launch VS Code Server for web-based development.
EOF

# form.yml - 类似上面的RStudio配置
```

### 2. TensorBoard

```bash
mkdir tensorboard
cd tensorboard

# manifest.yml
cat > manifest.yml << 'EOF'
---
name: TensorBoard
category: Interactive Apps
subcategory: Servers
role: batch_connect
description: |
  Launch TensorBoard for machine learning visualization.
EOF
```

### 3. Paraview

```bash
mkdir paraview
cd paraview

# manifest.yml
cat > manifest.yml << 'EOF'
---
name: ParaView
category: Interactive Apps
subcategory: Visualization
role: batch_connect
description: |
  Launch ParaView for scientific visualization.
EOF
```

## 部署新应用

### 方法 1: 重建容器（推荐）

```bash
# 停止当前服务
docker-compose down

# 重新构建OnDemand容器
docker-compose build ondemand

# 启动服务
docker-compose up -d
```

### 方法 2: 热部署（快速测试）

```bash
# 复制应用到运行中的容器
docker cp ./ondemand/your_new_app ondemand_container:/var/www/ood/apps/sys/

# 重启OnDemand服务
docker exec ondemand_container systemctl restart httpd
```

## 调试和故障排除

### 检查应用状态

```bash
# 进入OnDemand容器
docker exec -it ondemand_container bash

# 检查应用目录
ls -la /var/www/ood/apps/sys/

# 检查日志
tail -f /var/log/httpd/error_log
```

### 常见问题

1. **应用不显示**: 检查 manifest.yml 格式
2. **启动失败**: 检查 script.sh.erb 权限和语法
3. **连接问题**: 检查端口配置和防火墙

## 高级配置

### 自定义图标

- 将 64x64 像素的 PNG 图标放在应用目录下命名为`icon.png`

### 自定义视图

- 创建`view.html.erb`自定义连接页面

### 环境模块

- 在 form.yml 中配置所需的环境模块

## 示例：完整的 RStudio 应用

我已经为你创建了一个完整的 RStudio Interactive App 示例，位于 `ondemand/rstudio/` 目录。

### 快速部署新应用

1. **验证应用配置**：

   ```bash
   python docs/test_new_app.py ondemand/rstudio
   ```

2. **部署应用**：

   ```bash
   docs/deploy_new_apps.bat
   ```

3. **访问应用**：
   - 打开 https://localhost:3443
   - 登录后进入 Interactive Apps
   - 你应该看到新的 "RStudio Server" 应用

### 创建的示例应用

1. **RStudio Server** (`ondemand/rstudio/`)

   - 完整的 R 开发环境
   - 可配置内存和 CPU
   - 支持自定义工作目录

2. **VS Code Server** (`ondemand/vscode/`)
   - Web 版本的 VS Code
   - 适合代码开发和编辑

### 工具脚本

- `docs/test_new_app.py` - 验证应用配置
- `docs/deploy_new_apps.bat` - 快速部署脚本

现在你可以按照这个模式创建更多的 Interactive Apps！
