此目录存放个人开发docker镜像配置。

dockerfile 使用方式, 使用docker build构建镜像:

```dockerfile
docker buildx build --platform=[platform] -t [name]:[version] .
```
- platform: linux/amd64 或者 linux/arm64 , 或这两个同时构建，用逗号分割

启动docker容器：

```shell
docker run -v`pwd`:`pwd` --name dev -d -p 2222:22 -it fa6a94ee30d1 bash -c "sudo service ssh restart && tail -f /dev/null"

docker exec -it dev /bin/bash
```

在vscode中使用: 
```
ssh -p 2222 dev@127.0.0.1
```
连接

refs:
- https://www.cnblogs.com/stearsc/p/16792282.html
- https://midoq.github.io/2022/05/30/Ubuntu20-04%E6%9B%B4%E6%8D%A2%E5%9B%BD%E5%86%85%E9%95%9C%E5%83%8F%E6%BA%90/
- https://grauneko.com/index.php/archives/64/
