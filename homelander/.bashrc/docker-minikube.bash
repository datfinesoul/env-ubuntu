# Using minikube for docker is only needed on mac ATM
if [[ "$(uname -s)" == "Darwin" ]]; then
  which -s minikube && eval $(minikube docker-env)
fi
