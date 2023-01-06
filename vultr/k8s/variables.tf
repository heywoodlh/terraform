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
