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

# Initialize kubernetes provider with k8s_cluster config
provider "kubernetes" {
  host                   = "${vultr_kubernetes.k8s_cluster.endpoint}"
  token                  = "${vultr_kubernetes.k8s_cluster.kubeconfig.0.token}"
  cluster_ca_certificate = "${base64decode(vultr_kubernetes.k8s_cluster.kubeconfig.0.cluster_ca_certificate)}"
}

# Initialize kubectl provider with k8s_cluster config
provider "kubectl" {
  host                   = "${vultr_kubernetes.k8s_cluster.endpoint}"
  token                  = "${vultr_kubernetes.k8s_cluster.kubeconfig.0.token}"
  cluster_ca_certificate = "${base64decode(vultr_kubernetes.k8s_cluster.kubeconfig.0.cluster_ca_certificate)}"
  load_config_file       = false
}

# Create secret for persistent storage
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

# kubectl apply -f https://raw.githubusercontent.com/vultr/vultr-csi/master/docs/releases/latest.yml
data "http_request" "manifest" {
  url  = "https://raw.githubusercontent.com/vultr/vultr-csi/master/docs/releases/latest.yml"
}
resource "kubectl_apply" "vultr_csi" {
  depends_on = [http_request.manifest]
  manifest = http_request.manifest.body
}
