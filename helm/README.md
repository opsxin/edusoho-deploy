# Kubernetes

使用[Helm 3](https://helm.sh/)在[kubernetes](https://kubernetes.io/zh/)上部署 ES。

## 使用

### 下载 MySQL 依赖

```bash
helm dependency build ${Helm_Teamplate_Directory}
# helm dependency build ./edusoho
```

### 启动

```bash
helm install ${name} ${Helm_Teamplate_Directory}
# helm install tmp1 ./edusoho
```
