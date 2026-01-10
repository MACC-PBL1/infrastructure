resource "local_file" "ansible_inventory_nat" {
  filename = "${path.module}/../../../../../ansible/inventory/dev/hosts.ini"

  content = <<EOF
[nat_bastion]
${module.nat_bastion.public_ip} ansible_user=admin ansible_ssh_private_key_file=~/.ssh/labsuser.pem
EOF

  depends_on = [module.nat_bastion]
}
