terraform {
  required_providers {
    vultr = {
      source = "vultr/vultr"
      version = "2.12.0"
    }
  }
}

# Configure the Vultr Provider
provider "vultr" {
  rate_limit = 100
  retry_limit = 3
}

# Create a k8s cluster
resource "vultr_kubernetes" "k8" {
  region = "${var.k8s_region}"
    label     = "tf-vultr"
    version = "${var.k8s_version}"

    node_pools {
        node_quantity = 1
        plan = "${var.k8s_server_size}"
        label = "${var.k8s_label}"
        auto_scaler = "${var.k8s_autoscaler}"
        min_nodes = "${var.k8s_min_nodes}"
        max_nodes = "${var.k8s_max_nodes}"
    }
} 
