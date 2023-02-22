terraform {
  required_providers {
    vultr = {
      source = "vultr/vultr"
      version = "2.12.1"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    http = {
      source = "hashicorp/http"
      version = "3.2.1"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.9.0"
    }
    argocd = {
      source = "oboukili/argocd"
      version = "4.3.0"
    }
  }
}

# Configure the Vultr Provider
provider "vultr" {
  rate_limit = 100
  retry_limit = 3
}

# Create a k8s cluster
resource "vultr_kubernetes" "k8s_cluster" {
  region = "${var.k8s_region}"
    label     = "tf-vultr"
    version = "${var.k8s_version}"

    node_pools {
        node_quantity = "${var.k8s_min_nodes}"
        plan = "${var.k8s_server_size}"
        label = "${var.k8s_label}"
        auto_scaler = "${var.k8s_autoscaler}"
        min_nodes = "${var.k8s_min_nodes}"
        max_nodes = "${var.k8s_max_nodes}"
    }
} 

locals {
  kubeconfig             = yamldecode(base64decode(vultr_kubernetes.k8s_cluster.kube_config))
  host                   = local.kubeconfig["clusters"][0]["cluster"]["server"]
  ca_cert                = base64decode(local.kubeconfig["clusters"][0]["cluster"]["certificate-authority-data"])
  client_certificate     = base64decode(local.kubeconfig["users"][0]["user"]["client-certificate-data"])
  client_key             = base64decode(local.kubeconfig["users"][0]["user"]["client-key-data"])
}

# Initialize various kubernetes provider with k8s_cluster config
provider "kubernetes" {
  host                   = local.host
  cluster_ca_certificate = local.ca_cert
  client_certificate     = local.client_certificate
  client_key             = local.client_key
}
provider "kubectl" {
  host                   = local.host
  cluster_ca_certificate = local.ca_cert
  client_certificate     = local.client_certificate
  client_key             = local.client_key
  load_config_file       = false
}
provider "helm" {
  kubernetes {
    host                   = local.host
    cluster_ca_certificate = local.ca_cert
    client_certificate     = local.client_certificate
    client_key             = local.client_key
  }
}

## Create secret for persistent storage
resource "kubernetes_secret" "vultr_secret" {
  metadata {
    name = "vultr-csi"
  }
  data = {
    api-key = "${var.vultr_api_key}"
  }
  type = "Opaque"
}

provider "http" {}

## Define vultr-csi: kubectl apply -f https://raw.githubusercontent.com/vultr/vultr-csi/master/docs/releases/latest.yml
data "http" "vultr_csi_manifest_raw" {
  url  = "https://raw.githubusercontent.com/vultr/vultr-csi/master/docs/releases/latest.yml"
}
data "kubectl_file_documents" "vultr_csi_manifest" {
  content = data.http.vultr_csi_manifest_raw.body
}
resource "kubectl_manifest" "vultr_csi" {
  for_each  = data.kubectl_file_documents.vultr_csi_manifest.manifests
  yaml_body = each.value
}

## Point domain to k8s_cluster
resource "vultr_dns_domain" "k8s-light-domain" {
  domain = "${var.k8s_domain}"
  ip = "${resource.vultr_kubernetes.k8s_cluster.ip}"
}

## Create resources for ArgoCD
resource "kubernetes_namespace" "argocd_namespace" {
  metadata {
    annotations = {
      name = "argocd"
    }
    name = "argocd"
  }
}

## Clone repo locally
resource "null_resource" "clone_git_repo" {
  provisioner "local-exec" {
    command = "git clone --branch ${var.app_of_apps_version} ${var.app_of_apps_url} ${path.module}/app_of_apps"
  }
}

## Helm deploy ArgoCD
resource "helm_release" "argocd" {
  name = "argo-cd"
  namespace = "argocd"
  chart = "./app_of_apps/charts/argo-cd"
}

## Deploy the app of apps
resource "helm_release" "app_of_apps" {
  name = "bootstrap-app"
  chart = "./app_of_apps/apps"
}

## Remove local git repo
resource "null_resource" "cleanup_git_repo" {
  provisioner "local-exec" {
    command = "rm -rf ${path.module}/app_of_apps"
  }
}
