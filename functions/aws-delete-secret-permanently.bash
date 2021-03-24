aws-delete-secret-permanently () {
local REGION NAME
REGION="${1}"
NAME="${2}"
aws --region "${REGION}" secretsmanager restore-secret --secret-id "${NAME}"
aws --region "${REGION}" secretsmanager delete-secret --force-delete-without-recovery --secret-id "${NAME}"
echo "aws --region '${REGION}' secretsmanager get-secret-value --secret-id '${NAME}'"
}
