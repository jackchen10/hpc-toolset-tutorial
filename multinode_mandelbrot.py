#!/usr/bin/env python3
"""
跨节点MPI Mandelbrot集合计算
支持真正的多节点并行计算
"""

from mpi4py import MPI
import numpy as np
import time
import socket
import os

def mandelbrot_point(c, max_iter=100):
    """计算单个点的Mandelbrot值"""
    z = 0
    for n in range(max_iter):
        if abs(z) > 2:
            return n
        z = z*z + c
    return max_iter

def mandelbrot_chunk(xmin, xmax, ymin, ymax, width, height, max_iter=100):
    """计算Mandelbrot集合的一个区块"""
    result = np.zeros((height, width))
    
    for i in range(height):
        for j in range(width):
            # 将像素坐标转换为复数
            x = xmin + (xmax - xmin) * j / (width - 1)
            y = ymin + (ymax - ymin) * i / (height - 1)
            c = complex(x, y)
            result[i, j] = mandelbrot_point(c, max_iter)
    
    return result

def main():
    # 初始化MPI
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()
    
    # 获取节点信息
    hostname = socket.gethostname()
    
    # Mandelbrot参数
    width, height = 800, 600
    xmin, xmax = -2.5, 1.5
    ymin, ymax = -1.5, 1.5
    max_iter = 100
    
    if rank == 0:
        print(f"🔬 跨节点MPI Mandelbrot计算")
        print(f"总进程数: {size}")
        print(f"图像尺寸: {width}x{height}")
        print(f"最大迭代: {max_iter}")
        print("-" * 50)
    
    # 计算每个进程负责的行数
    rows_per_process = height // size
    start_row = rank * rows_per_process
    end_row = start_row + rows_per_process
    
    # 最后一个进程处理剩余的行
    if rank == size - 1:
        end_row = height
    
    actual_height = end_row - start_row
    
    print(f"Rank {rank} ({hostname}): 处理行 {start_row}-{end_row-1} ({actual_height}行)")
    
    # 开始计算
    start_time = time.time()
    
    # 计算分配给当前进程的区块
    local_result = mandelbrot_chunk(
        xmin, xmax, 
        ymin + (ymax - ymin) * start_row / height,
        ymin + (ymax - ymin) * end_row / height,
        width, actual_height, max_iter
    )
    
    compute_time = time.time() - start_time
    
    # 收集所有进程的结果
    if rank == 0:
        # 主进程收集所有结果
        full_result = np.zeros((height, width))
        full_result[start_row:end_row, :] = local_result
        
        for i in range(1, size):
            # 接收其他进程的数据
            other_start = i * rows_per_process
            other_end = other_start + rows_per_process
            if i == size - 1:
                other_end = height
            
            other_height = other_end - other_start
            other_result = np.zeros((other_height, width))
            comm.Recv(other_result, source=i, tag=i)
            full_result[other_start:other_end, :] = other_result
        
        total_time = time.time() - start_time
        
        # 保存结果
        try:
            import matplotlib.pyplot as plt
            plt.figure(figsize=(12, 9))
            plt.imshow(full_result, extent=[xmin, xmax, ymin, ymax], 
                      cmap='hot', origin='lower')
            plt.colorbar(label='Iterations')
            plt.title(f'跨节点MPI Mandelbrot集合 ({size}进程)')
            plt.xlabel('Real')
            plt.ylabel('Imaginary')
            plt.savefig('/tmp/multinode_mandelbrot.png', dpi=150, bbox_inches='tight')
            print(f"✅ 图像已保存: /tmp/multinode_mandelbrot.png")
        except ImportError:
            print("⚠️ matplotlib未安装，跳过图像保存")
        
        # 性能统计
        total_pixels = width * height
        pixels_per_second = total_pixels / total_time
        
        print("\n" + "="*60)
        print("🏆 跨节点MPI性能测试结果")
        print("="*60)
        print(f"总计算时间: {total_time:.3f} 秒")
        print(f"总像素数量: {total_pixels:,}")
        print(f"处理速度: {pixels_per_second:,.0f} 像素/秒")
        print(f"并行效率: {size}进程跨节点计算")
        
    else:
        # 其他进程发送结果给主进程
        comm.Send(local_result, dest=0, tag=rank)
    
    # 所有进程报告自己的性能
    comm.Barrier()
    
    local_pixels = actual_height * width
    local_speed = local_pixels / compute_time
    
    print(f"Rank {rank} ({hostname}): {compute_time:.3f}秒, "
          f"{local_pixels:,}像素, {local_speed:,.0f}像素/秒")
    
    if rank == 0:
        print("="*60)

if __name__ == "__main__":
    main()
