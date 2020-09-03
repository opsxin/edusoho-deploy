# Docker Comose

通过[docker-compose](https://docs.docker.com/compose/)运行多个[docker](https://www.docker.com/)容器的方式部署 ES。

## 使用

```bash
docker-compose up -d
```

无需其他任何操作，访问`http://Host_IP:80`即可。

## 注意

- ES 安装向导中，数据库服务器需填写 **db**，即 docker-compose 文件中 MySQL 的 Service 名。
- 数据库用户，密码等在`.env`文件中定义。
