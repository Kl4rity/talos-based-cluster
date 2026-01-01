# Traefik load balancer configuration
load_balancer_name = "traefik-ingress"
location           = "nbg1"
load_balancer_type = "lb11"

# Labels applied to the Traefik load balancer
load_balancer_labels = {
  type = "traefik-ingress"
}

# Target worker nodes running Traefik
worker_target_label_selector = "type=worker"

# HTTP service configuration (forwards to Traefik NodePort)
http_listen_port = 80
http_destination_port = 32765
http_protocol = "tcp"

# HTTPS service configuration (forwards to Traefik NodePort)
https_listen_port = 443
https_destination_port = 32031
https_protocol = "tcp"