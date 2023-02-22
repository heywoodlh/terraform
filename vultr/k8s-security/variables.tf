variable "k8s_region" {
  type = string
}

variable "k8s_label" {
  type = string
}

variable "k8s_version" {
  type = string
}

variable "k8s_autoscaler" {
  type = bool
}

variable "k8s_max_nodes" {
  type = number
}

variable "k8s_min_nodes" {
  type = number
}

variable "k8s_server_size" {
  type = string
}

variable "k8s_block_storage_size" {
  type = number
}

variable "k8s_block_storage_region" {
  type = string
}

variable "vultr_api_key" {
  type = string
}

variable "k8s_domain" {
  type = string
}

variable "app_of_apps_url" {
  type = string
}

variable "app_of_apps_version" {
  type = string
}
