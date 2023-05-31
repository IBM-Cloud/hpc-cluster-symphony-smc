###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

# This mapping file has entries for smc images
# These are images for smc nodes (primary, secondary, secondary-candidate)

locals {
  image_region_map = {
    "hpcc-symphony732-rhel86-smc-v1" = {
      "eu-de"    = "r010-8c7026b2-8887-42db-b117-1aebfebe200b"
      "us-east"  = "r014-70601edc-345a-4c5e-a08b-f3a9a4b176c8"
      "eu-gb"    = "r018-d33a425c-1543-43a7-a0fa-5d5f782e9c3b"
      "jp-osa"   = "r034-74fa8bdf-659b-4dd8-bda9-9e6afe01dbac"
      "br-sao"   = "r042-2fa501f5-a4bf-4c37-913f-64b6ef9720c8"
      "us-south" = "r006-877ec399-46b8-424f-b73d-04c89df2c839"
      "jp-tok"   = "r022-35ec77a4-fc5b-4e1b-9d23-63efd0a4005f"
      "au-syd"   = "r026-3da4b01d-8c69-41c9-ac5c-ac53368b8045"
      "ca-tor"   = "r038-c6568e3e-48b9-4b8a-b3e9-46be1ace13b7"
    }
  }
}