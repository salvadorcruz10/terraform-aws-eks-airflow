# terraform-aws-eks-airflow

The general overview of the cluster is this:

![diagram](diagram.png)

The current architecture was implemented following this guide [Provisioning an EKS Cluster guide](https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster)

### Prerequisites

AWS account configured. For this example we are using default profile and us-east-2 region

#### Dependencies
- Cluster version: 1.15 (Specified in terraform.tfvars, version 1.16 seems not to be working when using Helm)
- Terraform >= 0.12

### Installing

To have K8s cluster running:

Execute Terraform commands:

```
terraform init --var-file=terraform.tfvars
```
```
terraform apply --var-file=terraform.tfvars
```
Once that the cluster is created, set the kubectl context:

```
aws eks --region <your-region> update-kubeconfig --name <your-cluster-name>
```

Create a namespace for airflow deployment:
```
kubectl create namespace airflow
```

To destroy the EKS cluster, we run:

```
terraform destroy --var-file=terraform.tfvars
```

## For Helm 2

Initialize the tiller:
```
kubectl apply -f kubernetes/helm/tiller.yaml
helm init --service-account tiller
```

Configure the EFS role:
```
kubcetl apply -f kubernetes/yaml/efs/role.yaml
``` 

Replace the efs-id in [values-efs.yaml](kubernetes/helm/values-efs.yaml)
```
...
  efsFileSystemId: <efs-id>
  awsRegion: us-east-2
...
```

Install efs-provisioner:
```
helm install --name efs-provisioner stable/efs-provisioner -f kubernetes/helm/values-efs.yaml
```

Create the PVC:
```
kubectl apply -f kubernetes/yaml/efs/efs-pvc.yaml
```

Override values.yaml (this file is used to customize the installation using Helm). In the example below, we are setting the number of worker replicas, all possible values can be seen in [values.yaml](https://github.com/helm/charts/blob/master/stable/airflow/values.yaml):

```
...
workers:
  replicas: 2
...
```

Once we have everything set in our values.yaml file, we can execute the Helm command:

```
helm install stable/airflow --version 4.9.0 --name "airflow" --namespace "airflow" -f kubernetes/helm/values-airflow.yaml 
```

We can verify that our pods are up and running by executing:

```
kubectl get pods -n airflow 
```

To get the airflow URL, we execute, and paste the DNS name that we will find for the external IP  under our airflow service:

```
kubectl get svc -n airflow 
```

### Removing components

To delete the Helm chart, we run:

```
helm del --purge airflow 
```

## For Helm 3

Here we are using Astronomer as example, but, can also been installed any other Airflow distribution.

Add the chart repository and confirm:
```
helm repo add astronomer https://helm.astronomer.io
helm repo list
```
Install the airflow chart from the repository:
```
helm install airflow astronomer/airflow -n airflow
```
We can verify that our pods are up and running by executing:
```
kubectl get pods -n airflow
```


### Accessing to Airflow dashboard

To get the airflow URL, we execute, and paste the DNS name that we will find for the external IP under our airflow service:
````
kubectl get svc -n airflow
````
Use the default user/password defined in values.yaml file:
```
User:       <example-user>
Password:   <example-password>
```
If you want to customize your installation, override the `values.yaml` file and upgrade your deployment:
```
helm upgrade airflow astronomer/airflow -f values.yaml -n airflow
```
All possible values can be seen in [values.yaml](https://github.com/helm/charts/blob/master/stable/airflow/values.yaml):


## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) to know about the process for submitting pull requests to us.

## Acknowledgments

This solution was based on this guide: [Provision an EKS Cluster learn guide](https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster), containing
Terraform configuration files to provision an EKS cluster on AWS.