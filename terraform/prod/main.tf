provider "google" {
  # Версия провайдера
  version = "~>2.15.0"

  # ID проекта
  project = var.project
  region  = var.region
}
module "app" {
  source           = "../modules/app"
  public_key_path  = var.public_key_path
  zone             = var.zone
  app_disk_image   = var.app_disk_image
  private_key_path = var.private_key_path
  database_url     = "${module.db.db_internal_ip}:27017"
}

module "db" {
  source          = "../modules/db"
  public_key_path = var.public_key_path
  zone            = var.zone
  db_disk_image   = var.db_disk_image
}

module "vpc" {
  source        = "../modules/vpc"
  source_ranges = var.source_ranges
}
