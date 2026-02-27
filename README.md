# deliberate. Cloud on Hetzner

A unified Terraform configuration for deploying an opinionated and complete Kubernetes cluster on Hetzner to get you started and retain flexibility and freedom.
The goal is to give you something that works - instead of giving you a list of decisions to make.

## Why Talos on Hetzner?

### Customer Demand
Many customers prefer EU-based hosting over hyperscalers for data sovereignty and emotional reasons. Hetzner provides an excellent price to performance with German/EU data residency.

### Portability
Kubernetes gives you deployment flexibility - migrate between Hetzner, Scaleway, Exoscale, or hyperscalers without reworking your K8s resources.

### Cost
Hyperscalers have high margins. Hetzner offers competitive pricing while maintaining excellent performance and reliability.

## What this repository provides

### Compute
You get a cluster on which you can deploy your compute workloads. Your stateless service, hosting for your webapp, etc. - all on the same infrastructure.

### DNS & Ingress
Define an HTTPRoute and the necessary DNS records will be created via external-dns. Not only a nice developer-experience but laying the groundwork for feature-deployments.

### TLS Certificates
Let's Encrypt certificates are automatically generated and managed for you.

### Logging & Monitoring
Prometheus and Grafana are deployed and configured to provide a complete logging and monitoring stack. 

You can find it at grafana.deliberate.cloud

### Gitlab CE && Container Registry
Gitlab is deployed on a dedicated Hetzner VM. Managing it outside the cluster is easier from a networking perspective. 

You can find it at gitlab.deliberate.cloud && registry.deliberate.cloud respectively

### Persistence
You can either provision a Hetzner volume or use a Longhorn volume which makes use of the Nodes' local storage (I would recommend Hetzner volumes so as not to put undue pressure on the cluster nodes).

## Example of a Minimal Deployment
```yaml 
apiVersion: v1
kind: Namespace
metadata:
  name: your-app
---
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-pull-secret
  namespace: your-app
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64 encoded docker config>
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: your-app
  namespace: your-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: your-app
  template:
    metadata:
      labels:
        app: your-app
    spec:
      imagePullSecrets:
        - name: gitlab-pull-secret
      containers:
        - name: your-app
          image: registry.deliberate.cloud/your-app:latest
          ports:
            - containerPort: 8000
          resources:
            limits:
              cpu: "500m"
              memory: "256Mi"
            requests:
              cpu: "100m"
              memory: "128Mi"
---
apiVersion: v1
kind: Service
metadata:
  name: your-app
  namespace: your-app
spec:
  selector:
    app: your-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8000
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: your-app
  namespace: your-app
  annotations:
    external-dns.alpha.kubernetes.io/enabled: "true"
    external-dns.alpha.kubernetes.io/owner: "default"
spec:
  parentRefs:
    - name: cilium-gateway
      namespace: default
  hostnames:
    - deliberate.cloud
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: your-app
          port: 80
```

## TODOs
The goal of this repository is to create an opinionated cluster deployment which provides any interested user with a solid starting point which includes all the basics one can expect. This is a work in progress - building up from the basics to convenience features:

- Compute ✅
- DNS ✅
- TLS Certificates ✅
- Container Registry (GitLab CE) ✅
- Logging and Monitoring ✅
- Tracing ✅
- Store tofu-state in Hetzner S3 🚧 
- GlitchTip or BugSink for Error Tracking. 🚧
- S3 Storage (Hetzner or Self-Hosted) - would just document how to use Hetzner's from an application-deployment. 🚧
- Cloud Native Postgress 🚧
- ArgoCD? 🚧
- Expose Docs as simple webapp to access after deployment - docs.{primary-domain} - linking to the deployed services and provide a quickstart / getting started guide. 🚧
- ... ?

## Quick Start
### Preparation
1. Install mise https://mise.jdx.dev/getting-started.html
2. Run `mise install`
3. Create a Hetzner Account https://www.hetzner.com/de/cloud
4. Create a Hetzner Project to install the cloud into
5. Create a Hetzner API Token https://cloud.hetzner.com/project-api-keys
6. Create a Cloudflare Account https://www.cloudflare.com/
7. Transfer DNS to Cloudflare 
8. Create a Cloudflare API Token https://dash.cloudflare.com/profile/api-tokens

Please reference the concrete README's in the respective directories for more details.
