###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
    Creates new SSH key pair to enable passwordless SSH between SMC nodes.
*/

variable "turn_on" {}

resource "tls_private_key" "tls_private_key" {
  count     = tobool(var.turn_on) == true ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

output "public_key_content" {
  value     = try(tls_private_key.tls_private_key[0].public_key_openssh, "")
  sensitive = true
}

output "private_key_content" {
  value     = try(tls_private_key.tls_private_key[0].private_key_pem, "")
  sensitive = true
}