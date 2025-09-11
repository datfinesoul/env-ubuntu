#!/usr/bin/env bash

alias aws-delete-secret-permanently=aws_delete_secret_permanently
aws_delete_secret_permanently () {
local REGION NAME
REGION="${1}"
NAME="${2}"
aws --region "${REGION}" secretsmanager restore-secret --secret-id "${NAME}"
aws --region "${REGION}" secretsmanager delete-secret --force-delete-without-recovery --secret-id "${NAME}"
echo "aws --region '${REGION}' secretsmanager get-secret-value --secret-id '${NAME}'"
}

# Call the function with all arguments
aws_delete_secret_permanently "$@"
