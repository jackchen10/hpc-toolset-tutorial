import subprocess
import sys
from colorama import init, Fore, Style

# 初始化colorama支持Windows颜色显示
init(autoreset=True)

def log_info(message):
    """打印紫色信息日志"""
    print(f"{Fore.MAGENTA}{message}{Style.RESET_ALL}")

def log_warn(message):
    """打印黄色警告日志"""
    print(f"{Fore.YELLOW}{message}{Style.RESET_ALL}")

def run_docker_command(cmd):
    """执行Docker命令并检查返回码"""
    try:
        result = subprocess.run(cmd, shell=True, check=True, text=True)
        return result.returncode
    except subprocess.CalledProcessError as e:
        log_warn(f"命令执行失败: {cmd}")
        log_warn(f"错误信息: {e.stderr}")
        sys.exit(1)

def start():
    """启动HPC Toolset集群"""
    log_info("Fetching latest HPC Toolset Images..")
    run_docker_command("docker compose pull")

    log_info("Starting HPC Toolset Cluster..")
    run_docker_command("docker compose up -d --no-build")

    log_info("Cluster URLs:")
    log_info(f"Coldfront:  https://localhost:2443")
    log_info(f"OnDemand:   https://localhost:3443")
    log_info(f"XDMoD:      https://localhost:4443")
    log_info(f"SSH登录:    ssh -p 6222 hpcadmin@localhost")

def stop():
    """停止集群容器"""
    log_info("Stopping HPC Toolset Cluster containers..")
    run_docker_command("docker compose stop")

def destroy():
    """销毁集群容器和卷"""
    log_info("Stopping and removing containers and volumes..")
    run_docker_command("docker compose stop")
    run_docker_command("docker compose rm -f -v")
    run_docker_command("docker compose down -v")

def cleanup():
    """清理所有相关镜像"""
    log_warn("**警告: 此操作将删除所有相关容器镜像，需要重新下载**")
    log_warn("建议先执行'destroy'命令")
    print("")
    
    yn = input("是否继续？(yes/no): ").strip().lower()
    if yn.startswith('y'):
        log_info("Removing containers and images...")
        destroy()
        # 获取所有匹配的镜像ID
        result = subprocess.run(
            'docker images -f "reference=ubccr/hpcts*" -q',
            shell=True,
            capture_output=True,
            text=True
        )
        if result.stdout:
            run_docker_command(f"docker rmi {result.stdout.strip()}")
        else:
            log_warn("未找到匹配的镜像")
    else:
        log_info("清理操作已取消")

def main():
    """主函数处理命令行参数"""
    if len(sys.argv) < 2:
        print(f"用法: {sys.argv[0]} {{start|stop|destroy|cleanup}}")
        sys.exit(1)

    command = sys.argv[1]
    commands = {
        'start': start,
        'stop': stop,
        'destroy': destroy,
        'cleanup': cleanup
    }

    if command in commands:
        commands[command]()
    else:
        print(f"未知命令: {command}")
        print(f"可用命令: start, stop, destroy, cleanup")
        sys.exit(1)

if __name__ == "__main__":
    main()