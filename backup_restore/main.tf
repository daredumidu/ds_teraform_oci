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
  description = "Path to your private key"
  type        = string
}

variable "region" {
  description = "OCI region"
  type        = string
  default     = "us-phoenix-1"
}

variable "compartment_ocid" {
  description = "OCID of the compartment"
  type        = string
}

variable "boot_volume_backup_ocid" {
  description = "OCID of the boot volume backup"
  type        = string
}

variable "availability_domain" {
  description = "Availability domain for the instance"
  type        = string
}

variable "subnet_ocid" {
  description = "OCID of the subnet"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

variable "instance_name" {
  description = "Custom name for the VM instance"
  type        = string
  default     = "vm-from-boot-backup"
}

variable "boot_volume_name" {
  description = "Custom name for the restored boot volume"
  type        = string
  default     = "restored-boot-volume"
}

# Create boot volume from backup
resource "oci_core_boot_volume" "restored_boot_volume" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
  
  source_details {
    type = "bootVolumeBackup"
    id   = var.boot_volume_backup_ocid
  }

  display_name = var.boot_volume_name
}

# Create the compute instance
resource "oci_core_instance" "vm_instance" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
  shape               = "VM.Standard.E2.1.Micro"

  display_name = var.instance_name

  create_vnic_details {
    subnet_id        = var.subnet_ocid
    assign_public_ip = true
  }

  source_details {
    source_type = "bootVolume"
    source_id   = oci_core_boot_volume.restored_boot_volume.id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  preserve_boot_volume = false
}

# Outputs
output "instance_id" {
  description = "OCID of the created instance"
  value       = oci_core_instance.vm_instance.id
}

output "instance_public_ip" {
  description = "Public IP of the instance"
  value       = oci_core_instance.vm_instance.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the instance"
  value       = oci_core_instance.vm_instance.private_ip
}

output "boot_volume_id" {
  description = "OCID of the restored boot volume"
  value       = oci_core_boot_volume.restored_boot_volume.id
}
