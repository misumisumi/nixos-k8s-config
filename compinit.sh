#! /usr/bin/env zsh

[[ $SHELL = *zsh* ]] && source <(kubectl completion zsh)
alias "k=kubectl --kubeconfig certs/generated/kubernetes/admin.kubeconfig"
complete -o default -F __start_kubectl k
complete -o nospace -C $(which terraform) terraform
echo "completion loaded"