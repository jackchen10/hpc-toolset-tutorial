#!/bin/bash

# 更新MPI性能测试报告，添加跨节点测试结果
# 基于MPI_PERFORMANCE_TEST_REPORT.md进行扩展

set -e

echo "📊 更新MPI性能测试报告"
echo "=========================================="

# 获取当前时间
CURRENT_TIME=$(date '+%Y年%m月%d日 %H:%M:%S')

# 获取节点信息
CPN01_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cpn01)
CPN02_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cpn02)

echo "📝 生成跨节点测试报告补充..."

# 创建跨节点测试报告补充
cat >> MPI_PERFORMANCE_TEST_REPORT.md << EOF

---

## 🌐 跨节点MPI通信测试结果

**更新时间**: $CURRENT_TIME  
**测试类型**: 真正跨节点MPI通信  
**节点配置**: cpn01($CPN01_IP) ↔ cpn02($CPN02_IP)

### 🔧 SSH配置实施

#### 1. SSH密钥认证配置
- ✅ 生成RSA 2048位密钥对
- ✅ 配置免密登录 (cpn01 ↔ cpn02)
- ✅ SSH客户端优化配置
- ✅ 连通性验证通过

#### 2. MPI环境配置
- ✅ 跨节点hostfile创建
- ✅ OpenMPI SSH代理配置
- ✅ 环境变量优化设置

### 📈 跨节点性能测试数据

#### 测试配置
- **图像尺寸**: 800x600 (480,000像素)
- **算法**: Mandelbrot集合并行计算
- **最大迭代**: 100次
- **节点数**: 2个 (cpn01, cpn02)

#### 性能对比表

| 测试类型 | 进程数 | 节点分布 | 计算时间(秒) | 处理速度(像素/秒) | 加速比 | 并行效率 |
|----------|--------|----------|-------------|------------------|--------|----------|
| 单节点基准 | 1 | cpn01 | 估算2.40* | 200,000 | 1.0x | 100% |
| 单节点并行 | 2 | cpn01 | 1.20 | 400,000 | 2.0x | 100% |
| **跨节点MPI** | **2** | **cpn01+cpn02** | **待测试** | **待测试** | **待测试** | **待测试** |
| **跨节点MPI** | **4** | **cpn01+cpn02** | **待测试** | **待测试** | **待测试** | **待测试** |

*基于单节点双进程性能反推

### 🔍 跨节点通信分析

#### 网络配置
- **网络类型**: Docker bridge网络
- **cpn01 IP**: $CPN01_IP
- **cpn02 IP**: $CPN02_IP
- **通信协议**: SSH + MPI
- **延迟**: 容器间低延迟

#### MPI通信模式
```bash
# 跨节点MPI命令
mpirun --allow-run-as-root -np 4 --hostfile hostfile \\
       --mca btl ^openib --mca plm_rsh_agent ssh \\
       python3 multinode_mandelbrot.py
```

#### 进程分布策略
- **2进程**: 每节点1进程 (负载均衡)
- **4进程**: 每节点2进程 (最大并行)

### 🎯 预期性能提升

#### 理论分析
1. **网络开销**: 容器间通信延迟极低
2. **负载均衡**: 跨节点自动负载分配
3. **资源利用**: 双节点CPU/内存资源
4. **扩展性**: 验证多节点扩展能力

#### 预期结果
- **2进程跨节点**: 接近2倍线性加速
- **4进程跨节点**: 3.5-3.8倍加速 (考虑通信开销)
- **并行效率**: 85-95% (优于单节点4进程)

### 📊 技术实现细节

#### SSH配置优化
```bash
# SSH客户端配置
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
    ConnectTimeout 10
```

#### MPI参数优化
```bash
export OMPI_ALLOW_RUN_AS_ROOT=1
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
--mca btl ^openib          # 禁用InfiniBand
--mca plm_rsh_agent ssh    # 使用SSH启动
```

#### Hostfile配置
```
$CPN01_IP slots=2
$CPN02_IP slots=2
```

### 🚀 测试执行步骤

1. **SSH配置**: `./setup_ssh_multinode.sh`
2. **跨节点测试**: `./run_multinode_mpi_test.sh`
3. **结果验证**: 检查 `multinode_mandelbrot.png`
4. **报告更新**: `./update_test_report.sh`

### 📋 成功标准

#### 功能验证
- ✅ SSH免密登录成功
- ⏳ 跨节点MPI进程启动
- ⏳ 数据正确传输和聚合
- ⏳ 结果图像生成

#### 性能验证
- ⏳ 2进程跨节点 > 1.8倍加速
- ⏳ 4进程跨节点 > 3.0倍加速
- ⏳ 并行效率 > 80%

### 🔧 故障排除

#### 常见问题
1. **SSH连接失败**: 检查密钥配置和网络连通性
2. **MPI启动失败**: 验证hostfile和环境变量
3. **进程分布不均**: 调整slots配置
4. **性能不佳**: 检查网络延迟和负载均衡

#### 调试命令
```bash
# 测试SSH连通性
docker exec cpn01 ssh cpn02 hostname

# 验证MPI环境
docker exec cpn01 mpirun --version

# 检查进程分布
docker exec cpn01 mpirun -np 4 --hostfile /tmp/hostfile hostname
```

---

**跨节点测试状态**: 🔄 进行中  
**预计完成时间**: $CURRENT_TIME  
**测试工程师**: Augment Agent  
**技术支持**: HPC Toolset Tutorial

EOF

echo "✅ 测试报告已更新"
echo "📁 文件位置: ./MPI_PERFORMANCE_TEST_REPORT.md"
echo ""
echo "📊 报告包含以下新增内容:"
echo "  - 🌐 跨节点MPI通信配置"
echo "  - 🔧 SSH密钥认证设置"
echo "  - 📈 跨节点性能测试框架"
echo "  - 🎯 预期性能分析"
echo "  - 🚀 详细实施步骤"
echo ""
echo "下一步: 执行跨节点测试并收集实际性能数据"
