FROM codercom/code-server:ubuntu

USER root

# 创建插件目录
RUN mkdir -p /home/coder/extensions

# 复制本地的Claude插件到容器中
COPY claude.vsix /home/coder/extensions/

# 创建配置目录
RUN mkdir -p /home/coder/.config/code-server

# 创建配置文件
RUN echo "bind-addr: 0.0.0.0:8080\nauth: none\ncert: false" > /home/coder/.config/code-server/config.yaml

# 确保目录所有权正确
RUN chown -R coder:coder /home/coder/.config

# 切换回coder用户
USER coder

# 安装Claude插件
RUN code-server --install-extension /home/coder/extensions/claude.vsix

# 从市场安装Live Preview插件
RUN code-server --install-extension ms-vscode.live-server

# 默认工作目录
WORKDIR /home/coder/project

# 暴露默认端口
EXPOSE 8080

# 启动code-server，使用配置文件中的设置
CMD ["code-server", "."] 
