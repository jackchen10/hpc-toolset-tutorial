# Git 推送工作流程

## 推送前检查流程

### 1. 检查当前状态
```bash
git status
```

### 2. 获取最新远程更新
```bash
git fetch origin
```

### 3. 检查是否有冲突
```bash
git status
```

### 4. 如果有远程更新，先合并
```bash
# 方法1: 合并（推荐用于协作）
git pull origin master

# 方法2: 变基（保持线性历史）
git pull --rebase origin master
```

### 5. 解决冲突（如果有）
```bash
# 查看冲突文件
git status

# 编辑冲突文件，然后
git add <冲突文件>
git commit -m "解决合并冲突"
```

### 6. 推送
```bash
git push origin master
```

## 常见错误处理

### 错误1: "Updates were rejected because the remote contains work"
```bash
# 解决方案
git fetch origin
git pull origin master  # 或 git pull --rebase origin master
git push origin master
```

### 错误2: "non-fast-forward"
```bash
# 如果确定要覆盖远程（谨慎使用）
git push --force-with-lease origin master
```

### 错误3: 网络问题
```bash
# 重试推送
git push origin master

# 或使用SSH（如果配置了）
git remote set-url origin git@github.com:jackchen10/hpc-toolset-tutorial.git
```

## Fork仓库的特殊处理

### 添加上游仓库
```bash
git remote add upstream https://github.com/原始仓库/hpc-toolset-tutorial.git
```

### 同步上游更新
```bash
git fetch upstream
git checkout master
git merge upstream/master
git push origin master
```

## 自动化脚本

创建一个安全推送脚本：
```bash
#!/bin/bash
# safe-push.sh

echo "开始安全推送流程..."

# 检查工作区状态
if [ -n "$(git status --porcelain)" ]; then
    echo "工作区有未提交的更改，请先提交"
    exit 1
fi

# 获取远程更新
echo "获取远程更新..."
git fetch origin

# 检查是否需要合并
if [ "$(git rev-list HEAD..origin/master --count)" -gt 0 ]; then
    echo "远程有新提交，正在合并..."
    git pull --rebase origin master
    if [ $? -ne 0 ]; then
        echo "合并失败，请手动解决冲突"
        exit 1
    fi
fi

# 推送
echo "推送到远程..."
git push origin master

echo "推送完成！"
```
