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

function run_echo {
    log "Upgrading|installing echo"
    helm upgrade --recreate-pods --wait --install --wait --values values.yaml echo ./charts/echo
}

function run_canary_istio {
    run_canary istio
}

function run_canary_traefik {
    run_canary traefik
}

function run_istio_header_check {
    log "Running http header match check for istio provider with -H \"User: json\" curl parameter..."
    ./scripts/count.sh 100 "$(minikube ip):$(kubectl get svc istio-ingressgateway -o jsonpath="{.spec.ports[0].nodePort}")" echo.minikube "User: json"
}

function run_canary {
    controller=$1
    log "Running weighted routing check for ${controller}..."
    command="./scripts/count.sh 100"
    host="echo.minikube"
    if [[ $controller == "istio" ]]; then
        command="${command} $(minikube ip):$(kubectl get svc istio-ingressgateway -o jsonpath="{.spec.ports[0].nodePort}")"
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
        run_echo
        run_canary_istio
        run_canary_traefik
        run_istio_header_check
        ;;
    init)
        init_minikube
        ;;
    istio)
        run_istio
        ;;
    traefik)
        run_traefik
        ;;
    echo)
        run_echo
        ;;
    canary_istio)
        run_canary_istio
        ;;
    canary_traefik)
        run_canary_traefik
        ;;
    header_istio)
        run_istio_header_check
        ;;
    *)
        log "Unknown parameter (all|init|istio|traefik|echo|canary_istio|canary_traefik|header_traefik)"
        exit 1
        ;;
esac
