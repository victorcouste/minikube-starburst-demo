
#!/bin/sh

# Starburst Harbor Helm repository credentials
USERNAME_HARBOR_CHART_REPO="username"
PASSWORD_HARBOR_CHART_REPO="xxxxxxxxx"

# Starburst Enterprise version
STARBURST_VERSION=356.1.0

# Start a single-node 6CPUs and 16GB memory minikube cluster
minikube start --cpus 6 --memory 16GB
kubectl cluster-info

# Add bitnami Helm repo and install PostgreSQL chart
helm repo add bitnami https://charts.bitnami.com/bitnami
echo "Install postgresql"
helm install postgresql bitnami/postgresql
echo "Wait postgresql"
sleep 30

# Get PostgreSQL default password
echo "Get password"
export POSTGRES_PASSWORD=$(kubectl get secret --namespace default postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
sleep 5
echo "PostgreSQL password: "$POSTGRES_PASSWORD
sleep 5

# Create an event_logger PostgreSQL database to store Starburst event logs and Insights data
echo "Create DB "
kubectl run postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:11.11.0-debian-10-r0 --env="PGPASSWORD=$POSTGRES_PASSWORD" --command -- psql --host postgresql -U postgres -d postgres -p 5432 -c 'CREATE DATABASE event_logger'

# Update chart values template files with PostgreSQL password and Starburst Helm repo credentials
echo "Update helm chart values files "
sed "s/__POSTGRES_PASSWORD__/$POSTGRES_PASSWORD/g; s/__USERNAME_HARBOR_CHART_REPO__/$USERNAME_HARBOR_CHART_REPO/g; s/__PASSWORD_HARBOR_CHART_REPO__/$PASSWORD_HARBOR_CHART_REPO/g;" starburst_values_template.yaml > starburst_values.yaml
sed "s/__USERNAME_HARBOR_CHART_REPO__/$USERNAME_HARBOR_CHART_REPO/g; s/__PASSWORD_HARBOR_CHART_REPO__/$PASSWORD_HARBOR_CHART_REPO/g;" ranger_values_template.yaml > ranger_values.yaml
sed "s/__USERNAME_HARBOR_CHART_REPO__/$USERNAME_HARBOR_CHART_REPO/g; s/__PASSWORD_HARBOR_CHART_REPO__/$PASSWORD_HARBOR_CHART_REPO/g;" hive_values_template.yaml > hive_values.yaml

sleep 10
echo "Deploy SE "

# Add Starburst Harbor Helm repository
helm repo add --username $USERNAME_HARBOR_CHART_REPO --password $PASSWORD_HARBOR_CHART_REPO starburstdata https://harbor.starburstdata.net/chartrepo/starburstdata
sleep 10

# Create Starburst secret for license keys
kubectl create secret generic starburstdata --from-file=starburstdata.license
sleep 20

# Install Ranger Helm chart
helm install ranger starburstdata/starburst-ranger --version $STARBURST_VERSION --values ranger_values.yaml
sleep 30

# Install Hive Helm chart
helm install hive starburstdata/starburst-hive --version $STARBURST_VERSION --values hive_values.yaml
sleep 30

# Install Starburst Helm chart
helm install starburst-enterprise starburstdata/starburst-enterprise --version $STARBURST_VERSION --values starburst_values.yaml
sleep 30

# List Helm releases
helm list
# List deployements
kubectl get deployments
# List pods status
kubectl get pods -o wide
# List services status
kubectl get services

echo "Deployment ...... (4 minutes) "

#while :;do for s in / - \\ \|; do printf "\r$s";sleep 60;done;done

sleep 60
echo '#####                 (25%)'
kubectl get pods -o wide
sleep 60
echo '##########            (50%)'
kubectl get pods -o wide
sleep 60
echo '###############       (75%)'
kubectl get pods -o wide
sleep 60
echo '####################  (100%)'


helm list
kubectl get deployments
kubectl get pods -o wide
kubectl get services

# Get Ranger UI URL
ranger_url=$(minikube service ranger --url)
echo "url "$ranger_url
echo "admin/RangerPassword1"
open $ranger_url

# Get Starburst Insights UI URL
starburst_url=$(minikube service starburst --url)
echo "url "$starburst_url'/ui/insights'
echo "user : starburst_service"

open $starburst_url'/ui/insights'

# If you want to connect to the cluster from a local client
echo "kubectl port-forward service/starburst 7080:8080"
echo "http://localhost:7080"
echo "jdbc:trino://localhost:7080"

# To  open minikube dashboard (Kubernetes dashboard UI for applications and cluster management/monitoring) at
echo "http://127.0.0.1:65401/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy"
minikube dashboard






