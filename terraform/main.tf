resource "openstack_identity_project_v3" "project" {
  name      = "scenario"
  domain_id = "default"
  provider  = openstack.admin
}

resource "openstack_identity_user_v3" "myuser" {
  default_project_id = openstack_identity_project_v3.project.id
  name               = "nima"
  password           = "qazwsx"
  domain_id          = "default"
  provider           = openstack.admin
}

data "openstack_identity_role_v3" "role" {
  name     = "_member_"
  provider = openstack.admin
}

resource "openstack_identity_role_assignment_v3" "my_role" {
  user_id    = openstack_identity_user_v3.myuser.id
  project_id = openstack_identity_project_v3.project.id
  role_id    = data.openstack_identity_role_v3.role.id
  provider   = openstack.admin
}

resource "openstack_compute_flavor_v2" "tiny" {
  name      = "x1.tiny"
  ram       = "512"
  vcpus     = "1"
  disk      = "8"
  is_public = true
  provider  = openstack.admin
  extra_specs = {
    "hw:boot_menu" = true
  }
}


resource "openstack_compute_flavor_v2" "flavors" {
  count     = length(var.flavor_name)
  name      = var.flavor_name[count.index]
  ram       = var.ram[count.index]
  vcpus     = "1"
  disk      = var.disk[count.index]
  is_public = true
  provider  = openstack.admin
}

resource "openstack_networking_network_v2" "network1" {
  name           = "private_network1"
  admin_state_up = "true"
  provider       = openstack.mine
  depends_on     = [openstack_identity_project_v3.project, openstack_identity_user_v3.myuser, openstack_identity_role_assignment_v3.my_role]
}

resource "openstack_networking_network_v2" "network2" {
  name           = "private_network2"
  admin_state_up = "true"
  provider       = openstack.mine
  depends_on     = [openstack_identity_project_v3.project, openstack_identity_user_v3.myuser, openstack_identity_role_assignment_v3.my_role]
}

resource "openstack_networking_subnet_v2" "subnet1" {
  name            = "private_subnet1"
  network_id      = openstack_networking_network_v2.network1.id
  cidr            = "172.18.1.0/24"
  gateway_ip      = "172.18.1.1"
  enable_dhcp     = "true"
  dns_nameservers = ["8.8.8.8", "4.2.2.4"]
  provider        = openstack.mine
}


resource "openstack_networking_subnet_v2" "subnet2" {
  name            = "private_subnet2"
  network_id      = openstack_networking_network_v2.network2.id
  cidr            = "172.22.2.0/24"
  gateway_ip      = "172.22.2.1"
  enable_dhcp     = "true"
  dns_nameservers = ["8.8.8.8", "4.2.2.4"]
  provider        = openstack.mine
}

resource "openstack_networking_secgroup_v2" "secgroup" {
  name       = "my_secgroup"
  provider   = openstack.mine
  depends_on = [openstack_identity_project_v3.project, openstack_identity_user_v3.myuser, openstack_identity_role_assignment_v3.my_role]
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_port" {
  count             = length(var.ports)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = var.ports[count.index]
  port_range_max    = var.ports[count.index]
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
  provider          = openstack.mine
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
  provider          = openstack.mine
}

data "openstack_networking_network_v2" "pub_net" {
  name     = "public_network"
  provider = openstack.admin
}

resource "openstack_networking_router_v2" "router" {
  name                = "my_vrouter"
  external_network_id = data.openstack_networking_network_v2.pub_net.id
  provider            = openstack.mine
  depends_on          = [openstack_identity_project_v3.project, openstack_identity_user_v3.myuser, openstack_identity_role_assignment_v3.my_role]
}

resource "openstack_networking_router_interface_v2" "router_interface1" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet1.id
  provider  = openstack.mine
}

resource "openstack_networking_router_interface_v2" "router_interface2" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet2.id
  provider  = openstack.mine
}

data "openstack_images_image_v2" "centos" {
  name     = "centos7"
  provider = openstack.admin
}

resource "openstack_compute_instance_v2" "webserver1" {
  name            = "webserver1"
  flavor_id       = element(openstack_compute_flavor_v2.flavors.*.id, 1)
  security_groups = ["my_secgroup"]
  user_data       = file("webscript.sh")
  provider        = openstack.mine

  block_device {
    uuid                  = data.openstack_images_image_v2.centos.id
    source_type           = "image"
    volume_size           = 10
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }


  block_device {
    source_type           = "blank"
    destination_type      = "volume"
    volume_size           = 1
    boot_index            = 1
    delete_on_termination = true
  }

  network {
    name = openstack_networking_network_v2.network1.name
  }

  network {
    name = openstack_networking_network_v2.network1.name
  }
}

resource "openstack_compute_instance_v2" "webserver2" {
  name            = "webserver2"
  image_id        = data.openstack_images_image_v2.centos.id
  flavor_id       = openstack_compute_flavor_v2.tiny.id
  security_groups = ["my_secgroup"]
  user_data       = file("webscript.sh")
  provider        = openstack.mine

  network {
    name = openstack_networking_network_v2.network2.name
  }

  network {
    name = openstack_networking_network_v2.network2.name
  }
}

resource "openstack_networking_floatingip_v2" "ip-pool" {
  pool       = data.openstack_networking_network_v2.pub_net.name
  provider   = openstack.mine
  depends_on = [openstack_identity_project_v3.project, openstack_identity_user_v3.myuser, openstack_identity_role_assignment_v3.my_role]
}

resource "openstack_compute_floatingip_associate_v2" "floatip" {
  floating_ip = openstack_networking_floatingip_v2.ip-pool.address
  instance_id = openstack_compute_instance_v2.webserver1.id
  provider    = openstack.mine
}

output "webserver1_floatingip" {
  value = openstack_networking_floatingip_v2.ip-pool.address
}
