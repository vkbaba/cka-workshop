まずはNamespace を作成しましょう。
```execute
kubectl create ns question4
```
以降は指示通り各リソースを作成していくのですが、その前にKubernetes のRBAC について簡単におさらいしましょう。

Kubernetes においては、2つのユーザータイプが存在します。`ServiceAccount` と呼ばれるKubernetes のリソースと、通常のユーザーアカウントです。ServiceAccount はKubernetes のPod が使用するアカウントで、Pod にアタッチすることで、Pod が誰なのかを示し、利用できるKubernetes API を制限します。一方でユーザーアカウントは、我々人間が使用するアカウントで、具体的に言うとkubeconfig ファイルに記載されているユーザーなのですが、Kubernetes に対してアクセスをする際に提示することで、ユーザーがアクセスできるリソースを制御します。  

今回はServiceAccount、すなわちPod が使用するアカウントに対するRBAC の設定を通して、実際にPod がアクセスできるリソースを制御します。

アクセスを制御するためには、アクセス権を定義する`ClusterRole` / `Role` リソースと、アカウントと紐づける `ClusterRoleBinding` / `RoleBinding` を使います。頭にCluster とついているものはクラスタで定義されるリソースで、ついていないものはNamespaced な、名前空間の中で定義されるリソースになります。例えば、ClusterRole とClusterRoleBinding を用いることで、クラスタ内の全ての名前空間のリソースに対してClusterRole に基づきアクセス許可を与えます。また、ClusterRole とRoleBinding を用いることで、特定の名前空間の中のリソースに対してClusterRole に基づきアクセス許可を与えます。名前空間ごとにRole を作成し、RoleBinding で紐づけてもよいですが、ClusterRole を使うことで、様々な名前空間に対して1 つのアクセス権定義を使いまわせるというメリットがあります。

//絵

それではServiceAccount を作成しましょう。マニフェストファイルから作成してもよいですが、ServiceAccount は引数が少なくて済むため、kubectl create コマンドで作る方が楽です。
```execute
kubectl -n question4 create sa q4-sa
```
📝ヒント：  
https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/

次にClusterRole を作成します。ドキュメントからコピペしてマニフェストファイルを作成してもよいですが、kubectl create コマンドでも作成することができます。
```execute
kubectl create clusterrole q4-clusterrole --verb=get --resource=secret --resource=configmap
```
参考までに、ClusterRole のマニフェストは下記の通りです。
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: q4-clusterrole
  namespace: question4
rules:
- apiGroups: [""] 
  resources: ["configmaps", "secrets"]
  verbs: ["get"]
```
最後にRoleBinding を作成します。こちらも同様にドキュメントからコピペしてマニフェストを作成してもよいですが、kubectl create コマンドでも作成することができます。
```execute
kubectl -n question4 create rolebinding q4-rolebinding --clusterrole q4-clusterrole --serviceaccount question4:q4-sa
```
参考までに、RoleBinding のマニフェストは下記の通りです。
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: q4-rolebinding
  namespace: question4
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: q4-clusterrole
subjects:
- kind: ServiceAccount
  name: q4-sa
  namespace: question4
```
それでは最後に実際にアクセス制御が達成されているかを確かめてみましょう。
```execute
kubectl apply -f ~/q4/rbac-test.yaml
```
Configmap はGet できるはずです。
```execute
kubectl exec -it -n question4 nginx-rbac -- sh
curl -k -H "Authorization: Bearer $(cat /run/secrets/kubernetes.io/serviceaccount/token)"  https://kubernetes.default/api/v1/namespaces/question4/configmaps/test-configmap 
exit
```
Secret もGet できるはずです。
```execute
kubectl exec -it -n question4 nginx-rbac -- sh
curl -k -H "Authorization: Bearer $(cat /run/secrets/kubernetes.io/serviceaccount/token)"  https://kubernetes.default/api/v1/namespaces/question4/secrets/test-secret
exit
```
Pod はGet できません。
```execute
kubectl exec -it -n question4 nginx-rbac -- sh
curl -k -H "Authorization: Bearer $(cat /run/secrets/kubernetes.io/serviceaccount/token)"  https://kubernetes.default/api/v1/namespaces/question4/pods/nginx-rbac
exit
```
📝ヒント：  
https://kubernetes.io/docs/ja/tasks/administer-cluster/access-cluster-api/  

Pod を作成しなくても、実は `kubectl auth` でリソースにアクセスできるかどうかを確認することができます。  

例えば下記の出力がyes の場合、そのリソースの操作(Configmap のGet)ができます。
```
kubectl -n question4 auth can-i get configmap --as system:serviceaccount:question4:q4-sa
```
no と表示されればリソースの操作(Configmap のCreate)ができません。
```
kubectl -n question4 auth can-i create configmap --as system:serviceaccount:question4:q4-sa
```



