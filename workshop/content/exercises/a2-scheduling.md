まず、テンプレートとなるPod のマニフェストをドキュメントから探します。今回は永続性を持たない空のボリュームということで、emptyDir の使用を思いつきます。また、emptyDir が思いつかなかったとしても、ドキュメントでvolume と検索し、emptyDir が要件に適当なことを判断します。

emptyDir でドキュメントを検索すると、いくつかemptyDir を使うマニフェストが出てくるはずです。  
https://kubernetes.io/ja/docs/tasks/configure-pod-container/configure-volume-storage/  
https://kubernetes.io/docs/tasks/access-application-cluster/communicate-containers-same-pod-shared-volume/

📝ヒント：  
https://kubernetes.io/ja/docs というようにURL を書き換えると、日本語対応しているものは日本語表示が可能です。また、https://kubernetes.io/docs とすると英語表示が可能です。英語しかないドキュメントもありますので、必要に応じて両者を使い分けてください。


見つけたマニフェストを組み合わせつつ、ひな型を作っていきます。


```yaml
apiVersion: v1
kind: Pod
metadata:
  name: q2-pod
spec:
  containers:
  - name: c1
    image: busybox:1.31.1
    args:
      - /bin/sh
      - -c
      - while true; do date >> /vol/date.log; sleep 1; done
    volumeMounts:
    - name: vol
      mountPath: /vol
  - name: c2
    image: busybox:1.31.1
    args:
      - /bin/sh
      - -c
      - tail -f /vol/date.log
    volumeMounts:
    - name: vol
      mountPath: /vol
  volumes:
  - name: vol
    emptyDir: {}      
```

📝ヒント：  
コンテナの中で実行するコマンドに関するマニフェストの書き方は色々あります。command: を使ってもよいですが、上記のようにargs: を使った書き方が最もシンプルかつ汎用性があるかと思います。

次にマスターノードへのスケジューリングを設定します。マスターノードはシステムが利用するPod のための領域であるため、デフォルトではPod をデプロイ（＝スケジューリング）できません。ユーザーが勝手にマスターノードにPod のスケジューリングできないよう、`taint` （汚れ）という概念が使われています。taint があるノードにPod をデプロイしたい場合、Pod に `toleration`（耐性）を設定する必要があります。
https://kubernetes.io/ja/docs/concepts/scheduling-eviction/taint-and-toleration/

taint はPod のスケジューリングを防ぐ仕組みであり、デフォルトでマスターノードに使用されていますが、ワーカーノードにも使用できます。例えば、ワーカーノードのメモリが不足した場合、自動的に `node.kubernetes.io/memory-pressure` のtaint がそのワーカーノードに付与され、新たなPod のスケジューリングを防ぎます。

toleration を設定するためには、マスターノードにどのようなtaint が設定されているかを確認する必要があります。

```execute
kubectl describe node | grep Taints
```
マスターノードには `key:node-role.kubernetes.io/master` というtaint が設定してあり、effect はNoSchedule ということが分かります。なお、ここではkey に対応するvalue は空となっています。したがって、マニフェストには以下を追加することになります。

```yaml
tolerations:
- effect: NoSchedule
  key: node-role.kubernetes.io/master
```

ただし、toleration は、単にtaint が付与されているノードに対してスケジューリングを可能にするための設定であるため、このままではワーカーノードにもスケジュールされる可能性があります。マスターノードに強制的にスケジューリングするためには `nodeSelector` または `Affinity/Anti-Affinity` を使います。nodeSelector は単にスケジューリングされるノードを指定するときに使い、Affinity/Anti-Affinity はさらに柔軟にスケジューリング方法を指定したい場合に使います。今回はnodeSelector を使いますが、どちらも試験に出る可能性があり、特にAffinity/Anti-Affinity はマニフェストが nodeSelector よりも複雑なため、どういったルールが指定できるかは事前にドキュメント等で確認しておきましょう。 

nodeSelector の設定はシンプルで、ノードに設定してあるラベルを指定するだけです。ノードにはすべて固有のラベルがあらかじめ設定されているため、ラベルを新規作成する必要はありません。
```execute
kubectl get node --show-labels
```

マスターノードには `node-role.kubernetes.io/master` という、マスターノードであることを示すラベルが既に設定されています。したがって、マニフェストに以下を追加します。この場合、key に対応するvalue は空であることに注意してください。
```yaml
nodeSelector:
  node-role.kubernetes.io/master: "" 
```

最終的に、apply するマニフェストは以下の通りです。


```execute
cat <<EOF > ~/q2/q2-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: q2-pod
spec:
  containers:
  - name: c1
    image: busybox:1.31.1
    args:
      - /bin/sh
      - -c
      - while true; do date >> /vol/date.log; sleep 1; done
    volumeMounts:
    - name: vol
      mountPath: /vol
  - name: c2
    image: busybox:1.31.1
    args:
      - /bin/sh
      - -c
      - tail -f /vol/date.log
    volumeMounts:
    - name: vol
      mountPath: /vol
  volumes:
  - name: vol
    emptyDir: {}
  tolerations:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
  nodeSelector:
    node-role.kubernetes.io/master: "" 
EOF
kubectl apply -f ~/q2/q2-pod.yaml
```

デプロイができたら、マスターノードにスケジューリングされたかを確認し、ログも正しく吐けていることを確認してみてください。

```execute
kubectl get pod -o wide
```
```execute
kubectl logs q2-pod c2
```

