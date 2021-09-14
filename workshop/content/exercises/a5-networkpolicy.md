まずはNamespace を作成しましょう。
```execute
kubectl create ns question5
```

CKA/CKAD/CKS いずれの試験範囲にも含まれ、点数配分も高く、かつ問題自体も難しいのが `NetworkPolicy` です。クラスタの中で通信を正しく制御できているかが分かりづらく、確認のために疎通テストをするのにも時間がかかり、マニフェスト自体も取っつきにくい書き方のため、苦手としている人も多いのではないでしょうか。しかしながら、事前に対策をすれば大きな得点源となるため、特に時間をかけて勉強する価値があるトピックです。  

NetwotkPolicy はKubernetes におけるファイアウォールであり、Pod の通信を制御します。名前空間にNetwotkPolicy が存在しない場合は全ての通信は許可されていますが、例えばデフォルトで全てのトラフィックを拒否し、許可する通信に絞って穴を空けていくホワイトリスト方式により、不要な通信を確実にブロックすることができます。  

今回の問題はこのようなホワイトリスト方式でのポリシー制御ですので、まずはデフォルトで全ての通信をブロックするNetworkPolicy を作成します。これはKubernetes のドキュメントからコピペすることができます。

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```
さて、マニフェストをよく見てみましょう。`podSelector` というのはその名の通りどのPod を対象とするかであり、{ } は全てのPod を対象とするという意味ですが、NetworkPolicy はクラスタ全体で定義されるリソースではなく、Namespaced なリソースということに注意してください。

```execute
kubectl api-resources | grep networkpolicies
```

したがって、metadata に名前空間を指定していないこのポリシーは、名前空間default 内で定義されるリソースであり、default 内のPod に対してのみ効果があります。 `policyTypes` の `Ingress`、 `Egress` はそれぞれ入力方向、出力方向を意味し、どの方向の通信を制御するかを表します。今回は全てのトラフィックを最初にブロックするため、Ingress、 Egress 両方を宣言します。 

したがって、このマニフェストの意味するところは、`「名前空間default 内のPod の通信をすべて拒否する」` ということになります。


次に、Pod 間の通信を許可するよう、ラベルを使って穴を空けていきます。

```yaml
ingress:
- from:
  - podSelector:
      matchLabels:
        app: frontend
egress:
- to:
  - podSelector:
      matchLabels:
        app: backend
```

この書き方はお作法として覚えてください。細かい書き方はドキュメントからコピペができるので暗記する必要はないですが、ingress: の後の from: や egress: の後の to: の関係、podSelector や今回の解答には出ていないnamespaceSelector を使って送信元、送信先対象が絞れることは覚えておきます。  
また、もう1 つ重要な点として、今回はingress from およびegress to の両方の指定をしなければなりません。なぜならば、frontend → backend の通信は、frontend から見るとegress (出力方向) 通信である一方で、backend からしてみればそれはingress (入力方向) 通信であり、片方のみ許可しただけでは通信は拒否されてしまうというためです。ホワイトリスト方式だとこのあたりが厳密になるためやや面倒です。

ちなみに、namespaceSelector の場合、ラベルを使って名前空間を指定します。`名前空間名を直接指定できない`ため、もし問題中にラベルが指定されなかった場合、対象となる名前空間に自分でラベルを作成して割り当てることに注意してください。下記の場合は、送信元となる名前空間に対して、user:alice のラベルが割り当てられている必要があります。

```yaml
ingress:
- from:
  - namespaceSelector:
      matchLabels:
        user: alice
    podSelector:
      matchLabels:
        role: client
```
ちなみに上記の場合、namespaceSelector はuser:alice のラベルで指定された名前空間内のPod を意味し、podSelector はrole:client のラベルで指定されたPod を意味しますが、これらはAND 条件になります。つまり、この場合、対象となる通信は「user:alice のラベルを持つ名前空間のPod かつ role:client のラベルを持つPod」からの通信を許可します。  

//絵

では次のマニフェストはどうでしょうか？

```yaml
ingress:
- from:
  - namespaceSelector:
      matchLabels:
        user: alice
  - podSelector:
      matchLabels:
        role: client
```
先ほどとの違いはpodSelector の前にハイフンが付いただけですが、これだとOR 条件になり、対象となる通信は「user:alice のラベルを持つ名前空間のPod または Network Polocy が定義された名前空間内のrole:client のラベルを持つPod」と大きく意味が異なります。

上記は以下のようにも書くことができます。OR 条件の場合、こちらのようにfrom で条件ごとに区切った方が見通しが良いです。
```yaml
ingress:
- from:
  - namespaceSelector:
      matchLabels:
        user: alice
