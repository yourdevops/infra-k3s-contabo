variable "ssh_source_cidrs" {
  description = "IPv4 CIDRs allowed to reach SSH (port 22). Set via the contabo TFC workspace variable of the same name."
  type        = list(string)
}
