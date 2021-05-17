
#!/bin/sh
spinner () {
secs=$1
SECONDS=0
while (( SECONDS < $secs ));do for s in / - \\ \|; do printf "\r$s";sleep .1;done;done
}

#----------------------------------------------------------------------------------

# Starburst Harbor Helm repository credentials
USERNAME_HARBOR_CHART_REPO="username"
PASSWORD_HARBOR_CHART_REPO="xxxxxxxx"

# Starburst Enterprise version
STARBURST_VERSION=356.1.0

echo "\n---------------------------------"
echo " minikube cluster creation"
echo "---------------------------------\n"

# Start a single-node 6CPUs and 16GB memory minikube cluster named "starburst-demo"
minikube start --cpus 6 --memory 16GB --profile starburst-demo
echo "\n minikube cluster status"
kubectl cluster-info

echo "\n---------------------------------------------------"
echo "   Requirements installation and configuration"
echo "---------------------------------------------------\n"

echo "Add bitnami Helm repository and install PostgreSQL chart"
helm repo add bitnami https://charts.bitnami.com/bitnami
echo "\nPostgreSQL installation\n "
helm install postgresql bitnami/postgresql
echo "\n PostgreSQL deployment in progress..."
spinner 30

echo "\nGet PostgreSQL default password...\n"
export POSTGRES_PASSWORD=$(kubectl get secret --namespace default postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
spinner 5
echo "PostgreSQL default password: "$POSTGRES_PASSWORD
spinner 5

echo "\nCreate event_logger PostgreSQL database to store Starburst event logs and Insights data..."
kubectl run postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:11.11.0-debian-10-r0 --env="PGPASSWORD=$POSTGRES_PASSWORD" --command -- psql --host postgresql -U postgres -d postgres -p 5432 -c 'CREATE DATABASE event_logger'
spinner 10

echo "\nUpdate chart values template files with PostgreSQL password and Starburst Helm repo credentials..."
sed "s/__POSTGRES_PASSWORD__/$POSTGRES_PASSWORD/g; s/__USERNAME_HARBOR_CHART_REPO__/$USERNAME_HARBOR_CHART_REPO/g; s/__PASSWORD_HARBOR_CHART_REPO__/$PASSWORD_HARBOR_CHART_REPO/g;" starburst_values_template.yaml > starburst_values.yaml
sed "s/__USERNAME_HARBOR_CHART_REPO__/$USERNAME_HARBOR_CHART_REPO/g; s/__PASSWORD_HARBOR_CHART_REPO__/$PASSWORD_HARBOR_CHART_REPO/g;" ranger_values_template.yaml > ranger_values.yaml
sed "s/__USERNAME_HARBOR_CHART_REPO__/$USERNAME_HARBOR_CHART_REPO/g; s/__PASSWORD_HARBOR_CHART_REPO__/$PASSWORD_HARBOR_CHART_REPO/g;" hive_values_template.yaml > hive_values.yaml
spinner 10

echo "\n---------------------------------------------------"
echo "          Starburst Enterprise deployment"
echo "---------------------------------------------------\n"

echo "Add Starburst Harbor Helm repository"
helm repo add --username $USERNAME_HARBOR_CHART_REPO --password $PASSWORD_HARBOR_CHART_REPO starburstdata https://harbor.starburstdata.net/chartrepo/starburstdata
spinner 10
echo "\nCreate Starburst secret for license keys"
kubectl create secret generic starburstdata --from-file=starburstdata.license
spinner 20
echo "\nInstall Ranger Helm chart...\n"
helm install ranger starburstdata/starburst-ranger --version $STARBURST_VERSION --values ranger_values.yaml
spinner 30
echo "\nInstall Hive Helm chart...\n"
helm install hive starburstdata/starburst-hive --version $STARBURST_VERSION --values hive_values.yaml
spinner 30
echo "\nInstall Starburst Enterprise Helm chart...\n"
helm install starburst-enterprise starburstdata/starburst-enterprise --version $STARBURST_VERSION --values starburst_values.yaml
spinner 30

echo "Helm releases"
helm list
echo "\nCluster Deployements"
kubectl get deployments
echo "\nCluster Pods"
kubectl get pods -o wide
echo "\nCluster Services"
kubectl get services

echo "\nApplications deployment in progress... (4 minutes)"
spinner 70
kubectl get pods -o wide
echo "\n25% done, 3 minutes left"
spinner 70
kubectl get pods -o wide
echo "\n50% done, 2 minutes left"
spinner 70
kubectl get pods -o wide
echo "\n75% done, 1 minute left"
spinner 70

echo "\n---------- Deployments finished - Final status ------------\n"

helm list
kubectl get deployments
kubectl get pods -o wide
kubectl get services

echo "\n----------------------------------------------------------------------------------"
echo "  Opening in a Web browser:"
echo "    - Starburst Enterprise Insights UI to monitor and query the Starburst cluster"
echo "    - Ranger UI to manage users, roles and permission policies"
echo "    - Kubernetes dashboard UI to manage applications and the cluster"
echo "----------------------------------------------------------------------------------\n"

ranger_url=$(minikube service ranger --url --profile starburst-demo)
echo "Ranger UI URL "$ranger_url
echo "Login with admin/RangerPassword1 credentials\n"
open $ranger_url

starburst_url=$(minikube service starburst --url --profile starburst-demo)
echo "Starburst Insights UI URL "$starburst_url'/ui/insights'
echo "Login with starburst_service user\n"
open $starburst_url'/ui/insights'

echo "If you want to connect to the cluster from a local client:"
echo "Command to execute :  kubectl port-forward service/starburst 7080:8080"
echo "New URL http://localhost:7080/ui/insights"
echo "JDBC URL jdbc:trino://localhost:7080"

echo "\nOpen minikube dashboard (Kubernetes dashboard UI for applications and cluster management/monitoring)\n"
minikube dashboard --profile starburst-demo