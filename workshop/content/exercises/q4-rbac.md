名前空間 `question4` を作成し、その中で`ServiceAccount` q4-sa を作成してください。次に、`Secrets` と `ConfigMaps` のみを `Get` 可能な `ClusterRole` を作成してください。最後に `RoleBinding` を作成し、作成したClusterRole を名前空間question4 のServiceAccount q4-sa に紐づけてください。

📝ヒント：  
RBAC テスト用に~/q4/rbac-test.yaml を使ってもOKです。

📝ヒント：  
https://kubernetes.io/ja/docs/reference/access-authn-authz/rbac/