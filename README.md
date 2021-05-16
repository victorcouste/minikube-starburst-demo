# minikube-starburst-demo

Command line, script and templates to quickly setup a [Starburst Enterprise](https://www.starburst.io/platform/starburst-enterprise/) demonstration environnement on a local [minikube](https://github.com/kubernetes/minikube) cluster.

The goal is to deploy Starburst Enterprise (based on [trino](https://trino.io) / PrestoSQL MPP SQL engine), [Apache Ranger](https://ranger.apache.org), a Hive metastore and a PostgreSQL database in a Kubernetes minikube cluster.


**Disclaimer**

NB: *This release does not form any part of the Starburst product. It is not officially released by Starburst, nor is it supported by Starburst, including by any of Starburst's Enterprise Support Agreements. It is made publicly and freely available purely for educational purposes.*

**Important**

NB: Before you run mini-starburst.sh: Make sure you do the following:

- Add in your folder a Starburst license file (**starburstdata.license**), which you can get from your friendly local Starburst Solutions Architect!
- Get login credentials for the Starburst Harbor Helm Charts repository.
- Update mini-starburst.sh with these credentials.
- Go through the requirements section below to make sure you have all the dependencies before starting


**Requirements**:
- Minikube [Installation instruction](https://minikube.sigs.k8s.io/docs/start)
- kubectl [Installation instructions](https://kubernetes.io/docs/tasks/tools)
- Helm [Installation instructions](https://helm.sh/docs/intro/install)