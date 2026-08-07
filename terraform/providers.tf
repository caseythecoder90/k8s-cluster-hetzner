# Auth: export HCLOUD_TOKEN in your shell (preferred — keeps the token out of
# files entirely), or set TF_VAR_hcloud_token. See docs/00-prerequisites.md.
provider "hcloud" {
  token = var.hcloud_token
}
