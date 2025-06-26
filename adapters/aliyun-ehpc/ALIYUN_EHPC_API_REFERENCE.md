# 阿里云 E-HPC REST API 接口完整说明

## 1. API 基础信息

### 1.1 基本信息

- **API 版本**: 2018-04-12 (当前稳定版本)
- **请求协议**: HTTPS
- **请求方法**: POST
- **数据格式**: JSON
- **字符编码**: UTF-8

### 1.2 接入地址

```
华东1（杭州）: https://ehpc.cn-hangzhou.aliyuncs.com
华东2（上海）: https://ehpc.cn-shanghai.aliyuncs.com
华北2（北京）: https://ehpc.cn-beijing.aliyuncs.com
华北3（张家口）: https://ehpc.cn-zhangjiakou.aliyuncs.com
华南1（深圳）: https://ehpc.cn-shenzhen.aliyuncs.com
西南1（成都）: https://ehpc.cn-chengdu.aliyuncs.com
```

### 1.3 认证方式

- **认证方法**: AccessKey 签名认证
- **签名算法**: HMAC-SHA1
- **签名版本**: 1.0

## 2. 集群管理 API

### 2.1 ListClusters - 查询集群列表

**功能**: 查询用户的集群列表

**请求参数**:

```json
{
  "Action": "ListClusters",
  "PageNumber": 1, // 可选，页码，默认1
  "PageSize": 10 // 可选，每页数量，默认10，最大100
}
```

**响应示例**:

```json
{
  "RequestId": "04F0F334-1335-436C-A1D7-6C044FE73368",
  "TotalCount": 2,
  "PageNumber": 1,
  "PageSize": 10,
  "Clusters": {
    "ClusterInfo": [
      {
        "Id": "ehpc-hz-FYUr32****",
        "RegionId": "cn-hangzhou",
        "ZoneId": "cn-hangzhou-b",
        "Name": "hpc-cluster-01",
        "Description": "HPC测试集群",
        "Status": "running",
        "OsTag": "CentOS_7.6_64",
        "AccountType": "nis",
        "SchedulerType": "pbs",
        "CreateTime": "2023-01-15T09:12:40Z",
        "NodeCount": 10,
        "LoginNodes": "192.168.1.10"
      }
    ]
  }
}
```

### 2.2 DescribeCluster - 查询集群详情

**功能**: 查询指定集群的详细信息

**请求参数**:

```json
{
  "Action": "DescribeCluster",
  "ClusterId": "ehpc-hz-FYUr32****" // 必需，集群ID
}
```

**响应示例**:

```json
{
  "RequestId": "04F0F334-1335-436C-A1D7-6C044FE73368",
  "ClusterInfo": {
    "Id": "ehpc-hz-FYUr32****",
    "Name": "hpc-cluster-01",
    "Description": "HPC测试集群",
    "Status": "running",
    "OsTag": "CentOS_7.6_64",
    "AccountType": "nis",
    "SchedulerType": "pbs",
    "EhpcVersion": "1.0.0",
    "CreateTime": "2023-01-15T09:12:40Z",
    "NodeCount": 10,
    "LoginNodes": "192.168.1.10",
    "ManagerNode": {
      "InstanceType": "ecs.c5.large",
      "InstanceId": "i-bp1234567890abcde"
    },
    "ComputeNodes": {
      "NodeInfo": [
        {
          "InstanceType": "ecs.c5.xlarge",
          "InstanceId": "i-bp1234567890abcdf",
          "Status": "running"
        }
      ]
    }
  }
}
```

### 2.3 CreateCluster - 创建集群

**功能**: 创建新的 E-HPC 集群

**请求参数**:

