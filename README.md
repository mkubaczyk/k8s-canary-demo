# k8s-canary-demo

Run `./scripts/run.sh all` to initialize minikube with helm, istio, traefik, echo example app and invoke every canary test

Run `./scripts/run.sh echo` to upgrade echo application after values.yaml changes

Run `./scripts/run.sh canary_istio|canary_nginx|canary_traefik` to run canary tests for specific controller
 
or `./scripts/run.sh canary_istio_header|canary_nginx_header` to run tests against http header match routing for istio|nginx controller
