# HPC Toolset Tutorial - Windows 11 部署指南

## 部署状态
✅ 项目已配置完成并启动

## 自动化脚本
我已经为您创建了以下脚本来管理HPC Toolset：

### 1. 启动脚本
- `start_hpc.bat` - Windows批处理启动脚本
- `hpcts.py` - Python管理脚本（原项目提供）

### 2. 状态检查脚本
- `simple_check.bat` - 简单状态检查
- `check_services.py` - 详细状态检查
- `check_status.ps1` - PowerShell状态检查

## 服务访问地址

### Web界面
- **ColdFront**: https://localhost:2443
  - 资源管理和分配系统
  - 默认管理员: admin/admin
  
- **Open OnDemand**: https://localhost:3443
  - HPC资源访问门户
  - 支持作业提交、文件管理、交互式应用
  
- **Open XDMoD**: https://localhost:4443
  - 性能监控和分析
  - 作业指标和系统统计

### SSH访问
- **集群前端**: ssh -p 6222 hpcadmin@localhost
  - 密码: ilovelinux

## 用户账户

### 管理员账户
- Username: `admin`
- Password: `admin`

### LDAP用户账户
默认密码: `ilovelinux`
- hpcadmin (管理员)
- cgray (普通用户)
- sfoster (普通用户)
- 其他测试用户...

## 手动启动命令

如果需要手动管理服务：

```bash
# 启动所有服务
docker compose up -d

# 停止所有服务
docker compose stop

# 查看服务状态
docker compose ps

# 查看日志
docker compose logs

# 完全清理（删除容器和数据）
docker compose down -v
```

## 故障排除

### 1. 端口冲突
如果遇到端口占用问题，检查以下端口是否被占用：
- 2443, 3443, 4443, 5554, 6222

### 2. 服务启动缓慢
- 首次启动需要下载大量Docker镜像，请耐心等待
- 数据库初始化需要时间
- 建议等待5-10分钟后再访问服务

### 3. 浏览器安全警告
- 由于使用自签名证书，浏览器会显示安全警告
- 点击"高级"然后"继续访问"即可

### 4. 重置环境
如果需要完全重置：
```bash
docker compose down -v
docker system prune -f
# 然后重新启动
docker compose up -d
```

## 教程资源

### 文档位置
- ColdFront教程: `coldfront/README.md`
- OnDemand教程: `ondemand/README.md`  
- XDMoD教程: `xdmod/README.md`
- 总体文档: `docs/` 目录

### 学习建议
1. 先访问ColdFront了解资源管理
2. 然后使用OnDemand提交作业
3. 最后在XDMoD中查看性能数据

## 技术支持
- 项目GitHub: https://github.com/ubccr/hpc-toolset-tutorial
- 官方文档: 各组件的官方网站
- 社区支持: 相关项目的GitHub Issues

---
部署完成时间: $(Get-Date)
系统: Windows 11 + Docker Desktop