```json
{
  "Action": "CreateCluster",
  "Name": "my-hpc-cluster", // 必需，集群名称
  "Description": "我的HPC集群", // 可选，集群描述
  "EhpcVersion": "1.0.0", // 必需，E-HPC版本
  "OsTag": "CentOS_7.6_64", // 必需，操作系统
  "SchedulerType": "pbs", // 必需，调度器类型
  "AccountType": "nis", // 必需，账户类型
  "SecurityGroupId": "sg-bp1234****", // 必需，安全组ID
  "VSwitchId": "vsw-bp1234****", // 必需，交换机ID
  "VolumeType": "cloud_efficiency", // 必需，存储类型
  "VolumeSize": 40, // 必需，存储大小(GB)
  "ComputeInstanceType": "ecs.c5.large", // 必需，计算节点实例类型
  "ComputeCount": 2, // 必需，计算节点数量
  "LoginInstanceType": "ecs.c5.large", // 必需，登录节点实例类型
  "ManagerInstanceType": "ecs.c5.large" // 必需，管理节点实例类型
}
```

### 2.4 DeleteCluster - 删除集群

**功能**: 删除指定的集群

**请求参数**:

```json
{
  "Action": "DeleteCluster",
  "ClusterId": "ehpc-hz-FYUr32****", // 必需，集群ID
  "ReleaseInstance": "true" // 可选，是否释放实例，默认true
}
```

## 3. 作业管理 API

### 3.1 SubmitJob - 提交作业

**功能**: 向集群提交计算作业

**请求参数**:

```json
{
  "Action": "SubmitJob",
  "ClusterId": "ehpc-hz-FYUr32****", // 必需，集群ID
  "CommandLine": "echo 'Hello World'", // 必需，执行命令
  "RunasUser": "testuser", // 必需，执行用户
  "Name": "test-job", // 可选，作业名称
  "Priority": 0, // 可选，优先级，默认0
  "JobQueue": "workq", // 可选，队列名称
  "Node": 1, // 可选，节点数，默认1
  "Cpu": 1, // 可选，CPU核数，默认1
  "Task": 1, // 可选，任务数，默认1
  "Thread": 1, // 可选，线程数，默认1
  "Mem": "1GB", // 可选，内存大小
  "Gpu": 0, // 可选，GPU数量，默认0
  "ClockTime": "01:00:00", // 可选，运行时间限制
  "StdoutRedirectPath": "/home/user/stdout", // 可选，标准输出路径
  "StderrRedirectPath": "/home/user/stderr", // 可选，标准错误路径
  "ReRunable": false, // 可选，是否可重运行
  "Variables": "VAR1=value1,VAR2=value2", // 可选，环境变量
  "PackagePath": "/home/user/package", // 可选，软件包路径
  "InputFileUrl": "oss://bucket/input", // 可选，输入文件URL
  "PostCmdLine": "echo 'Job finished'" // 可选，后处理命令
}
```

**响应示例**:

```json
{
  "RequestId": "04F0F334-1335-436C-A1D7-6C044FE73368",
  "JobId": "0.manager"
}
```

### 3.2 ListJobs - 查询作业列表

**功能**: 查询集群中的作业列表

**请求参数**:

```json
{
  "Action": "ListJobs",
  "ClusterId": "ehpc-hz-FYUr32****", // 必需，集群ID
  "PageNumber": 1, // 可选，页码
  "PageSize": 10 // 可选，每页数量
}
```

**响应示例**:

```json
{
  "RequestId": "04F0F334-1335-436C-A1D7-6C044FE73368",
  "TotalCount": 5,
  "PageNumber": 1,
  "PageSize": 10,
  "Jobs": {
    "JobInfo": [
      {
        "Id": "0.manager",
        "Name": "test-job",
        "Owner": "testuser",
        "State": "Running",
        "SubmitTime": "2023-01-15T10:30:00Z",
        "StartTime": "2023-01-15T10:31:00Z",
        "LastModifyTime": "2023-01-15T10:31:00Z",
        "Priority": "0",
        "CommandLine": "echo 'Hello World'",
        "JobQueue": "workq",
        "Node": "1",
        "Cpu": "1",
        "Mem": "1GB",
        "ClockTime": "01:00:00"
      }
    ]
  }
}
```

### 3.3 DescribeJob - 查询作业详情

**功能**: 查询指定作业的详细信息

