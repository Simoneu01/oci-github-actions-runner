variable "save_to" {
    default = ""
}

data "archive_file" "generate_zip" {
  type        = "zip"
  output_path = (var.save_to != "" ? "${var.save_to}/oci-github-actions-runner-orm.zip" : "${path.module}/dist/oci-github-actions-runner-orm.zip")
  source_dir = "../"
  excludes    = ["terraform.tfstate", "terraform.tfvars.template", "terraform.tfvars", "provider.tf", ".terraform", "build-orm", "images", "README.md", "terraform.", "terraform.tfstate.backup", "test", "simple", ".git", "README", ".github", ".gitignore", ".DS_Store", "LICENSE", "diagram", "packer"]
}