- from:
  - podSelector:
      matchLabels:
        role: client
```
なお、条件の中でnamespaceSelector が省略されpodSelector のみ宣言された場合は、Network Polocy が定義された名前空間内のPod を暗黙に意味します。つまり、この場合他の名前空間でrole:client のラベルを持つPod があったとしても、ingress 通信は許可されません。

//絵

さて、残りの要件として、「Pod はクラスタ内DNS を用いて名前解決が可能」というものがありました。ホワイトリスト方式のため、名前解決をするためにはクラスタ内DNS (CoreDNS) へのアクセスを許可する必要があります。ここを忘れてしまうと、Pod はService 経由で他のPod にアクセスできなくなるため、ホワイトリスト方式の場合はとても重要です。
ただし、こちらに関しては「全ての通信をブロックするホワイトリスト方式の場合、CoreDNS への通信を忘れずに許可する」というだけではなく、マニフェストの書き方も含めて覚えておく必要があります (Kubernetes の公式ドキュメントに載っていないため)。

```yaml
egress:
- to:
  - namespaceSelector: {}
    podSelector:
      matchLabels:
        k8s-app: kube-dns
  ports:
  - port: 53
    protocol: UDP
  - port: 53
    protocol: TCP
```
📝ヒント：  
https://cloud.redhat.com/blog/guide-to-kubernetes-egress-network-policies

CoreDNS Pod のラベルはデフォルトで割当てられています。  

なお、CoreDNS に対するIngress 通信を別途許可する必要はありません。このNetworkPolicy は名前空間kube-system (CoreDNS が稼働している) に定義されていないためです (NetworkPolicy はNamespaced なリソースであることに注意！)。


以上より、作成するNetworkPolicy は下記の通りです。

```execute
cat <<EOF > ~/q5/q5-networkpolicy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: q5-networkpolicy
  namespace: question5
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
  egress:
    - to:
      - namespaceSelector: {}
        podSelector:
          matchLabels:
            k8s-app: kube-dns
      ports:
      - protocol: TCP
        port: 53
      - protocol: UDP
        port: 53
    - to:
      - podSelector:
          matchLabels:
            app: backend
EOF
kubectl apply -f ~/q5/q5-networkpolicy.yaml
```

さっそく確認してみましょう。まずは単純にdescribe します。
```execute
kubectl describe -n question5 networkpolicy
```

```yaml
Spec:
  PodSelector:     <none> (Allowing the specific traffic to all pods in this namespace)
  Allowing ingress traffic:
    // app=frontend からの通信許可
    To Port: <any> (traffic allowed to all ports)
    From:
      PodSelector: app=frontend
  Allowing egress traffic:
    // CoreDNS への通信許可
    To Port: 53/TCP
    To Port: 53/UDP
    To:
      NamespaceSelector: <none>
      PodSelector: k8s-app=kube-dns
    ----------
    // app=backend への通信許可
    To Port: <any> (traffic allowed to all ports)
    To:
      PodSelector: app=backend
  Policy Types: Ingress, Egress
```
describe の結果としては正しく制御されているように見えます。実際にPod を作って確かめましょう。

```execution
kubectl apply -f ~/q5/np-test.yaml
```
このマニフェストは、2つのbusybox Pod をそれぞれfrontend backend アプリケーションと見立てています。frontend からping を送信し、かつ名前解決ができていることを確認します。

```execution
BACKEND_IP=$(kubectl get pod -n question5 busybox-backend -o jsonpath='{.status.podIP}')
BACKEND_FQDN=$(echo $BACKEND_IP | sed "s/\./-/g").question5.pod.cluster.local
kubectl exec -n question5 busybox-frontend -- ping $BACKEND_FQDN
```
その他のIP アドレスにはアクセスできません。
```execution
kubectl exec -n question5 busybox-frontend -- ping 8.8.8.8
```
以上より、NetworkPolicy が正しく機能されていることが確認できました。

最後に、NetworkPolicy Editor を紹介します。  
https://editor.cilium.io/  
NetworkPolicy Editor では、NetworkPolicy をハンズオン形式で学べるほか、ネットワーク制御の状態の可視化、GUI でのポリシーの操作、マニフェストのアップロードやダウンロードといったような機能を提供する、非常に便利なサービスです。試験に挑む前には必ず触っておきましょう。


