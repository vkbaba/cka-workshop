.vimrc に以下を記載します。
set tabstop=2
set expandtab
set shiftwidth=2

```execute
cat <<EOF > ~/.vimrc
set tabstop=2
set expandtab
set shiftwidth=2
```
他にもset autoindent でインデントを保持したまま改行するなど、使いやすいようにお好みで設定してください。

kubectl のエイリアスとオートコンプリートの設定は以下の通りです。

```execute
echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -F __start_kubectl k' >>~/.bashrc
exec bash
```

