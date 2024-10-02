curl -s https://fluxcd.io/install.sh | sudo bash

cat <<EOF > ~/.fluxcd_aliases
alias fluxns='kubectl config set-context --current --namespace=flux-system'
alias fluxre='kubectl rollout restart deployments -n flux-system'
EOF

cat <<EOF >> ~/.zprofile
# fluxcd aliases
[ -f ~/.fluxcd_aliases ] && source ~/.fluxcd_aliases
source <(flux completion zsh)
# fluxcd aliases end
EOF

flux check --pre

flux install --components="source-controller,kustomize-controller" --export > fluxcd/gotk-components.yaml

flux install --components="source-controller,kustomize-controller"

flux create source git podinfo \
  --url=https://github.com/stefanprodan/podinfo \
  --branch=master \
  --interval=1m

flux create kustomization podinfo \
  --target-namespace=default \
  --source=podinfo \
  --path="./kustomize" \
  --prune=true \
  --wait=true \
  --interval=30m \
  --retry-interval=2m \
  --health-check-timeout=3m 

flux get kustomizations --watch

flux suspend kustomization podinfo

flux resume kustomization podinfo

Add following files to fluxcd directory
- kustomization.yaml
- gotk-sync.yaml
- gotk-pvc.yaml

kubectl apply -k fluxcd

flux create source git podinfo-shard1 \
  --url=https://github.com/stefanprodan/podinfo \
  --branch=master \
  --interval=1m \
  --label="sharding.fluxcd.io/key=shard1"

flux create kustomization podinfo-shard1 \
  --target-namespace=default \
  --source=podinfo-shard1 \
  --path="./kustomize" \
  --prune=true \
  --wait=true \
  --interval=30m \
  --retry-interval=2m \
  --health-check-timeout=3m \
  --label="sharding.fluxcd.io/key=shard1"

flux check




