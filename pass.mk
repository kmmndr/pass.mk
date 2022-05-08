#!/usr/bin/env -S make -f

GNUPGHOME?=${HOME}/.gnupg
export GNUPGHOME

PASSWORD_STORE_DIR?=${HOME}/.password-store
export PASSWORD_STORE_DIR

GITLAB_HOST?=https://gitlab.com

real_name?=$(shell git config user.name)
real_email?=$(shell git config user.email)
passphrase?=weak-password

define usage =
Options:
  gpg-generate-key
    Generate key for yourself

  gpg-export-key
    Display public key to be shared (to gitlab)

  gpg-import-from-gitlab (-e GITLAB_HOST=${GITLAB_HOST})
    Import someone else key from Gitlab
    (Custom gitlab instance may be specified using GITLAB_HOST variable)

  gpg-ultimate-trust
    Set ultimate trust for someone else public key (required for pass)

  pass-init
    Initialize password store
    (set PASSWORD_STORE_DIR variable to use another store)

  pass-add-user -e email=someoneelse@localhost
    Add user key to store (to share passwords)

  pass-reinit
    Update password permission (run after pass-add-user)

  pass-clone -e remote=...
    Clone store from remote repository

Environment:
  GITLAB_HOST=${GITLAB_HOST}
  GNUPGHOME=${GNUPGHOME}
  PASSWORD_STORE_DIR=${PASSWORD_STORE_DIR}
endef

.PHONY: help
help:; @ $(info $(usage)) :

.PHONY: gpg-list-keys
gpg-list-keys:
	gpg --list-keys

.PHONY: gpg-list-secret-keys
gpg-list-secret-keys:
	gpg --list-secret-keys

.PHONY: review-user-variables
review-user-variables:
	$(eval real_name=$(shell read -p "Real Name [${real_name}] : " real_name; real_name=$${real_name:-${real_name}}; echo $$real_name))
	$(eval real_email=$(shell read -p "Real Email [${real_email}] : " real_email; real_email=$${real_email:-${real_email}}; echo $$real_email))
	@echo "${real_name} <${real_email}>"

.PHONY: gpg-review-variables
gpg-review-variables: review-user-variables
	$(eval passphrase=$(shell read -s -p "Passphrase: " passphrase; echo $$passphrase))
	@echo

.INTERMEDIATE: ${GNUPGHOME}/generate-key.batch
${GNUPGHOME}/generate-key.batch: gpg-review-variables
	@mkdir -p $$GNUPGHOME
	@chmod 0700 $$GNUPGHOME
	@echo 'Key-Type: eddsa' >> $@
	@echo 'Key-Curve: Ed25519' >> $@
	@echo 'Key-Usage: sign' >> $@
	@echo 'Subkey-Type: ecdh' >> $@
	@echo 'Subkey-Curve: Curve25519' >> $@
	@echo 'Subkey-Usage: encrypt' >> $@
	@echo 'Passphrase: ${passphrase}' >> $@
	@echo 'Name-Real: ${real_name}' >> $@
	@echo 'Name-Email: ${real_email}' >> $@
	@echo 'Creation-Date: $(shell date -u +%Y%m%dT%H%M%S)' >> $@
	@echo 'Expire-Date: 0' >> $@
	@echo '%commit' >> $@

.PHONY: gpg-generate-key
gpg-generate-key: ${GNUPGHOME}/generate-key.batch
	@if ! gpg --fingerprint ${real_email} > /dev/null 2>&1; then \
		echo "Key not found, generating..."; \
		gpg --batch --generate-key $^; \
	else \
		echo "Key found for ${real_email}"; \
	fi
	@rm $^

.PHONY: gpg-find-key
gpg-find-key:
	@gpg --fingerprint ${real_email}

.PHONY: gpg-export-key
gpg-export-key: review-user-variables
	@echo 'Public key follows here :'
	@gpg --export --armor ${real_email}

.PHONY: gpg-create-keyring
gpg-create-keyring: gpg-review-variables gpg-generate-key gpg-find-key gpg-export-key

.PHONY: gpg-import-from-gitlab
gpg-import-from-gitlab:
	$(eval GITLAB_USER?=$(shell id -nu))
	$(eval GITLAB_USER=$(shell read -p "Gitlab username [${GITLAB_USER}] : " username; username=$${username:-${GITLAB_USER}}; echo $$username))
	@echo "Importing ${GITLAB_USER} from ${GITLAB_HOST} ..."
	@curl -L ${GITLAB_HOST}/${GITLAB_USER}.gpg 2> /dev/null | gpg --import --verbose

.PHONY: gpg-ultimate-trust
gpg-ultimate-trust:
	$(eval email?=$(shell read -p "E-mail: " email; echo $$email))
	gpg --list-keys --fingerprint --with-colons ${email} | awk -F':' '/^fpr/ { print $$10 ":6:" }' | gpg --import-ownertrust

.PHONY: pass-init
pass-init: review-user-variables
	mkdir -p ${PASSWORD_STORE_DIR}
	pass init ${real_email}
	pass git init

.PHONY: pass-reinit
pass-reinit:
	pass init $$(cat ${PASSWORD_STORE_DIR}/.gpg-id)

.PHONY: pass-clone
pass-clone:
	@test -n "${remote}" || (echo 'remote parameter is missing'; exit 1)
	git clone ${remote} ${PASSWORD_STORE_DIR}

.PHONY: pass-list
pass-list:
	@pass list

.PHONY: prompt-email
prompt-email:
	$(eval email?=$(shell read -p "E-mail: " email; echo $$email))
	@echo

.PHONY: ensure-email
ensure-email:
	@test -n "${email}" || (echo 'email parameter is missing'; exit 1)

.PHONY: pass-add-user
pass-add-user: ensure-email
	echo ${email} >> ${PASSWORD_STORE_DIR}/.gpg-id
