名前空間 `question5` を作成し、以下の要件を満たすようNetworkPolicy を作成して割り当ててください。  
- key:value = app:frontend のラベルを持つPod からapp:backend のラベルを持つPod への通信を許可
- Pod はクラスタ内DNS を用いて名前解決が可能
- その他の入力・出力方向の通信はすべてブロック

また、~/q5/np-test.yaml を用いて、作成したNetworkPolicy が正しいかを確認してみてください。


📝ヒント：  
https://kubernetes.io/ja/docs/concepts/services-networking/network-policies/