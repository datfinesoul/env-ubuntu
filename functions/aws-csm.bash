aws-csm () {
AWS_CSM_ENABLED='true'
AWS_CSM_PORT='31000'
AWS_CSM_HOST='127.0.0.1'
export AWS_CSM_ENABLED AWS_CSM_PORT AWS_CSM_HOST
if [[ "${1:-}" == "--proxy" ]]; then
	shift
  HTTP_PROXY='http://127.0.0.1:10080'
  HTTPS_PROXY='http://127.0.0.1:10080'
  AWS_CA_BUNDLE=~/.iamlive/ca.pem
  export HTTP_PROXY HTTPS_PROXY AWS_CA_BUNDLE
fi
}
