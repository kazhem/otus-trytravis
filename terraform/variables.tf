variable project {
  description = "Project ID"
}
variable region {
  description = "Region"
  # Значение по умолчанию
  default = "europe-west1"
}
variable zone {
  description = "Zone in region"
  default     = "europe-west1-b"
}

variable public_key_path {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}
variable appuser1_public_key_path {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}
variable appuser2_public_key_path {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}
variable private_key_path {
  description = "Path to the private key used in connections"
}
variable disk_image {
  description = "Disk image"
}
variable instance_count {
  type    = number
  default = 1
}
