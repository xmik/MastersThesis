# Master's Thesis

This is the source code used while working on Master's Thesis of title: Kubernetes Cluster Deployment for Production Environment

## Structure and specification

The main directories here are:
```
src/eks/ -- contains source code to manage a Kubernetes cluster with eksctl
src/kops/ -- contains source code to manage a Kubernetes cluster with kops
thesis-tex/ -- contains text of the Master's thesis
```

Using this repository one may:
* operate (create, test, delete) a Kubernetes cluster using eksctl
* operate (create, test, delete) a Kubernetes cluster using kops
* deploy autoscaler, backup solution (Velero) and logging (to AWS CloudWatch) with one command (after the prerequisites like IAM and S3 buckets are set)
* generate a pdf file with this Master's Thesis text (the first page is not generated)

For details, please read the PDF. Either generate it or download the file [thesis-manual.pdf](thesis-manual.pdf).

## Usage

### Generate a PDF file
Run a Dojo Docker container to ensure the development environment:
```
dojo
```

Generate the PDF:
```
pdflatex -interaction=nonstopmode -file-line-error thesis-tex/thesis.tex
bibtex thesis
pdflatex -interaction=nonstopmode -file-line-error thesis-tex/thesis.tex
```

The output file should be: `thesis.pdf`

### Operate a production ready Kubernetes cluster with eksctl
Run a Dojo Docker container to ensure the development environment:
```
cd src/
dojo
cd eks/
```

Choose an environment: testing or production:
```
eks$ export K8S_EXP_ENVIRONMENT=testing
```

Deploy the cluster (this takes ~25 minutes):
```
eks$ ./tasks _create
```

Deploy all the services needed to meet production requirements:
```
# first create the eks/credentials-velero file (see 5th chapter of the thesis)
eks$ ./tasks _enable_velero
eks$ ./tasks _enable_as
eks$ ./tasks _test
```

Delete the cluster (this takes ~6 minutes):
```
eks$ ./tasks _delete
```

### Operate a production ready Kubernetes cluster with kops
Run a Dojo Docker container to ensure the development environment:
```
cd src/
dojo
cd kops/
```

Choose an environment: testing or production:
```
kops$ export K8S_EXP_ENVIRONMENT=testing
```

Deploy the cluster (this takes ~6 minutes):
```
kops$ ./tasks _create
```

Deploy all the services needed to meet production requirements:
```
# first create the kops/credentials-velero file (see 5th chapter of the thesis)
kops$ ./tasks _enable_velero
kops$ ./tasks _enable_as
kops$ ./tasks _enable_logging
kops$ ./tasks _test
```

Delete the cluster (this takes ~6 minutes):
```
kops$ ./tasks _delete
```
