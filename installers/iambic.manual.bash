#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

docker pull --quiet public.ecr.aws/iambic/iambic:latest
docker system prune --force
docker history public.ecr.aws/iambic/iambic:latest
