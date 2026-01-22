resource "aws_instance" "services" {
  for_each = var.instances

  ami                    = var.ami
  instance_type          = each.value.instance_type
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = [var.sg_id]
  associate_public_ip_address = each.value.public_ip
  key_name               = var.key_name
  private_ip             = lookup(each.value, "private_ip", null)
  user_data = lookup(each.value, "user_data", null)
  iam_instance_profile        = lookup(each.value, "iam_instance_profile", null)
  tags = {
    Name = each.key
  }
}
