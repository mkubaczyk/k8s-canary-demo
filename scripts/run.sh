#!/bin/bash

set -e

LOG_COUNT=1
function log {
	DATE=$(date '+%Y-%m-%d %H:%M:%S')
	echo "---> #$LOG_COUNT [$DATE] $1"
	((LOG_COUNT++))
}

function init_minikube {
    log "Deleting minikube"
    minikube delete || true
    log "Bootstraping minikube"
    minikube start --vm-driver=hyperkit --kubernetes-version=v1.13.2 --cpus=4 --memory=8192
    log "Initializing helm"
    kubectl create serviceaccount --namespace kube-system tiller
    kubectl create clusterrolebinding tiller-admin --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
    helm init --upgrade --service-account tiller --wait
}

function run_istio {
    log "Upgrading|installing istio"
    kubectl create ns istio-system || true
    helm upgrade --recreate-pods --wait --install --wait --values values.yaml istio ./charts/istio --timeout 900
}

function run_nginx_ingress {
    log "Upgrading|installing nginx-ingress"
    helm dependency build ./charts/nginx-ingress
    helm upgrade --wait --install --values values.yaml nginx-ingress ./charts/nginx-ingress
}

function run_echo {
    log "Upgrading|installing echo"
    helm upgrade --recreate-pods --wait --install --wait --values values.yaml echo ./charts/echo
}

function run_canary_header {
    controller=$1
    log "Running http header match check for $controller provider with -H \"will-you-let-me-in: always\" curl parameter..."
    command="./scripts/count.sh 100"
    host="echo.minikube"
    if [[ $controller == "istio" ]]
    then
        command="${command} $(minikube ip):$(kubectl get svc istio-ingressgateway -o jsonpath="{.spec.ports[0].nodePort}")"
    else
        command="${command} $(minikube ip):$(kubectl get svc nginx-ingress-controller -o jsonpath="{.spec.ports[0].nodePort}")"
    fi
    command="${command} $host 'will-you-let-me-in: always'"
    eval ${command}
}

function run_canary {
    controller=$1
    log "Running weighted routing check for ${controller}..."
    command="./scripts/count.sh 100"
    host="echo.minikube"
    if [[ $controller == "istio" ]]
    then
        command="${command} $(minikube ip):$(kubectl get svc istio-ingressgateway -o jsonpath="{.spec.ports[0].nodePort}")"
    elif [[ $controller == "nginx" ]]
    then
        command="${command} $(minikube ip):$(kubectl get svc nginx-ingress-controller -o jsonpath="{.spec.ports[0].nodePort}")"
    else
        command="${command} $(minikube ip):$(kubectl get svc traefik -o jsonpath="{.spec.ports[0].nodePort}")"
    fi
    command="${command} $host"
    eval ${command}
}

function run_traefik {
    log "Upgrading|installing traefik"
    helm dependency build ./charts/traefik
    helm upgrade --wait --install --values values.yaml traefik ./charts/traefik
}

case "$1" in
    all)
        init_minikube
        run_istio
        run_traefik
        run_nginx_ingress
        run_echo
        run_canary istio
        run_canary traefik
        run_canary nginx
        run_canary_header istio
        run_canary_header nginx
        ;;
    init)
        init_minikube
        ;;
    istio)
        run_istio
        ;;
    nginx)
        run_nginx_ingress
        ;;
    traefik)
        run_traefik
        ;;
    echo)
        run_echo
        ;;
    canary_istio)
        run_canary istio
        ;;
    canary_traefik)
        run_canary traefik
        ;;
    canary_nginx)
        run_canary nginx
        ;;
    canary_istio_header)
        run_canary_header istio
        ;;
    canary_nginx_header)
        run_canary_header nginx
        ;;
    *)
        log "Unknown parameter (all|init|istio|traefik|echo|canary_istio|canary_traefik|header_traefik)"
        exit 1
        ;;
esac
