# pass.mk

Simple helper for [pass](https://www.passwordstore.org/) meant to ease usage in
team without prior GPG knowledge.

## Requirements

The following tools are required:
- [coreutils](https://www.gnu.org/software/coreutils/)
- [make](https://www.gnu.org/software/make/)
- [gnupg](https://www.gnupg.org/)
- [pass](https://www.passwordstore.org/)

## Installation

```
# installation
env PREFIX=~/.local make install

# uninstallation
env PREFIX=~/.local make uninstall
```

## Usage

### Create your key pair

```
$ pass.mk gpg-generate-key
Real Name [John Doe] :
Real Email [john@doe.lan] :
John Doe <john.doe@localhost>
Passphrase:
Key not found, generating...
gpg: directory '/home/john/.gnupg/openpgp-revocs.d' created
gpg: revocation certificate stored as '/home/john/.gnupg/openpgp-revocs.d/C2BC1EA22C1E731F1FF1C87C1D9794D7456CA0C9.rev'
```

### Export your public key to gitlab

```
$ pass.mk gpg-export-key
Real Name [John Doe] :
Real Email [john@doe.lan] :
John Doe <john.doe@localhost>
Public key follows here :
-----BEGIN PGP PUBLIC KEY BLOCK-----

0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000
00000
-----END PGP PUBLIC KEY BLOCK-----
```

### Other options

```
Options:
  gpg-generate-key
    Generate key for yourself

  gpg-export-key
    Display public key to be shared (to gitlab)

  gpg-import-from-gitlab (-e GITLAB_HOST=https://gitlab.com)
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
  GITLAB_HOST=https://gitlab.com
  GNUPGHOME=/home/john/.gnupg
  PASSWORD_STORE_DIR=/home/john/.password-store
```
