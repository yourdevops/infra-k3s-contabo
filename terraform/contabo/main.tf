# ---------- VPS ----------
resource "contabo_instance" "s01" {
  display_name = "s01.yourdevops.me"
}

# ---------- Object Storage ----------
resource "contabo_object_storage" "main" {
  region                   = "EU"
  total_purchased_space_tb = 0.25
}
