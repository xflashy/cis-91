variable "zone" {
  default = "us-central1-f"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  project = "christian-403921"
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "e2-micro"
  zone = var.zone
  tags = ["dev", "web"]
  boot_disk { 

    initialize_params {
       image = "debian-cloud/debian-11"
      #image = "cos-cloud/cos-stable"
    }
  }
  
  attached_disk {
    source      = google_compute_disk.default.id
    device_name = google_compute_disk.default.name
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
    
  }
}

output "ip" {
  value = google_compute_instance.vm_instance.network_interface.0.network_ip
}

resource "google_compute_firewall" "firewall" {
  name    = "terraform-firewall"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "22"]
  }

  target_tags = ["web"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_storage_bucket" "backup-bucket1" {
  name          = "backup-mariadb1"
  location      = "US"
  force_destroy = true
  uniform_bucket_level_access = true

versioning {
  enabled = true
}

  lifecycle_rule {
    condition {
      with_state = "ARCHIVED"
      num_newer_versions = 180
    }
    action {
      type = "Delete"
    }
  }

   lifecycle_rule {
    condition {
      age = 0
      days_since_noncurrent_time = 180
    }
    action {
      type = "Delete"
    }
  }
}

output "external_ip" {
value = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
}
  resource "google_compute_disk" "default" {
  name = "data"
  type = "pd-balanced"
  zone = "us-central1-f"
  size = "10"
}
 

