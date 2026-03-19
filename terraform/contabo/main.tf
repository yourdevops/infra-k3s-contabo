# ---------- VPS ----------
resource "contabo_instance" "s01" {
  display_name = "s01.yourdevops.me"
  product_id   = "V94"
  image_id     = "d64d5c6c-9dda-4e38-8174-0ee282474d8a"
  ssh_keys     = [98323, 320273]

  add_ons {
    id       = "1501"
    quantity = 1
  }
}

# ---------- Object Storage ----------
resource "contabo_object_storage" "main" {
  region                   = "European Union"
  total_purchased_space_tb = 0.25
  display_name             = "Object Storage EU 2393"

  auto_scaling {
    state         = "disabled"
    size_limit_tb = 0
  }
}