**请求参数**:

```json
{
  "Action": "DescribeJob",
  "ClusterId": "ehpc-hz-FYUr32****", // 必需，集群ID
  "JobId": "0.manager" // 必需，作业ID
}
```

### 3.4 DeleteJobs - 删除作业

**功能**: 删除一个或多个作业

**请求参数**:

```json
{
  "Action": "DeleteJobs",
  "ClusterId": "ehpc-hz-FYUr32****", // 必需，集群ID
  "Jobs": "0.manager,1.manager" // 必需，作业ID列表，逗号分隔
}
```

## 4. 用户管理 API

### 4.1 ListUsers - 查询用户列表

**功能**: 查询集群中的用户列表

**请求参数**:

```json
{
  "Action": "ListUsers",
  "ClusterId": "ehpc-hz-FYUr32****", // 必需，集群ID
  "PageNumber": 1, // 可选，页码
  "PageSize": 10 // 可选，每页数量
}
```

### 4.2 AddUsers - 添加用户

**功能**: 向集群添加用户

**请求参数**:

```json
{
  "Action": "AddUsers",
  "ClusterId": "ehpc-hz-FYUr32****", // 必需，集群ID
  "User": [
    {
      "Name": "testuser", // 必需，用户名
      "Password": "password123", // 必需，密码
      "Group": "users" // 可选，用户组
    }
  ]
}
```

### 4.3 DeleteUsers - 删除用户

**功能**: 从集群删除用户

**请求参数**:

```json
{
  "Action": "DeleteUsers",
  "ClusterId": "ehpc-hz-FYUr32****", // 必需，集群ID
  "User": [
    {
      "Name": "testuser" // 必需，用户名
    }
  ]
}
```

## 5. 队列管理 API

### 5.1 ListQueues - 查询队列列表

**功能**: 查询集群中的队列列表

**请求参数**:

```json
{
  "Action": "ListQueues",
  "ClusterId": "ehpc-hz-FYUr32****" // 必需，集群ID
}
```

**响应示例**:

```json
{
  "RequestId": "04F0F334-1335-436C-A1D7-6C044FE73368",
  "Queues": {
    "QueueInfo": [
      {
        "QueueName": "workq",
        "Type": "route",
        "State": "enabled",
        "MaxJobs": 100,
        "ComputeNodes": ["compute001", "compute002"]
      }
    ]
  }
}
```

### 5.2 CreateJobQueue - 创建作业队列

**功能**: 创建新的作业队列

**请求参数**:

```json
{
  "Action": "CreateJobQueue",
  "ClusterId": "ehpc-hz-FYUr32****", // 必需，集群ID
  "QueueName": "gpu-queue" // 必需，队列名称
}
```

## 6. 镜像和价格查询 API

### 6.1 ListImages - 查询支持的镜像

**功能**: 查询 E-HPC 支持的操作系统镜像

**请求参数**:

```json
{
  "Action": "ListImages",
  "BaseOsTag": "CentOS" // 可选，操作系统类型过滤
}
```

### 6.2 DescribePrice - 查询价格

**功能**: 查询集群或实例的价格信息

**请求参数**:

```json
{
  "Action": "DescribePrice",
  "PriceUnit": "Hour", // 必需，计费单位
  "ChargeType": "PostPaid", // 必需，付费类型
  "InstanceType": "ecs.c5.large", // 可选，实例类型
  "Period": 1 // 可选，计费周期
}
```

## 7. 作业状态说明

### 7.1 作业状态枚举

```
- Queued: 排队中
- Running: 运行中
- Completed: 已完成
- Failed: 失败
- Cancelled: 已取消
- Suspended: 已暂停
- Held: 保持状态
```

### 7.2 集群状态枚举

```
- creating: 创建中
- running: 运行中
- exception: 异常
- releasing: 释放中
- stopped: 已停止
- deleted: 已删除
```

## 8. 错误码说明

### 8.1 常见错误码

