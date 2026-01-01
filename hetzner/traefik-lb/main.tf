resource "hcloud_load_balancer" "traefik" {
  name               = var.load_balancer_name
  location           = var.location
  load_balancer_type = var.load_balancer_type
  labels             = var.load_balancer_labels
}

resource "hcloud_load_balancer_service" "http" {
  load_balancer_id = hcloud_load_balancer.traefik.id
  listen_port      = var.http_listen_port
  destination_port = var.http_destination_port
  protocol         = var.http_protocol
}

resource "hcloud_load_balancer_service" "https" {
  load_balancer_id = hcloud_load_balancer.traefik.id
  listen_port      = var.https_listen_port
  destination_port = var.https_destination_port
  protocol         = var.https_protocol
}

resource "hcloud_load_balancer_target" "worker_nodes" {
  load_balancer_id = hcloud_load_balancer.traefik.id
  type             = "label_selector"
  label_selector   = var.worker_target_label_selector
}