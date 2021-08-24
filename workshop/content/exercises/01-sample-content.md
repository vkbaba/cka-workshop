カレントディレクトリを移動してください。

```execute
cd ~/lab1/
```
Pod を作成するマニフェストをapply します。

```execute
kubectl apply -f nginx.yaml
```

Pod が正しく作成されているかを確認します。

```execute
kubectl get pod
```

Good Job!!

