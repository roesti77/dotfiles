# __PROJECT_NAME__

[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.31-326ce5?style=flat-square&logo=kubernetes)](https://kubernetes.io/)
[![kind](https://img.shields.io/badge/kind-latest-2f6cb4?style=flat-square)](https://kind.sigs.k8s.io/)
[![Cilium](https://img.shields.io/badge/Cilium-1.16.5-F8C517?style=flat-square&logo=cilium)](https://cilium.io/)
[![Gateway API](https://img.shields.io/badge/Gateway%20API-v1.2.1-326ce5?style=flat-square)](https://gateway-api.sigs.k8s.io/)
[![cert-manager](https://img.shields.io/badge/cert--manager-v1.17.0-0090d8?style=flat-square)](https://cert-manager.io/)
[![mkcert](https://img.shields.io/badge/mkcert-local%20CA-3a3a3a?style=flat-square)](https://github.com/FiloSottile/mkcert)
[![Devbox](https://img.shields.io/badge/Devbox-Nix--based-31135a?style=flat-square)](https://www.jetify.com/devbox/)
[![direnv](https://img.shields.io/badge/direnv-auto--env-2e2e2e?style=flat-square)](https://direnv.net/)
[![Taskfile](https://img.shields.io/badge/Taskfile-v3-29BEB0?style=flat-square&logo=task)](https://taskfile.dev/)

Local Kubernetes playground for running __PROJECT_NAME__. A single-node kind
cluster with Cilium as CNI (kube-proxy replaced), Gateway API for ingress, and
cert-manager wiring mkcert's local CA for trusted TLS on `*.localhost.direct`.

## Prerequisites

Install [Devbox](https://www.jetify.com/devbox/) and [direnv](https://direnv.net/):

```sh
curl -fsSL https://get.jetify.com/devbox | bash
brew install direnv
```

Hook direnv into your shell (zsh):

```sh
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
```

Then enter the repo and allow the environment — devbox pulls all tools defined
in `devbox.json` (kind, kubectl, helm, cilium-cli, mkcert, jq, ...).

```sh
cd __PROJECT_NAME__
direnv allow
```

## Cluster

The kind cluster `__PROJECT_NAME__-playground` is managed via `task kind:*`:

| Task | What it does |
|---|---|
| `task kind:prepare-local-cluster` | Create the cluster and install everything: Gateway API CRDs, Cilium (with `kubeProxyReplacement` and `gatewayAPI.enabled`), cert-manager, the mkcert root CA as a `ClusterIssuer`, and a shared `Gateway` listening on HTTP/80 + HTTPS/443. |
| `task kind:start-local-cluster` | Start the existing kind containers and switch kubectx. |
| `task kind:stop-local-cluster` | Stop the kind containers without deleting state. |
| `task kind:delete-local-cluster` | Delete the cluster and remove the local `.mkcert/` directory. |

After `prepare-local-cluster`, the control-plane container maps host ports
80 → NodePort 30080 and 443 → NodePort 30443. Cilium's Gateway API
implementation creates a `cilium-gateway-shared` Service in the
`gateway-system` namespace; the task patches it to `NodePort` with those fixed
ports so requests to `https://<anything>.localhost.direct` reach the Gateway
through the kind port mappings.

`localhost.direct` resolves to `127.0.0.1` via public DNS, so no `/etc/hosts`
entries are needed. Certificates are signed by the mkcert root CA installed in
your system trust store — browsers will trust them without warnings.
