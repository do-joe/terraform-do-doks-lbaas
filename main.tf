terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.0-pre2"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.0"
    }
  }
}

data "digitalocean_kubernetes_cluster" "doks_cluster" {
  name = var.doks_cluster_name
}

provider "kubernetes" {
  host  = data.digitalocean_kubernetes_cluster.doks_cluster.endpoint
  token = data.digitalocean_kubernetes_cluster.doks_cluster.kube_config[0].token
  cluster_ca_certificate = base64decode(
    data.digitalocean_kubernetes_cluster.doks_cluster.kube_config[0].cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes = {
    host  = data.digitalocean_kubernetes_cluster.doks_cluster.endpoint
    token = data.digitalocean_kubernetes_cluster.doks_cluster.kube_config[0].token
    cluster_ca_certificate = base64decode(
      data.digitalocean_kubernetes_cluster.doks_cluster.kube_config[0].cluster_ca_certificate
    )
  }
}

resource "kubernetes_namespace_v1" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
    labels = {
      name = "ingress-nginx"
    }
  }
}

data "http" "ingress_nginx_values" {
  url = "https://raw.githubusercontent.com/digitalocean/marketplace-kubernetes/master/stacks/ingress-nginx/values.yml"
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  namespace  = kubernetes_namespace_v1.ingress_nginx.metadata[0].name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.12.1"
  values = [
    data.http.ingress_nginx_values.response_body
  ]
  set = [
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/do-loadbalancer-name"
      value = var.lb_name != null ? var.lb_name : var.doks_cluster_name
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/do-loadbalancer-size-unit"
      value = var.lb_size_unit
    },
    # There appears to be an issue with the NLB working with the Routing Agent with default route defined. So will use ALB for now.
    # Once issue is resolved uncomment this and remove the three following values.
    #     {
    #       name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/do-loadbalancer-type"
    #       value = "REGIONAL_NETWORK"
    #     },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/do-loadbalancer-enable-proxy-protocol"
      value = "true"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/do-loadbalancer-tls-passthrough"
      value = "true"
    },
    {
      name  = "controller.config.use-proxy-protocol"
      value = "true"
    }
  ]
}

# To be added later once how NLB issue will be handled.
# resource "kubernetes_namespace_v1" "cert_manager" {
#   metadata {
#     name = "cert-manager"
#     labels = {
#       name = "cert-manager"
#     }
#   }
# }
#
# data "http" "cert_manager_values" {
#   url = "https://raw.githubusercontent.com/digitalocean/marketplace-kubernetes/master/stacks/cert-manager/values.yml"
# }
#
#
# resource "helm_release" "cert_manager" {
#   name       = "cert-manager"
#   namespace  = kubernetes_namespace_v1.cert_manager.metadata[0].name
#   repository = "https://charts.jetstack.io"
#   chart      = "cert-manager"
#   version    = "1.13.3"
#   values = [
#     data.http.cert_manager_values.response_body
#   ]
# }
#
#
# resource "kubernetes_namespace_v1" "app" {
#   metadata {
#     name = var.app_name
#     labels = {
#       name = var.app_name
#     }
#   }
# }
#
# resource "helm_release" "cert_manager_issuer" {
#   depends_on = [
#     helm_release.cert_manager
#   ]
#   name       = "cert-manager-letsencrypt-issuer"
#   namespace  = kubernetes_namespace_v1.app.metadata[0].name
#   chart      = "${path.module}/cert-manager-letsencrypt-issuer"
#   set = [
#     {
#       name  = "acmeEmail"
#       value = var.letsencrypt_email
#     }
#   ]
# }





