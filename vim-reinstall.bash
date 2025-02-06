# shellcheck source=./_core.bash
. "$(dirname "${0}")/_core.bash"

if [[ "${script_dir}" != "$(readlink -e -- "$(pwd)")" ]]; then
  echo "please execute this script from its own directory"
  exit 1
fi

# vim specific stuff
pushd "${HOME}/.vim/pack/datfinesoul/start/coc.nvim"
pnpm install || npm install
popd
