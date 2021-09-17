以下の要件の通り、コンテナを2 つ含むPod を作成してください。2 つのコンテナは永続性を持たない空のボリュームを共有します。また、Pod はマスターノードにスケジューリングされるようにしてください。その際、ノードに新たなラベルは適用しないでください。

- Pod の名前: `q2-pod`  
- Namespace: `default`  
- ボリューム名: `vol`
- コンテナ1
  - 名前: `c1`  
  - イメージ: `public.ecr.aws/runecast/busybox:1.33.1`
  - 実行コマンド: `while true; do date >> /vol/date.log; sleep 1; done`
  - ボリュームのマウントパス: `/vol`
- コンテナ2
  - 名前: `c2`
  - イメージ: `public.ecr.aws/runecast/busybox:1.33.1` 
  - 実行コマンド: `tail -f /vol/date.log`
  - ボリュームのマウントパス: `/vol`
  