```
- InvalidAccessKeyId.NotFound: AccessKey不存在
- Forbidden.SubUser: 子账号权限不足
- InvalidClusterId.NotFound: 集群不存在
- InvalidJobId.NotFound: 作业不存在
- Throttling: 请求频率过高
- InternalError: 内部错误
- InvalidParameter: 参数错误
- QuotaExceeded: 配额超限
```

## 9. 高级功能 API

### 9.1 GetJobLog - 获取作业日志

**功能**: 获取作业的执行日志

**请求参数**:

```json
{
  "Action": "GetJobLog",
  "ClusterId": "ehpc-hz-FYUr32****", // 必需，集群ID
  "JobId": "0.manager", // 必需，作业ID
  "LogType": "stdout" // 可选，日志类型: stdout/stderr
}
```

**响应示例**:

```json
{
  "RequestId": "04F0F334-1335-436C-A1D7-6C044FE73368",
  "LogContent": "Hello World\nJob execution completed successfully\n"
}
```

### 9.2 ModifyClusterAttributes - 修改集群属性

**功能**: 修改集群的基本属性

**请求参数**:

```json
{
  "Action": "ModifyClusterAttributes",
  "ClusterId": "ehpc-hz-FYUr32****", // 必需，集群ID
  "Name": "new-cluster-name", // 可选，新集群名称
  "Description": "新的集群描述" // 可选，新集群描述
}
```

### 9.3 ListClusterLogs - 查询集群日志

**功能**: 查询集群的操作日志

**请求参数**:

```json
{
  "Action": "ListClusterLogs",
  "ClusterId": "ehpc-hz-FYUr32****", // 必需，集群ID
  "PageNumber": 1, // 可选，页码
  "PageSize": 10 // 可选，每页数量
}
```

### 9.4 AddNodes - 添加计算节点

**功能**: 向集群添加计算节点

**请求参数**:

```json
{
  "Action": "AddNodes",
  "ClusterId": "ehpc-hz-FYUr32****", // 必需，集群ID
  "Count": 2, // 必需，节点数量
  "InstanceType": "ecs.c5.xlarge", // 必需，实例类型
  "ImageId": "centos_7_06_64_20G_alibase_20190711.vhd" // 可选，镜像ID
}
```

### 9.5 DeleteNodes - 删除计算节点

**功能**: 从集群删除计算节点

**请求参数**:

```json
{
  "Action": "DeleteNodes",
  "ClusterId": "ehpc-hz-FYUr32****", // 必需，集群ID
  "Instance": [
    {
      "Id": "i-bp1234567890abcde" // 必需，实例ID
    }
  ],
  "ReleaseInstance": true // 可选，是否释放实例
}
```

## 10. 文件传输 API

### 10.1 ListFileSystemWithMountTargets - 查询文件系统

**功能**: 查询集群关联的文件系统

**请求参数**:

```json
{
  "Action": "ListFileSystemWithMountTargets",
  "PageNumber": 1, // 可选，页码
  "PageSize": 10 // 可选，每页数量
}
```

### 10.2 CreateJobTemplate - 创建作业模板

**功能**: 创建可重复使用的作业模板

**请求参数**:

```json
{
  "Action": "CreateJobTemplate",
  "Name": "my-job-template", // 必需，模板名称
  "CommandLine": "echo 'Template Job'", // 必需，执行命令
  "RunasUser": "testuser", // 必需，执行用户
  "Priority": 0, // 可选，优先级
  "JobQueue": "workq", // 可选，队列名称
  "Node": 1, // 可选，节点数
  "Cpu": 1, // 可选，CPU核数
  "Mem": "1GB", // 可选，内存大小
  "ClockTime": "01:00:00" // 可选，运行时间限制
}
```

### 10.3 ListJobTemplates - 查询作业模板

**功能**: 查询用户的作业模板列表

**请求参数**:

```json
{
  "Action": "ListJobTemplates",
  "PageNumber": 1, // 可选，页码
  "PageSize": 10 // 可选，每页数量
}
```

## 11. 监控和统计 API

