terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.35.0"
    }
  }
}

provider "openstack" {
  alias               = "admin"
  user_name           = "admin"
  tenant_name         = "admin"
  password            = "QAZwsx123"
  auth_url            = "http://192.168.1.200:5000/v3"
  region              = "RegionOne"
  user_domain_name    = "Default"
  project_domain_name = "Default"
}


provider "openstack" {
  alias               = "mine"
  user_name           = "nima"
  tenant_name         = "scenario"
  password            = "qazwsx"
  auth_url            = "http://192.168.1.200:5000/v3"
  region              = "RegionOne"
  user_domain_name    = "Default"
  project_domain_name = "Default"
}
