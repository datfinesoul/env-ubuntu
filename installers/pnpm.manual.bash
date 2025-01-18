#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

### MODIFY: START
repo="nvm-sh/nvm"
### MODIFY: END

releases="$(gh api "/repos/${repo}/releases/latest")"

# NOTE: sometimes you need ${kernel_name,,}
read -r version url <<< "$(
  printf "%s\n" "${releases}" \
  | jq \
  --arg k "${kernel_name}" \
  --arg a "${architecture}" \
  --arg m "${machine}" \
  -r '[.tag_name, (.assets[].browser_download_url | select(test($k+"_"+$m)))] | @tsv'
)"

info "V:${version}"
info "U:${url}"

curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${version}/install.sh" | bash
wget -qO- https://get.pnpm.io/install.sh | ENV="$HOME/.bashrc" SHELL="$(which bash)" bash -
pnpm
pnpm env install --global lts


exit 0

npx create-next-app@latest nextjs-dashboard --example "https://github.com/vercel/next-learn/tree/main/dashboard/starter-example" --use-pnpm
pnpm i @vercel/postgres
historyc | grep pnpm
cp nvm.manual.bash pnpm.manual.bash
historyc | grep pnpm >> pnpm.manual.bash
mv ../workstation/apne1.tf ./
cat apne1.tf
vim apne1.tf
vim apne1.tf
vim apne1.tf
vim apne1.tf
vim apne1.tf
vim apne1.tf
vim apne1.tf
vim apne1.tf
vim apne1.tf
vim apne1.tf
vim apne1.tf
cat apne1.tf
ll /home/datfinesoul/.local/share/icons/hicolor/256x256/apps/kitty.png
ll /home/datfinesoul/.local/share/icons/hicolor/256x256/apps/kitty.png
ll /home/datfinesoul/.local/share/icons/hicolor/256x256/apps/kitty.png
vim apne1.tf
vim apne1.tf
cp management_use1.env dev_apne1.env
mv management_use1.env management_apne1.env
vim dev_apne1.env
mv dev_apne1.env observe_dev_apne1.env
mv management_apne1.env observe_management_apne1.env
mv dev_apne1.env observe_dev_apne1.env
mv management_apne1.env observe_management_apne1.env
vim apne1.tf
cp management_use1.env dev_apne1.env
mv management_use1.env management_apne1.env
vim dev_apne1.env
mv dev_apne1.env observe_dev_apne1.env
mv management_apne1.env observe_management_apne1.env
mv dev_apne1.env observe_dev_apne1.env
mv management_apne1.env observe_management_apne1.env
vim apne1.tf
cat apne1.tf
cat apne1.tf
git checkout apne1.tf
vim apne1.tf
vim apne1.tf
vim apne1.tf
git d apne1.tf
cat apne1.tf
git checkout apne1.tf
vim apne1.tf
vim apne1.tf
vim apne1.tf
git d apne1.tf
cd dev/apne1/
cd dev_apne1.observe_lambda
cat apne1.tf
git checkout apne1.tf
cp apne1.tf usw2.tf
meld apne1.tf usw2.tf
cp apne1.tf usw2.tf
cp apne1.tf ../../dev/core/apne1.tf
vim apne1.tf
mkdir -p aws/dev/apne1
mkdir -p aws/prod/apne1
mkdir -p aws/management/apne1
cp core/*.tf aws/dev/apne1/
cd aws/dev/apne1/
cp ~/Pictures/unbounded.work.png images/
mv src/app/images/unbounded.work.png public/
cp ~/Pictures/unbounded.work.2.png ../../public/unbounded.work.png
cp ~/Pictures/unbounded.work.2.png ../../public/unbounded.work.png
cp ~/Pictures/unbounded.work.2.png ../../public/unbounded.work.png
cp ~/Pictures/unbounded.work.2.png ../../public/unbounded.work.png
cp ~/Pictures/unbounded.work.2.png ../../public/unbounded.work.png
cp ~/Pictures/unbounded.work.2.png ../../public/unbounded.work.png
cp ~/Pictures/unbounded.work.png images/
mv src/app/images/unbounded.work.png public/
cp ~/Pictures/unbounded.work.2.png ../../public/unbounded.work.png
cp ~/Pictures/unbounded.work.2.png ../../public/unbounded.work.png
cp ~/Pictures/unbounded.work.2.png ../../public/unbounded.work.png
cp ~/Pictures/unbounded.work.2.png ../../public/unbounded.work.png
onoff apne1.tf
onoff apne1.tf
meld apne1.tf apne1.tf.off
rm apne1.tf
onoff apne1.tf.off
vim apne1.tf
meld apne1.tf apne1.tf.off
rm apne1.tf
onoff apne1.tf.off
vim apne1.tf
meld dev/core/apne1.tf prod/core/usw2.tf
meld dev/core/apne1.tf prod/core/apne1.tf
meld apne1.tf usw2.tf
cp apne1.tf usw2.tf
cp apne1.tf usw2.tf
vim apne1.tf
meld apne1.tf apne1.tf.off
rm apne1.tf
onoff apne1.tf.off
vim apne1.tf
meld dev/core/apne1.tf prod/core/usw2.tf
meld dev/core/apne1.tf prod/core/apne1.tf
meld apne1.tf usw2.tf
cp apne1.tf usw2.tf
vim apne1.tf
vim apne1.tf
vim apne1.tf
vim apne1.tf
cp apne1.tf usw2.tf
cp main.tf shared-apne1.tf
vim shared-apne1.tf
cp shared-apne1.tf shared-use1.tf
cp shared-apne1.tf shared-usw2.tf
ln -sf ../../_shared/core/shared-apne1.tf
cp main.tf shared-apne1.tf
vim shared-apne1.tf
cp shared-apne1.tf shared-use1.tf
cp shared-apne1.tf shared-usw2.tf
ln -sf ../../_shared/core/shared-apne1.tf
cat shared-apne1.tf
vim apne1.tf
ln -sf ../../_shared/core/shared-apne1.tf.tf
ln -sf ../../_shared/core/shared-apne1.tf
ln -sf ../../_shared/core/shared-apne1.tf.tf
ln -sf ../../_shared/core/shared-apne1.tf
mv shared-apne1.tf core-apne1.tf
mv core-apne1.tf apne1.tf
cat shared-apne1.tf
ln -sf ../../_shared/core/shared-apne1.tf.tf
ln -sf ../../_shared/core/shared-apne1.tf
git checkout -- apne1.tf
mv apne1.tf apne1-network.tf
vim apne1.tf
mv apne1.tf apne1-network.tf
aws s3 ls s3://u10-dev-lambda-artifact-apne1
aws s3 rm s3://u10-dev-lambda-artifact-apne1/phadviger.tar.gz
aws s3 rm s3://u10-dev-lambda-artifact-apne1/phadviger.tar.gz
aws s3 ls s3://u10-dev-lambda-artifact-apne1
aws s3 rm s3://u10-dev-lambda-artifact-apne1/phadviger.tar.gz
aws s3 ls s3://u10-dev-lambda-artifact-apne1
aws s3 rm s3://u10-dev-lambda-artifact-apne1/phadviger.tar.gz
aws s3 ls s3://u10-dev-lambda-artifact-apne1
aws s3 rm s3://u10-dev-lambda-artifact-apne1/phadviger.tar.gz
wget -qO- https://get.pnpm.io/install.sh | ENV="$HOME/.bashrc" SHELL="$(which bash)" bash -
pnpm
pnpm env install --global lts
pn
pn env
npx create-next-app@latest nextjs-dashboard --example "https://github.com/vercel/next-learn/tree/main/dashboard/starter-example" --use-pnpm
pn run dev
pn i
pn dev
pn
pn dev
pnpm i @vercel/postgres
pn dev
historyc | grep pn
historyc | grep pnmp
historyc | grep pnpm
pn env use --global lts
cp nvm.manual.bash pnpm.manual.bash
historyc | grep pnpm >> pnpm.manual.bash
historyc | grep pn >> pnpm.manual.bash
