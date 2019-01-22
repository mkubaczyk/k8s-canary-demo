#!/bin/bash

set -e

minikube start --vm-driver=hyperkit --kubernetes-version=v1.11.6 --cpus=4 --memory=8192

kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-admin --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --upgrade --service-account tiller --wait

echo "/private/etc/hosts will be updated now, which requires sudo to be used..."
echo -e "\n$(minikube ip) traefik.minikube echo.minikube" | sudo tee -a /private/etc/hosts
