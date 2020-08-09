# Ansible

通过[ansible](https://www.ansible.com/)方式在一台或多台主机上部署 ES。

## 需求

Ansible 版本需为 **2.6** 以上，推荐 **2.9**。

## 使用

```bash
ansible-playbook -i hosts deploy.yml
```

### hosts

需要部署的主机列表，分为 **web** 和 **db**。

`web`会安装 Nginx:latest，PHP:7.1 和 ES 所需要的 PHP 扩展。

`db`在 Ubuntu:20.04 和 CentOS:8 中会安装 MySQL:8，其余发行版将会安装 MySQL:5.7。

### defaults

变量参数可在`defaults.yml`文件中修改，暂时只支持少量的自定义变量。

### db

MySQL 安装后需自行添加数据库及用户。

