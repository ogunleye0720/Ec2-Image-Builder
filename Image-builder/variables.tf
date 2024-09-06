
variable "name_prefix" {
  description = "Prefix for all resource names."
  type        = string
  default = "chromenotepadbucket"
}

variable "chrome_url" {
  description = "URL for downloading Google Chrome."
  type        = string
  default     = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
}

variable "description" {
  description = "description for the image builder component"
  type = string
  default = "Installs software on Windows Server 2022"
}
variable "environment" {
  description = "Project environment"
  type = string
  default = "Test"
}

variable "change_description" {
  description = "version state for the image builder"
  type = string
  default = "Initial version"
}

variable "notepad_url" {
  description = "URL for downloading Notepad++."
  type        = string
  default     = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.1.9.2/npp.8.1.9.2.Installer.x64.exe"
}

variable "parent_image_arn" {
  description = "The ARN of the base image to use for the AMI."
  type        = string
  default = "arn:${data.aws_partition.current.partition}:imagebuilder:${data.aws_region.current.name}:aws:image/ami-07cc1bbe145f35b58"
}

variable "platform" {
  description = "platform to use for the AMI"
  type = string
  default = "Windows"
}

variable "instance_types" {
  description = "The instance types for EC2 Image Builder pipeline."
  type        = list(string)
  default     = ["t2.medium"]
}

variable "version" {
  description = "version number"
  type = string
  default = "1.0.0"
}

variable "volume_size" {
  description = "The volume size in GB."
  type        = number
  default     = 30
}
