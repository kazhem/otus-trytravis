resource "google_compute_instance_group" "app_instance_group" {
  name = "app-instance-group"
  zone = var.zone
  instances = google_compute_instance.app[*].self_link

  named_port {
    name = "http"
    port = "9292"
  }
}

resource "google_compute_health_check" "http-health-check" {
  name = "http-health-check"

  timeout_sec        = 3
  check_interval_sec = 3

  http_health_check {
    port_name = "http"
    port      = 9292
  }
}



resource "google_compute_url_map" "app_urlmap" {
  name        = "app-urlmap"
  description = "urlmap to app_backend"

  default_service = google_compute_backend_service.app_home.self_link

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.app_home.self_link

    path_rule {
      paths   = ["/", "/*"]
      service = google_compute_backend_service.app_home.self_link
    }
  }
  depends_on = [google_compute_backend_service.app_home]
}

resource "google_compute_backend_service" "app_home" {
  name = "app-home"
  health_checks = [
    google_compute_health_check.http-health-check.self_link,
  ]
  port_name = "http"
  protocol  = "HTTP"
  backend {
    group = google_compute_instance_group.app_instance_group.self_link
  }
  depends_on = [
    google_compute_instance_group.app_instance_group,
    google_compute_health_check.http-health-check
  ]
}

resource "google_compute_target_http_proxy" "app_proxy" {
  name    = "app-proxy"
  url_map = google_compute_url_map.app_urlmap.self_link
}

resource "google_compute_global_forwarding_rule" "app_forwarding_rule" {
  name       = "app-global-rule"
  target     = google_compute_target_http_proxy.app_proxy.self_link
  port_range = "80"
}
