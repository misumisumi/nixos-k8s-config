#! /usr/bin/env bash

[[ ! -d ./.terraform ]] && terraform init
[[ $(terraform workspace list | grep product) == "" ]] && terraform workspace new product
[[ $(terraform workspace list | grep develop) == "" ]] && terraform workspace new develop

echo "initialization complete"