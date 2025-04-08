variable "doks_cluster_name" {
  description = "DOKS cluster name"
  type        = string
}

variable "nginx_ingress_values_url" {
  description = "URL of the values file to use when creating a helm release for nginx ingress."
  type        = string
  default     = "https://raw.githubusercontent.com/digitalocean/marketplace-kubernetes/master/stacks/ingress-nginx/values.yml"
}

variable "lb_name" {
  description = "Name of the LB deployed as part of the nginx ingress. Defaults to the name of the cluster."
  type        = string
  default     = null
}

variable "lb_size_unit" {
  description = " how many nodes the load balancer is created with."
  type        = number
  default     = 1
}
