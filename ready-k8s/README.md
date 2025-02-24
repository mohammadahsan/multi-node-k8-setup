# First Level

## Second Level

### Minikube Install Guide

```bash
## Install minikube
brew install minikube
minikube start
## Install Helm
brew install helm
```

#### Install Minikube Addon Ingress

```bash
minikube addons enable ingress
```

#### If no Minikube
kubectl create ns ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx

##### Install cert Manager

```bash
helm repo add jetstack https://charts.jetstack.io --force-update
kubectl create ns cert-manager
helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.12.0 --set installCRDs=true
## Install cluster Issuer
kubectl apply -f samples/learn-issuer.yaml
```

##### Install sample pods to test ingress & Certmanager

```bash
kubectl apply -f samples/sample.yaml
```

###### Make sure to add /etc/hosts file entry and run minikube tunnel

```bash
sudo vim /etc/hosts
127.0.0.1 learn.com
127.0.0.1 *.learn.com # Change it as per need host file doesn't support wild card '*'
## Run the minikube
sudo minikube tunnel
```

##### Install ArgoCD using the helm Charts locally

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm pull argo/argo-cd
tar -xvf argo-cd-7.7.3.tgz
## Install Argocd
kubectl create ns argocd
helm upgrade --install argocd ./argo-cd -f argo-cd/values.yaml -n argocd # Ingress modified to use local dns
```

##### Install Argo-Rollouts using the helm Charts locally

```bash
helm pull argo/argo-rollouts
tar -xvf argo-rollouts-2.37.8.tgz

kubectl create ns argo-rollouts
helm upgrade --install argo-rollouts ./argo-rollouts -f argo-rollouts/values.yaml -n argo-rollouts # Ingress modified to use local dns
```


##### Removing K8s Finalizers

```bash
kubectl patch clusterserviceversions.operators.coreos.com <resource-name> -n px-operator --type=json -p='[{"op": "remove", "path": "/metadata/finalizers"}]'

```


kubectl run -i -t busybox --image=busybox --restart=Never
kubectl run web --image=nginx --port=80
kubectl expose pod web --port 80
kubectl create ingress demo-localhost --class=nginx --rule="demo.learn.com/*=demo:80"