# Code Server 预装插件镜像

基于 `codercom/code-server:ubuntu` 的 Docker 镜像，预装了以下 VS Code 扩展:

- Claude AI 扩展 (claude-dev-3.7.1)
- Live Preview 扩展 (ms-vscode.live-server)

## 特性

- 支持多架构: 同时支持 x86_64/amd64 和 ARM64 平台
- 预装扩展: 内置 Claude AI 和 Live Preview 扩展
- 无需认证: 默认配置为无需密码即可访问

## 使用方法

### 拉取并运行镜像

```bash
# 拉取镜像
docker pull ghcr.io/yjq001/code-server:latest

# 运行容器
docker run -d --name code-server -p 8080:8080 -v "$(pwd):/home/coder/project" ghcr.io/yjq001/code-server:latest
```

访问 `http://localhost:8080` 即可使用 Code Server。

### 本地构建镜像

1. 将 Claude 扩展文件 `claude-dev-3.7.1.vsix` 放在仓库根目录
2. 构建镜像:

```bash
docker build -t code-server:custom .
```

3. 运行本地构建的镜像:

```bash
docker run -d --name code-server -p 8080:8080 -v "$(pwd):/home/coder/project" code-server:custom
```

## 自定义构建

如果需要自行构建镜像，请确保:

1. 将 Claude 扩展文件 `claude-dev-3.7.1.vsix` 放在仓库根目录
2. 运行构建命令:

```bash
docker build -t code-server:custom .
```

## 环境变量

可以通过环境变量自定义 Code Server:

- `PASSWORD`: 设置访问密码
- `HASHED_PASSWORD`: 设置哈希后的密码
- `PORT`: 修改内部端口 (默认 8080)

例如:

```bash
docker run -d -p 8080:8080 -e PASSWORD=your_password ghcr.io/yjq001/code-server:latest
```
