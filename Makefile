.PHONY: init fmt validate plan apply destroy

init:
	tofu init

fmt:
	tofu fmt -recursive

validate:
	tofu validate

plan:
	tofu plan

apply:
	tofu apply

destroy:
	tofu destroy
