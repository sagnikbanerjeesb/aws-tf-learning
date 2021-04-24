## Demo terraform code to deploy [dobby](https://github.com/thecasualcoder/dobby) on an ecs cluster and expose it via alb

### Pre-requisites:
- Terraform
- AWS account
- IAM user which will be used to provision infra
  - It needs to have access to:
    - IAM
    - ElasticLoadBalancing
    - AmazonS3
    - AmazonECS
    - AmazonVPC

### Setup:
Need to expose env vars (reqd for provision and destroy operations as well):
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
```bash
terraform init
```

### Provision:
```bash
terraform apply
```

### Validation:
- Hit dobby apis using the DNS Name (on port 80 as of now) of the alb 
(which should have been printed as an output of the terraform script)

### Destroy:
```bash
terraform destroy
```