FROM codercom/code-server:ubuntu

USER root

# 创建插件目录
RUN mkdir -p /home/coder/extensions

# 复制本地的Claude插件到容器中
COPY claude-dev-3.7.1.vsix /home/coder/extensions/

# 切换回coder用户
USER coder

# 安装Claude插件
RUN code-server --install-extension /home/coder/extensions/claude-dev-3.7.1.vsix

# 从市场安装Live Preview插件
RUN code-server --install-extension ms-vscode.live-server

# 默认工作目录
WORKDIR /home/coder/project

# 暴露默认端口
EXPOSE 8080

# 启动code-server
CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "none", "."] 
