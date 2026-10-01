.PHONY: init fmt validate plan apply destroy secrets-edit secrets-check

# Secrets live encrypted in secrets.sops.tfvars.json (SOPS + age, see README).
# `sops exec-file` decrypts to a private temp file for the duration of one
# command and removes it afterwards; nothing plaintext touches the tree.
SOPS_FILE := secrets.sops.tfvars.json
WITH_SECRETS := sops exec-file --no-fifo $(SOPS_FILE)

init:
	tofu init

fmt:
	tofu fmt -recursive

validate:
	tofu validate

plan:
	$(WITH_SECRETS) 'tofu plan -input=false -var-file={}'

apply:
	$(WITH_SECRETS) 'tofu apply -input=false -var-file={}'

destroy:
	$(WITH_SECRETS) 'tofu destroy -input=false -var-file={}'

secrets-edit:
	sops $(SOPS_FILE)

# Fails if any value in the secrets file is not an ENC[...] ciphertext.
secrets-check:
	@python3 -c 'import json,sys; d=json.load(open("$(SOPS_FILE)")); bad=[k for k,v in d.items() if k!="sops" and not str(v).startswith("ENC[")]; sys.exit("plaintext values: %s" % bad if bad else 0)' && echo "$(SOPS_FILE): all values encrypted"
