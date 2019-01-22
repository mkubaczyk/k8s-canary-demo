# k8s-canary-demo

`./scripts/init.sh` to set up a minikube with helm

`helm upgrade --recreate-pods --wait --install demo .` to deploy chart

`./scripts/count.sh 100 http://echo.minikube:$(kubectl get svc traefik -o jsonpath="{.spec.ports[0].nodePort}")` - to test canary
