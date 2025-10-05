# `get-profile-ssh-keys.bash`

## requirements

### sets environment variables

- **MY_PROFILE** (eg. personal, company-name, etc.)

### bitwarden secure note(s)

- note needs to be in a folder called `profile-MY_PROFILE` (replace `MY_PROFILE` with the contents of what would be in the environment variable)

- needs 1 fields and files as attachments
  - type - should always be `ssh`

> **NOTE**: use `base64 -w0` to encode
>
> **NOTE**: can multiple sessions be logged in at the same time on the console?