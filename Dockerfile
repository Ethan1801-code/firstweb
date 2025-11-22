# 基于 Ubuntu 22.04 基础镜像（精简版，体积更小）
FROM ubuntu:22.04

# 关键1：避免 Ubuntu 交互式安装弹出窗口（必加）
ENV DEBIAN_FRONTEND=noninteractive
# 可选：设置时区（若代码需要时区一致性，可保留）
ENV TZ=Asia/Shanghai

# 关键2：创建非 root 用户（安全！禁止容器以 root 权限运行）
RUN useradd -m appuser

# 步骤1：安装系统依赖（python3 + pip3 + 必要工具）
# 补充 ca-certificates：确保 pip 安装第三方库时 HTTPS 连接正常
# 补充 tzdata：适配时区环境变量（可选，若不需要时区可删除）
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        ca-certificates \  # 关键补充：解决 pip 安装时 SSL 证书问题
        tzdata \
        && \
    # 清理 apt 缓存（减小镜像体积，Ubuntu 必做）
    rm -rf /var/lib/apt/lists/* && \
    # 配置时区（若删除 TZ 环境变量，可同时删除这行）
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 步骤2：设置工作目录（容器内代码存放路径）
WORKDIR /app

# 步骤3：复制项目文件到容器（关键！确保路径正确）
# 本地 forge 目录下的所有文件（包括 server.py、private.pem、requirements.txt）→ 容器 /app 目录
COPY forge/ /app/

# 步骤4：安装 Python 第三方依赖（flask、ecdsa 等，从 requirements.txt 读取）
# --no-cache-dir：不缓存 pip 安装包，减小镜像体积
RUN pip3 install --no-cache-dir -r requirements.txt

# 关键3：修改文件权限（给非 root 用户授权，避免 PermissionError）
# 确保 appuser 能读取 private.pem、运行 server.py
RUN chown -R appuser:appuser /app && \
    chmod 600 /app/private.pem  # 密钥文件限制只读权限（安全最佳实践）

# 切换到非 root 用户（关键！禁止 root 运行应用）
USER appuser

# 暴露端口（与 server.py 中 app.run(port=5000) 一致，不可修改）
EXPOSE 5000

# 容器启动命令（直接运行 server.py，路径正确）
CMD ["python3", "server.py"]
