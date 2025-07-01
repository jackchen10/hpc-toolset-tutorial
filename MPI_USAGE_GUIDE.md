# MPI-enabled HPC Toolset Tutorial 使用指南

## 🎯 概述

本指南介绍如何使用包含MPI支持的HPC Toolset Tutorial环境，可以直接运行您的Mandelbrot MPI Python脚本，无需重新安装依赖。

## 🚀 快速开始

### 1. 构建MPI镜像

```bash
# 给构建脚本执行权限
chmod +x build_mpi_images.sh

# 构建MPI-enabled镜像
./build_mpi_images.sh
```

### 2. 启动MPI环境

```bash
# 使用MPI-enabled compose文件启动
docker compose -f docker-compose.mpi.yml up -d

# 检查服务状态
docker compose -f docker-compose.mpi.yml ps
```

### 3. 验证MPI安装

```bash
# 测试MPI功能
docker exec frontend mpirun -np 2 /usr/local/bin/test_mpi.py

# 检查Slurm状态
docker exec frontend sinfo
```

## 🐍 运行Mandelbrot MPI任务

### 方法1: 直接在计算节点运行

```bash
# 复制您的脚本到容器
docker cp mandelbrot_simple.py frontend:/tmp/

# 在frontend上运行
docker exec frontend bash -c "
    source /etc/profile.d/mpi.sh
    cd /tmp
    mpirun -np 2 python3 mandelbrot_simple.py
"

# 复制结果图像
docker cp frontend:/tmp/mandelbrot_mpi_test.png ./
```

### 方法2: 通过Slurm作业调度

```bash
# 创建作业脚本
cat > mandelbrot_mpi.sbatch << 'EOF'
#!/bin/bash
#SBATCH --job-name=mandelbrot_mpi
#SBATCH --output=mandelbrot_%j.log
#SBATCH --error=mandelbrot_%j.err
#SBATCH --ntasks=4
#SBATCH --time=00:15:00

# 设置MPI环境
source /etc/profile.d/mpi.sh

# 运行MPI Python脚本
cd $SLURM_SUBMIT_DIR
mpirun -np $SLURM_NTASKS python3 mandelbrot_simple.py
EOF

# 复制脚本到容器
docker cp mandelbrot_mpi.sbatch frontend:/tmp/
docker cp mandelbrot_simple.py frontend:/tmp/

# 提交作业
docker exec frontend bash -c "cd /tmp && sbatch mandelbrot_mpi.sbatch"

# 监控作业
docker exec frontend squeue

# 查看结果
docker exec frontend bash -c "cd /tmp && ls -la *.png *.log"
```

### 方法3: 通过Open OnDemand Web界面

1. 访问 `https://localhost:3443`
2. 登录 (用户名: `hpcadmin`, 密码: `ilovelinux`)
3. 进入 **Jobs → Job Composer**
4. 创建新作业或使用MPI模板
5. 上传您的Python脚本
6. 配置资源需求
7. 提交作业并监控状态

## 🔧 预配置的MPI环境

### 环境变量
```bash
PATH="/usr/lib64/openmpi/bin:$PATH"
LD_LIBRARY_PATH="/usr/lib64/openmpi/lib:$LD_LIBRARY_PATH"
MPI_ROOT="/usr/lib64/openmpi"
OMPI_MCA_btl_vader_single_copy_mechanism=none
OMPI_MCA_btl_base_warn_component_unused=0
OMPI_MCA_plm_rsh_agent=/usr/bin/ssh
OMPI_ALLOW_RUN_AS_ROOT=1
OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
```

### 已安装的包
- **OpenMPI** - MPI运行时环境
- **mpi4py** - Python MPI绑定
- **numpy** - 数值计算库
- **matplotlib** - 绘图库
- **scipy** - 科学计算库

## 📊 性能测试结果

基于我们的测试，您的Mandelbrot脚本在2进程环境下：

- **分辨率**: 1000x1000 像素
- **计算时间**: ~1.02秒
- **输出文件**: ~0.15MB PNG图像
- **MPI进程**: 2个进程并行计算
- **节点分布**: 可在单节点或多节点运行

## 🛠️ 故障排除

### 常见问题

1. **MPI警告信息**
   ```
   PSM3 can't open nic unit: 0 (err=23)
   ```
   这是容器环境的网络警告，不影响MPI功能。

2. **权限问题**
   ```bash
   # 确保脚本有执行权限
   chmod +x your_script.py
   ```

3. **Python包缺失**
   ```bash
   # 在容器中安装缺失的包
   docker exec frontend python3 -m pip install --user package_name
   ```

### 调试命令

```bash
# 检查MPI版本
docker exec frontend mpirun --version

# 测试MPI通信
docker exec frontend mpirun -np 2 python3 -c "from mpi4py import MPI; print(f'Rank {MPI.COMM_WORLD.Get_rank()}')"

# 检查Slurm状态
docker exec frontend sinfo
docker exec frontend squeue

# 查看作业详情
docker exec frontend scontrol show job <job_id>
```

## 📦 镜像管理

### 保存镜像

```bash
# 保存MPI镜像到文件
docker save hpcts-mpi:latest | gzip > hpcts-mpi-latest.tar.gz

# 加载镜像
gunzip -c hpcts-mpi-latest.tar.gz | docker load
```

### 清理环境

```bash
# 停止所有服务
docker compose -f docker-compose.mpi.yml down

# 清理卷（注意：会删除所有数据）
docker compose -f docker-compose.mpi.yml down -v

# 清理镜像
docker rmi hpcts-mpi:latest
```

## 🎯 总结

通过这个MPI-enabled的Docker镜像，您可以：

✅ **即开即用** - 无需重新安装MPI和Python依赖  
✅ **多节点并行** - 支持跨节点MPI计算  
✅ **Web界面管理** - 通过OnDemand提交和监控作业  
✅ **完整HPC环境** - 包含Slurm、XDMoD、ColdFront  
✅ **持久化存储** - 镜像可保存和重用  

您的Mandelbrot MPI Python脚本现在可以在这个环境中无缝运行，享受真正的并行计算能力！
