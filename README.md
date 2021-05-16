# minikube-starburst-demo

Scripts and templates to quickly setup a Starburst ([trino](https://trino.io) / PrestoSQL) demonstration environnement on a local minikube cluster.

Disclaimer
NB: This release does not form any part of the Starburst product. It is not officially released by Starburst, nor is it supported by Starburst, including by any of Starburst's Enterprise Support Agreements. It is made publicly and freely available purely for educational purposes.

Important
NB: Before you run bigbang.py: Make sure you do the following:

update my-vars.yaml, to specify your new setup
write helm-creds.yaml, to provide your login credentials for the helm repo—see my-vars.yaml file for description of what to put in there
add a Starburst license file, which you can get from your friendly local Starburst Solutions Architect!
go through the requirements section below to make sure you have all the dependencies before starting


Requirements:
- Minikube
- kubectl
- helm

Installation:
