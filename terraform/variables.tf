
variable "flavor_name" {
  type    = list(any)
  default = ["x1.small", "x1.medium"]
}

variable "ram" {
  type    = list(any)
  default = ["1024", "2048"]
}

variable "disk" {
  type    = list(any)
  default = ["9", "10"]
}
variable "ports" {
  type    = list(any)
  default = [22, 80]
}
