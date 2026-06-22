alias strip-ansi=strip_ansi
alias strip-tofu-actions=strip_tofu_actions
strip_ansi ()
{
    sed 's/\x1b\[[0-9;]*[a-zA-Z]//g'
}

strip_tofu_actions ()
{
    awk '/OpenTofu will perform the following actions:/{found=1} found{print}'
}
