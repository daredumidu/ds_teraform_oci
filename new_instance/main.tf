terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# Variables
variable "tenancy_ocid" {
  description = "OCID of your tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the user"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint of the API key"
  type        = string
}

variable "private_key_path" {
  description = "Path to your private key file"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "region" {
  description = "OCI region"
  type        = string
  default     = "us-ashburn-1"
}

variable "compartment_ocid" {
  description = "OCID of the compartment where resources will be created"
  type        = string
}

variable "availability_domain" {
  description = "Availability domain for the instance"
  type        = string
}

variable "subnet_ocid" {
  description = "OCID of the subnet where the instance will be created"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

variable "instance_name" {
  description = "Custom name for the instance"
  type        = string
  default     = "my-oracle-linux-vm"
}

variable "boot_volume_name" {
  description = "Custom name for the boot volume (will be set after creation)"
  type        = string
  default     = "my-oracle-linux-boot-volume"
}

# Data source to get Oracle Linux 10 image
data "oci_core_images" "oracle_linux_10" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "10"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Create the compute instance (this automatically creates the boot volume from the image)
resource "oci_core_instance" "vm_instance" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = var.instance_name
  shape               = "VM.Standard.E2.1.Micro"

  create_vnic_details {
    subnet_id        = var.subnet_ocid
    display_name     = "${var.instance_name}-vnic"
    assign_public_ip = true
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.oracle_linux_10.images[0].id
    boot_volume_size_in_gbs = 100
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  # Boot volume will be deleted when instance is deleted
  preserve_boot_volume = false
}

# Outputs
output "instance_id" {
  description = "OCID of the created instance"
  value       = oci_core_instance.vm_instance.id
}

output "instance_name" {
  description = "Display name of the instance"
  value       = oci_core_instance.vm_instance.display_name
}

output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = oci_core_instance.vm_instance.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = oci_core_instance.vm_instance.private_ip
}

output "boot_volume_id" {
  description = "OCID of the boot volume"
  value       = oci_core_instance.vm_instance.boot_volume_id
}

output "rename_boot_volume_command" {
  description = "Optional: Command to rename the boot volume to your custom name"
  value       = "oci compute boot-volume update --boot-volume-id ${oci_core_instance.vm_instance.boot_volume_id} --display-name '${var.boot_volume_name}'"
}
