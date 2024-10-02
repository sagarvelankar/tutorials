https://github.com/argoproj/argo-cd.git

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
curl -sSL -o argocd-darwin-arm64 https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-darwin-arm64

sudo install -m 555 argocd-darwin-arm64 /usr/local/bin/argocd
rm argocd-darwin-arm64

kubectl port-forward svc/argocd-server -n argocd 8080:443

OR

Rancher desktop port forwarding

| Namespace | Name | Port | Local Port |
| --- | --- | --- | --- |
| argocd | argocd-server | http | 8080 |
| argocd | argocd-server | https | 8080 |

argocd admin initial-password -n argocd

argocd login localhost:8080
WARNING: server certificate had error: tls: failed to verify certificate: x509: certificate signed by unknown authority. Proceed insecurely (y/n)? y
Username: admin
Password: 
'admin:login' logged in successfully
Context 'localhost:8080' updated

argocd account update-password

https://github.com/argoproj/argocd-example-apps.git

kubectl config set-context --current --namespace=argocd

argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace default

argocd app set guestbook --sync-policy automated --auto-prune --self-heal

argocd app get guestbook

argocd app sync guestbook

kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

If you are not interested in UI, SSO, and multi-cluster features, then you can install only the core Argo CD components.
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/core-install.yaml

argocd login --core
argocd admin dashboard -n argocd

argocd app delete guestbook

https://github.com/settings/tokens?type=beta

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: github-sagarvelankar-creds
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repo-creds
stringData:
  type: git
  url: https://github.com/sagarvelankar
  password: XXXXX
  username: sagarvelankar
EOF

argocd app create guestbook --repo https://github.com/sagarvelankar/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace default

argocd app set guestbook --sync-policy automated --auto-prune --self-heal

argocd app sync guestbook

kubectl edit configmap argocd-cm -n argocd
data:
  resource.respectRBAC: "strict"
  resource.includeEventLabelKeys: team,env*

kubectl rollout restart -n argocd statefulset argocd-application-controller

AppProject is only required if Argo CD is configured to manage Application resources configured in namespaces other than argocd.

helm repo add jenkinsci https://charts.jenkins.io
helm repo update

cat <<EOF > /tmp/jenkins-values.yaml
controller:
  ingress:
    enabled: true
    hostName: jenkins.127.0.0.1.sslip.io
EOF

helm template jenkins jenkinsci/jenkins -f /tmp/jenkins-values.yaml -n jenkins --create-namespace --include-crds > argocd/jenkins.yaml

argocd app create jenkins --repo https://github.com/sagarvelankar/devops-jenkins-gitops.git --path argocd --dest-server https://kubernetes.default.svc --dest-namespace jenkins --revision component --sync-policy automated --auto-prune --self-heal --sync-option CreateNamespace=true --directory-include "*.yaml"

http://jenkins.127.0.0.1.sslip.io

cat <<EOF > /tmp/prometheus-values.yaml
alertmanager:
  ingress:
    enabled: true
    hosts:
      - alertmanager.127.0.0.1.sslip.io
grafana:
  ingress:
    enabled: true
    hosts:
      - grafana.127.0.0.1.sslip.io
prometheus:
  ingress:
    enabled: true
    hosts:
      - prometheus.127.0.0.1.sslip.io
EOF

helm install prometheus -n prometheus --create-namespace -f /tmp/prometheus-values.yaml prometheus-community/kube-prometheus-stack

Login to grafana with username admin and password prom-operator

cat <<EOF | kubectl apply -n argocd -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: argocd-metrics
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-metrics
  endpoints:
  - port: metrics
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: argocd-repo-server-metrics
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-repo-server
  endpoints:
  - port: metrics
EOF

Add dashboard https://raw.githubusercontent.com/argoproj/argo-cd/master/examples/dashboard.json

kubectl config set-context --current --namespace=argocd

helm repo add jenkinsci https://charts.jenkins.io
helm repo update

cat <<EOF > /tmp/devops-backstage-postgresql-values.yaml
EOF

helm template devops-backstage-postgresql oci://registry-1.docker.io/bitnamicharts/postgresql -f /tmp/devops-backstage-postgresql-values.yaml -n devops-backstage --create-namespace --include-crds > argocd/devops-backstage-postgresql.yaml

argocd app create devops-backstage-postgresql --repo https://github.com/sagarvelankar/devops-backstage-postgresql-gitops.git --path argocd --dest-server https://kubernetes.default.svc --dest-namespace devops-backstage --revision component --sync-policy automated --auto-prune --self-heal --sync-option CreateNamespace=true --directory-include "*.yaml"

Port forwarding in rancher desktop