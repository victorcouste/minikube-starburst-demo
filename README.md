# minikube-starburst-demo

Command line, script and templates to quickly setup a [Starburst Enterprise](https://www.starburst.io/platform/starburst-enterprise/) demonstration environnement on a small and local [Kubernetes](https://kubernetes.io) cluster.

The goal is to deploy Starburst Enterprise (based on [trino](https://trino.io) / PrestoSQL MPP SQL engine), [Apache Ranger](https://ranger.apache.org), a Hive metastore and a PostgreSQL database to a single-node Kubernetes [minikube](https://github.com/kubernetes/minikube) cluster. Deployments to the cluster are done via [Helm](https://helm.sh) charts installations.


## Disclaimer

NB: *This release does not form any part of the Starburst product. It is not officially released by Starburst, nor is it supported by Starburst, including by any of Starburst's Enterprise Support Agreements. It is made publicly and freely available purely for educational purposes.*

## Important

NB: Before you run mini-starburst.sh: Make sure you do the following:

- Add in your folder a Starburst license file (**starburstdata.license**), which you can get from your friendly local Starburst Solutions Architect!
- Get login credentials for the Starburst Harbor Helm Charts repository.
- Update mini-starburst.sh with these credentials.
- In mini-starburst.sh you can also update Starburst Enterprice version to be deployed.
- Go through the requirements section below to make sure you have all the dependencies before starting.


## Requirements:
- minikube [Installation instruction](https://minikube.sigs.k8s.io/docs/start) (no need to start a cluster)
- kubectl [Installation instructions](https://kubernetes.io/docs/tasks/tools)
- Helm [Installation instructions](https://helm.sh/docs/intro/install)
 
## Run:

```
mini-starburst.sh
```

## Command line explanation

Main commend line executed in mini-starburst.sh:

```
# Start a 6CPUs and 16GB memory minikube cluster
minikube start --cpus 6 --memory 16GB

# Add bitnami Helm repo to install PostgreSQL chart
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install postgresql bitnami/postgresql

# Get PostgreSQL default password
export POSTGRES_PASSWORD=$(kubectl get secret --namespace default postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)

# Create an event_logger PostgreSQL database to store Starburst event logs and Insights UI data
kubectl run postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:11.11.0-debian-10-r0 --env="PGPASSWORD=$POSTGRES_PASSWORD" --command -- psql --host postgresql -U postgres -d postgres -p 5432 -c 'CREATE DATABASE event_logger'

# Update chart values template files with PostgreSQL password and Starburst Harbor Helm repo credentials
sed "s/__POSTGRES_PASSWORD__/$POSTGRES_PASSWORD/g; s/__USERNAME_HARBOR_CHART_REPO__/$USERNAME_HARBOR_CHART_REPO/g; s/__PASSWORD_HARBOR_CHART_REPO__/$PASSWORD_HARBOR_CHART_REPO/g;" starburst_values_template.yaml > starburst_values.yaml
sed "s/__USERNAME_HARBOR_CHART_REPO__/$USERNAME_HARBOR_CHART_REPO/g; s/__PASSWORD_HARBOR_CHART_REPO__/$PASSWORD_HARBOR_CHART_REPO/g;" ranger_values_template.yaml > ranger_values.yaml
sed "s/__USERNAME_HARBOR_CHART_REPO__/$USERNAME_HARBOR_CHART_REPO/g; s/__PASSWORD_HARBOR_CHART_REPO__/$PASSWORD_HARBOR_CHART_REPO/g;" hive_values_template.yaml > hive_values.yaml

# Add Starburst Harbor Helm repo
helm repo add --username $USERNAME_HARBOR_CHART_REPO --password $PASSWORD_HARBOR_CHART_REPO starburstdata https://harbor.starburstdata.net/chartrepo/starburstdata

# Create Starburst secret for the license file
kubectl create secret generic starburstdata --from-file=starburstdata.license

# Install Ranger Helm chart
helm install ranger starburstdata/starburst-ranger --version $STARBURST_VERSION --values ranger_values.yaml

# Install Hive Helm chart
helm install hive starburstdata/starburst-hive --version $STARBURST_VERSION --values hive_values.yaml

# Install Starburst Helm chart
helm install starburst-enterprise starburstdata/starburst-enterprise --version $STARBURST_VERSION --values starburst_values.yaml

# List Helm releases
helm list
# List deployements
kubectl get deployments
# List pods status
kubectl get pods -o wide
# List services status
kubectl get services

# Get Ranger UI URL
ranger_url=$(minikube service ranger --url)
# Connect with admin/RangerPassword1 credentials

# Get Starburst Insights UI URL
starburst_url=$(minikube service starburst --url)
starburst_insights_url=$starburst_url'/ui/insights'
# Connect with starburst_service user

# If you want to connect to the cluster from a local client
kubectl port-forward service/starburst 7080:8080"
# New URL http://localhost:7080
# JDBC connection string jdbc:trino://localhost:7080

# To  open minikube dasboard (Kubernetes admin UI) in http://127.0.0.1:65401/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy"
# Command : minikube dashboard

```