### 11.1 DescribeClusterMetrics - 查询集群监控指标

**功能**: 查询集群的性能监控指标

**请求参数**:

```json
{
  "Action": "DescribeClusterMetrics",
  "ClusterId": "ehpc-hz-FYUr32****", // 必需，集群ID
  "MetricName": "cpu_utilization", // 必需，指标名称
  "StartTime": "2023-01-15T00:00:00Z", // 必需，开始时间
  "EndTime": "2023-01-15T23:59:59Z" // 必需，结束时间
}
```

### 11.2 ListJobMetrics - 查询作业监控指标

**功能**: 查询作业的性能监控指标

**请求参数**:

```json
{
  "Action": "ListJobMetrics",
  "ClusterId": "ehpc-hz-FYUr32****", // 必需，集群ID
  "JobId": "0.manager", // 必需，作业ID
  "MetricName": "memory_usage" // 必需，指标名称
}
```

## 12. 安全和权限 API

### 12.1 ListSecurityGroups - 查询安全组

**功能**: 查询可用的安全组列表

**请求参数**:

```json
{
  "Action": "ListSecurityGroups",
  "PageNumber": 1, // 可选，页码
  "PageSize": 10 // 可选，每页数量
}
```

### 12.2 ModifyUserGroups - 修改用户组

**功能**: 修改用户的组权限

**请求参数**:

```json
{
  "Action": "ModifyUserGroups",
  "ClusterId": "ehpc-hz-FYUr32****", // 必需，集群ID
  "User": [
    {
      "Name": "testuser", // 必需，用户名
      "Group": "admin" // 必需，新用户组
    }
  ]
}
```

## 13. API 调用示例

### 13.1 完整的 API 调用流程

```bash
# 1. 设置基本参数
ENDPOINT="https://ehpc.cn-hangzhou.aliyuncs.com"
ACCESS_KEY_ID="your_access_key_id"
ACCESS_KEY_SECRET="your_access_key_secret"

# 2. 构造请求参数
ACTION="ListClusters"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
NONCE=$(uuidgen)

# 3. 生成签名
# (具体签名算法见认证文档)

# 4. 发送请求
curl -X POST "$ENDPOINT" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "Action=$ACTION&AccessKeyId=$ACCESS_KEY_ID&Timestamp=$TIMESTAMP&..."
```

### 13.2 Ruby 调用示例

```ruby
require 'net/http'
require 'openssl'
require 'base64'
require 'json'

# 创建E-HPC客户端
client = AliyunEhpc::Client.new(
  access_key_id: 'your_access_key_id',
  access_key_secret: 'your_access_key_secret',
  region: 'cn-hangzhou'
)

# 查询集群列表
clusters = client.clusters.list(page_size: 20)

# 提交作业
job = client.jobs.submit('ehpc-hz-FYUr32****', {
  command_line: 'echo "Hello E-HPC"',
  runas_user: 'testuser',
  name: 'test-job',
  node: 1,
  cpu: 2,
  mem: '2GB',
  clock_time: '00:30:00'
})

# 查询作业状态
job_info = client.jobs.describe('ehpc-hz-FYUr32****', job.id)
puts "Job Status: #{job_info.state}"
```

## 14. 最佳实践建议

### 14.1 API 调用频率控制

- **建议频率**: 每秒不超过 20 次 API 调用
- **突发处理**: 使用指数退避算法处理限流
- **批量操作**: 优先使用批量 API 减少调用次数

### 14.2 错误处理策略

- **网络错误**: 实现自动重试机制（最多 3 次）
- **认证错误**: 检查 AccessKey 配置和权限
- **参数错误**: 验证请求参数的完整性和格式

### 14.3 性能优化建议

- **连接复用**: 使用 HTTP 连接池
- **并发控制**: 合理控制并发请求数量
- **缓存策略**: 缓存不经常变化的数据（如集群信息）

这份完整的 API 参考文档为阿里云 E-HPC 的 Ruby 适配器实现提供了详尽的接口规范和使用指南。
