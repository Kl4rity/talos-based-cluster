resource "hcloud_load_balancer" "controlplane" {
  name               = var.load_balancer_name
  location           = var.location
  load_balancer_type = var.load_balancer_type
  labels             = var.load_balancer_labels
}

resource "hcloud_load_balancer_service" "k8s_api" {
  load_balancer_id = hcloud_load_balancer.controlplane.id
  listen_port      = var.service_listen_port
  destination_port = var.service_destination_port
  protocol         = var.service_protocol
}



resource "hcloud_load_balancer_target" "controlplane_nodes" {
  load_balancer_id = hcloud_load_balancer.controlplane.id
  type             = "label_selector"
  label_selector   = var.controlplane_target_label_selector
}

