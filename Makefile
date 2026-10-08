.PHONY: init validate fmt lint plan apply destroy help

help:
	@echo "Available commands:"
	@echo "  make init      - Initialize Terraform and download provider plugins"
	@echo "  make validate  - Validate syntax and configuration integrity"
	@echo "  make fmt       - Format all Terraform files recursively"
	@echo "  make plan      - Generate and display execution plan"
	@echo "  make apply     - Provision infrastructure"
	@echo "  make destroy   - Tear down all managed infrastructure"

init:
	terraform init

validate:
	terraform validate

fmt:
	terraform fmt -recursive

plan:
	terraform plan -var-file="terraform.tfvars"

apply:
	terraform apply -var-file="terraform.tfvars"

destroy:
	terraform destroy -var-file="terraform.tfvars"