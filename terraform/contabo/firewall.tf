# ---------- Cloudflare public IPv4 ranges ----------
# Fetched on every run so CF IP rotations land in the firewall on next apply.
data "http" "cloudflare_ipv4" {
  url = "https://www.cloudflare.com/ips-v4"
}

locals {
  cloudflare_ipv4 = compact(split("\n", trimspace(data.http.cloudflare_ipv4.response_body)))
}

# ---------- Firewall ----------
resource "contabo_firewall" "yourdevops" {
  name         = "yourdevops"
  status       = "active"
  instance_ids = [tonumber(contabo_instance.s01.id)]

  rules {
    # k8s API
    inbound {
      protocol   = "tcp"
      action     = "accept"
      status     = "active"
      dest_ports = ["6443"]
      src_cidr {
        ipv4 = var.ssh_source_cidrs
      }
    }

    # SSH — restricted source
    inbound {
      protocol   = "tcp"
      action     = "accept"
      status     = "active"
      dest_ports = ["22"]
      src_cidr {
        ipv4 = var.ssh_source_cidrs
      }
    }

    # HTTPS — Cloudflare only
    inbound {
      protocol   = "tcp"
      action     = "accept"
      status     = "active"
      dest_ports = ["443"]
      src_cidr {
        ipv4 = local.cloudflare_ipv4
      }
    }

    # HTTP — Cloudflare only
    inbound {
      protocol   = "tcp"
      action     = "accept"
      status     = "active"
      dest_ports = ["80"]
      src_cidr {
        ipv4 = local.cloudflare_ipv4
      }
    }

    inbound {
      protocol   = ""
      action     = "drop"
      status     = "active"
      dest_ports = []
      src_cidr {
        ipv4 = []
        ipv6 = []
      }
    }
  }
}
