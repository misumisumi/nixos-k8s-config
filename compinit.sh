#! /usr/bin/env zsh
KUBECONFIG=.kube/admin.kubeconfig
[[ $SHELL = *zsh* ]] && source <(kubectl completion zsh)
[[ $SHELL = *zsh* ]] && source <(helm completion zsh)
alias "k=kubectl --kubeconfig $KUBECONFIG"
alias "he=helm --kubeconfig $KUBECONFIG"
complete -o default -F __start_kubectl k
complete -o nospace -C $(which terraform) terraform
echo "completion loaded"