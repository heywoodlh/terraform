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
  kubeconfig = yamldecode(base64decode(vultr_kubernetes.k8s_cluster.kube_config))
  host                   = local.kubeconfig["clusters"][0]["cluster"]["server"]
  ca_cert    = base64decode(local.kubeconfig["clusters"][0]["cluster"]["certificate-authority-data"])
  client_certificate     = base64decode(local.kubeconfig["users"][0]["user"]["client-certificate-data"])
  client_key             = base64decode(local.kubeconfig["users"][0]["user"]["client-key-data"])
  token                  = local.kubeconfig["users"][0]["user"]["token"]
}

# Initialize kubernetes provider with k8s_cluster config
provider "kubernetes" {
  host                   = local.host
  token                  = local.token
  cluster_ca_certificate = local.ca_cert
}

provider "kubectl" {
  host                   = local.host
  token                  = local.token
  cluster_ca_certificate = local.ca_cert
  load_config_file       = false
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

## kubectl apply -f https://raw.githubusercontent.com/vultr/vultr-csi/master/docs/releases/latest.yml
#data "http" "vultr_csi_yaml" {
#  url  = "https://raw.githubusercontent.com/vultr/vultr-csi/master/docs/releases/latest.yml"
#}
#resource "kubectl_manifest" "vultr_csi" {
#  yaml_body = data.vultr_csi_yaml.body
#}
