# 基于 Ubuntu 22.04 基础镜像（精简版，体积更小）
FROM ubuntu:22.04

# 关键1：避免 Ubuntu 交互式安装弹出窗口（必加）
ENV DEBIAN_FRONTEND=noninteractive
# 可选：设置时区（若代码需要时区一致性，可保留）
ENV TZ=Asia/Shanghai
# 新增：设置 pip 国内源（加速依赖安装，避免超时）
ENV PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
ENV PIP_TRUSTED_HOST=pypi.tuna.tsinghua.edu.cn

# 关键2：创建非 root 用户（安全！禁止容器以 root 权限运行）
RUN useradd -m appuser

# 步骤1：安装系统依赖（python3 + pip3 + 必要工具）
# 补充 ca-certificates：确保 pip 安装时 HTTPS 连接正常
# 补充 tzdata：适配时区环境变量（可选，若不需要时区可删除）
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        ca-certificates \
        tzdata \
        && \
    # 清理 apt 缓存（减小镜像体积，Ubuntu 必做）
    rm -rf /var/lib/apt/lists/* && \
    # 配置时区（若删除 TZ 环境变量，可同时删除这行）
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 步骤2：设置工作目录（容器内代码存放路径）
WORKDIR /app

# 步骤3：复制项目文件到容器（路径正确，无需修改）
COPY forge/ /app/

# 步骤4：安装 Python 第三方依赖（已通过环境变量配置国内源）
RUN pip3 install --no-cache-dir -r requirements.txt

# 关键3：修改文件权限（避免 PermissionError，无需修改）
RUN chown -R appuser:appuser /app && \
    chmod 600 /app/private.pem

# 切换到非 root 用户（安全，无需修改）
USER appuser

# 暴露端口（与 server.py 一致，无需修改）
EXPOSE 5000

# 启动命令（路径正确，无需修改）
CMD ["python3", "server.py"]
