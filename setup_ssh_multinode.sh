#!/bin/bash

# 配置SSH实现cpn01↔cpn02跨节点MPI通信
# 基于MPI_PERFORMANCE_TEST_REPORT.md的建议实施

set -e

echo "🔧 配置SSH实现真正跨节点MPI通信"
echo "=========================================="

# 获取节点IP地址
CPN01_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cpn01)
CPN02_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cpn02)

echo "📍 节点信息:"
echo "  cpn01: $CPN01_IP"
echo "  cpn02: $CPN02_IP"

# 1. 生成SSH密钥对（如果不存在）
echo ""
echo "🔑 步骤1: 配置SSH密钥认证"
echo "--------------------------------"

# 在cpn01上生成root用户的SSH密钥
docker exec cpn01 bash -c "
    if [ ! -f /root/.ssh/id_rsa ]; then
        mkdir -p /root/.ssh
        ssh-keygen -t rsa -b 2048 -f /root/.ssh/id_rsa -N '' -q
        echo '✅ cpn01: SSH密钥已生成'
    else
        echo '✅ cpn01: SSH密钥已存在'
    fi
"

# 在cpn02上生成root用户的SSH密钥
docker exec cpn02 bash -c "
    if [ ! -f /root/.ssh/id_rsa ]; then
        mkdir -p /root/.ssh
        ssh-keygen -t rsa -b 2048 -f /root/.ssh/id_rsa -N '' -q
        echo '✅ cpn02: SSH密钥已生成'
    else
        echo '✅ cpn02: SSH密钥已存在'
    fi
"

# 2. 配置SSH免密登录
echo ""
echo "🔐 步骤2: 配置免密登录"
echo "--------------------------------"

# 获取cpn01的公钥
CPN01_PUBKEY=$(docker exec cpn01 cat /root/.ssh/id_rsa.pub)
# 获取cpn02的公钥
CPN02_PUBKEY=$(docker exec cpn02 cat /root/.ssh/id_rsa.pub)

# 将cpn02的公钥添加到cpn01的authorized_keys
docker exec cpn01 bash -c "
    mkdir -p /root/.ssh
    echo '$CPN02_PUBKEY' >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    echo '✅ cpn01: 已添加cpn02公钥'
"

# 将cpn01的公钥添加到cpn02的authorized_keys
docker exec cpn02 bash -c "
    mkdir -p /root/.ssh
    echo '$CPN01_PUBKEY' >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    echo '✅ cpn02: 已添加cpn01公钥'
"

# 3. 配置SSH客户端设置
echo ""
echo "⚙️ 步骤3: 配置SSH客户端"
echo "--------------------------------"

# 在两个节点上配置SSH客户端设置
for node in cpn01 cpn02; do
    docker exec $node bash -c "
        cat > /root/.ssh/config << 'EOF'
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
    ConnectTimeout 10
EOF
        chmod 600 /root/.ssh/config
        echo '✅ $node: SSH客户端配置完成'
    "
done

# 4. 测试SSH连通性
echo ""
echo "🔍 步骤4: 测试SSH连通性"
echo "--------------------------------"

# 测试cpn01 -> cpn02
echo "测试 cpn01 -> cpn02:"
if docker exec cpn01 ssh root@$CPN02_IP hostname; then
    echo "✅ cpn01 -> cpn02: SSH连接成功"
else
    echo "❌ cpn01 -> cpn02: SSH连接失败"
    exit 1
fi

# 测试cpn02 -> cpn01
echo "测试 cpn02 -> cpn01:"
if docker exec cpn02 ssh root@$CPN01_IP hostname; then
    echo "✅ cpn02 -> cpn01: SSH连接成功"
else
    echo "❌ cpn02 -> cpn01: SSH连接失败"
    exit 1
fi

# 5. 创建MPI hostfile
echo ""
echo "📝 步骤5: 创建MPI hostfile"
echo "--------------------------------"

# 创建hostfile
cat > hostfile_multinode << EOF
$CPN01_IP slots=2
$CPN02_IP slots=2
EOF

echo "创建的hostfile内容:"
cat hostfile_multinode

# 将hostfile复制到两个节点
docker cp hostfile_multinode cpn01:/tmp/hostfile
docker cp hostfile_multinode cpn02:/tmp/hostfile

echo "✅ hostfile已复制到两个节点"

# 6. 验证MPI环境
echo ""
echo "🧪 步骤6: 验证MPI环境"
echo "--------------------------------"

for node in cpn01 cpn02; do
    echo "检查 $node 的MPI环境:"
    docker exec $node bash -c "
        export PATH=/usr/lib64/openmpi/bin:\$PATH
        which mpirun && mpirun --version | head -1
    "
done

echo ""
echo "🎉 SSH跨节点配置完成！"
echo "=========================================="
echo "✅ SSH密钥认证已配置"
echo "✅ 免密登录已启用"
echo "✅ MPI hostfile已创建"
echo "✅ 可以开始跨节点MPI测试"
echo ""
echo "下一步: 运行 ./run_multinode_mpi_test.sh 进行跨节点MPI测试"
