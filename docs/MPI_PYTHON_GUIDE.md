# MPI Python 作业运行指南

本指南详细说明如何在HPC Toolset Tutorial环境中运行您的MPI Python脚本（Mandelbrot集合计算）。

## 🎯 概述

您的MPI Python脚本可以在当前的HPC环境中运行，但需要一些配置调整来支持MPI并行计算。

## 📋 当前环境状态

### ✅ 已支持的功能
- **Slurm作业调度器** - 完整配置
- **多节点计算** - 2个计算节点 (cpn01, cpn02)
- **Python环境** - Python 3.9 + Jupyter
- **Web界面** - Open OnDemand作业提交
- **资源管理** - 动态资源分配

### ⚠️ 需要添加的组件
- **MPI运行时** - OpenMPI/MPICH
- **mpi4py** - Python MPI绑定
- **优化配置** - 容器间MPI通信

## 🚀 快速开始

### 方法1: 使用预配置的MPI模板

1. **复制MPI作业模板**
   ```bash
   # 登录到OnDemand Web界面
   # 进入 Jobs → Job Composer
   # 选择 "MPI Python Job (Mandelbrot Set)" 模板
   ```

2. **上传您的脚本**
   - 将您的脚本重命名为 `mandelbrot_mpi.py`
   - 或修改模板中的脚本名称

3. **调整资源配置**
   ```bash
   #SBATCH --nodes=2              # 节点数量
   #SBATCH --ntasks=4             # 总任务数
   #SBATCH --ntasks-per-node=2    # 每节点任务数
   #SBATCH --time=02:00:00        # 运行时间
   ```

4. **提交作业**
   - 点击 "Submit" 按钮
   - 监控作业状态

### 方法2: 命令行提交

1. **登录到frontend容器**
   ```bash
   docker exec -it frontend bash
   ```

2. **安装MPI支持**
   ```bash
   # 运行MPI安装脚本
   /usr/local/bin/install_mpi_support.sh
   ```

3. **创建作业脚本**
   ```bash
   cat > mandelbrot_job.sbatch << 'EOF'
   #!/bin/bash
   #SBATCH --job-name=mandelbrot_mpi
   #SBATCH --nodes=2
   #SBATCH --ntasks=4
   #SBATCH --ntasks-per-node=2
   #SBATCH --time=02:00:00
   #SBATCH --output=output_%j.log
   #SBATCH --error=error_%j.log
   
   # 加载MPI环境
   source /etc/profile.d/mpi.sh
   
   # 激活Python环境
   source /usr/local/jupyter/4.3.5/bin/activate
   
   # 安装依赖包
   pip install --user mpi4py numpy matplotlib
   
   # 运行MPI Python脚本
   mpirun -np $SLURM_NTASKS python mandelbrot_mpi.py
   EOF
   ```

4. **提交作业**
   ```bash
   sbatch mandelbrot_job.sbatch
   ```

## 🔧 脚本优化建议

### 1. 环境兼容性
您的原始脚本已经很好，但建议做以下调整：

```python
# 添加错误处理和环境检查
try:
    from mpi4py import MPI
except ImportError:
    import subprocess
    subprocess.check_call(["pip", "install", "--user", "mpi4py"])
    from mpi4py import MPI

# 使用非交互式matplotlib后端
import matplotlib
matplotlib.use('Agg')  # 重要：容器环境需要非交互式后端
import matplotlib.pyplot as plt
```

### 2. 资源配置优化
```python
# 根据可用资源调整参数
def plot_mandelbrot(xmin, xmax, ymin, ymax, width, height, max_iter, filename):
    comm = MPI.COMM_WORLD
    size = comm.Get_size()
    
    # 根据进程数调整分辨率
    if size <= 2:
        width, height = 5000, 5000  # 较小分辨率
    elif size <= 4:
        width, height = 8000, 8000  # 中等分辨率
    else:
        width, height = 10000, 10000  # 高分辨率
```

### 3. 容器环境优化
```bash
# 在作业脚本中添加MPI优化设置
export OMPI_MCA_btl_vader_single_copy_mechanism=none
export OMPI_MCA_btl_base_warn_component_unused=0
export OMPI_MCA_plm_rsh_agent=ssh
export OMPI_MCA_btl_tcp_if_include=eth0
```

## 📊 性能预期

### 当前环境配置
- **节点**: 2个计算节点
- **CPU**: 每节点2核心
- **内存**: 每节点1GB
- **网络**: Docker内部网络

### 预期性能
- **2进程**: ~30-60秒 (5000x5000分辨率)
- **4进程**: ~15-30秒 (8000x8000分辨率)
- **输出**: 高质量PNG图像

## 🐛 故障排除

### 常见问题

1. **MPI未找到**
   ```bash
   # 解决方案：安装MPI支持
   dnf install -y openmpi openmpi-devel
   pip install --user mpi4py
   ```

2. **matplotlib显示错误**
   ```python
   # 解决方案：使用非交互式后端
   import matplotlib
   matplotlib.use('Agg')
   ```

3. **进程间通信失败**
   ```bash
   # 解决方案：设置MPI环境变量
   export OMPI_MCA_btl_vader_single_copy_mechanism=none
   ```

4. **权限问题**
   ```bash
   # 解决方案：确保文件权限正确
   chmod +x mandelbrot_mpi.py
   ```

### 调试命令
```bash
# 检查MPI安装
mpirun --version

# 测试MPI功能
mpirun -np 2 python -c "from mpi4py import MPI; print(f'Rank {MPI.COMM_WORLD.Get_rank()}')"

# 查看作业状态
squeue
scontrol show job <job_id>

# 查看作业输出
tail -f output_<job_id>.log
```

## 📈 扩展建议

### 1. 增加计算节点
```yaml
# 在docker-compose.yml中添加更多节点
cpn03:
  image: ubccr/hpcts:slurm-${HPCTS_VERSION}
  command: ["slurmd"]
  hostname: cpn03
  # ... 其他配置
```

### 2. 云端扩展
- 使用Aliyun E-HPC适配器连接云端资源
- 实现混合云计算架构

### 3. 性能优化
- 使用更高效的MPI通信模式
- 实现负载均衡算法
- 添加GPU支持

## 📝 总结

您的MPI Python脚本完全可以在当前环境中运行！主要步骤：

1. ✅ **环境准备** - 安装MPI支持
2. ✅ **脚本适配** - 添加容器环境兼容性
3. ✅ **作业提交** - 使用Slurm调度器
4. ✅ **结果获取** - 通过Web界面或命令行

整个过程大约需要10-15分钟的设置时间，之后就可以享受并行计算的强大能力了！
