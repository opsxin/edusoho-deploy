# Kubernetes

在[kubernetes](https://kubernetes.io/zh/)上部署 ES。

## 使用

未使用持久卷（pv）：

```bash
kubectl apple -f edusoho
```

使用持久卷（pv）：

```bash
kubectl apple -f edusoho-pvc
```

## 访问

Nginx 的服务类型默认为`NodePort`。

获取 Port：

```bash
kubectl get svc -n edusoho
```

找到`nginx-svc`行，与其对应的`Port`列，即可找到 Port。如`80:32659/TCP`，则 Port 为 32659。

访问`http://NodeIP:Port`即可。

## 注意

- 默认 Namespace 为 edusoho，edusoho 和 edusoho-pvc 不能同时部署。
- 持久卷容量请按需修改，此处只分配了 1G 空间。
- edusoho-pvc 会部署 Ingress-nginx 的访问方式，如果不需要，通过`kubectl delete -f edusoho-pvc/edusoho-ingress.yml`删除。

