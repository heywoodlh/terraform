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

resource "vultr_block_storage" "k8s_block_storage" {
    label = "${var.k8s_label}-blockstorage"
    size_gb = "${var.k8s_block_storage_size}"
    region = "${var.k8s_block_storage_region}"
    # attach to node_pool
    attached_to_instance = "${vultr_kubernetes.k8s_cluster.node_pools.0.id}"
}
