現在のコンテキストを表示するコマンドは以下の通りです。
```execute
kubectl config current-context
```

名前空間はマニフェストで作成してもよいですが、ここでは簡単にkubectl create コマンドで名前空間を直接作成したあと、ラベルを割り当てましょう。
```execute
kubectl create ns question1 
kubectl label ns question1 cka=q1
```

📝ヒント：  
ラベルはkey:value の形で表現されます。key のみを割り当てたい場合はvalue を入力する必要はありません。


割り当てたラベルは以下のようにフィルタリングのために使うことができます。
```execute
kubectl get ns -l cka=q1
```

📝ヒント：  
全てのオプションを覚える必要はありません。ヘルプオプションで都度参照します。
```execute
kubectl get -h
```
