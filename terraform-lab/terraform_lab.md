# 🚀 Terraform Lab: Launch EC2 with NGINX and S3 Backend

## 🧠 Overview

In this lab, you'll use **Terraform** to provision infrastructure on AWS, including:

* VPC, Subnet, Internet Gateway, Route Table
* Security Group for SSH and HTTP
* EC2 instance running Ubuntu with NGINX installed
* Remote state using **S3 backend with DynamoDB for locking**

This lab demonstrates the correct order of Terraform operations when working with backends and authentication.

---

## 📁 Step 1: Clone the Lab Repository

```bash
git clone https://github.com/mohammedd2510/Route-Labs.git
cd Route-Labs/terraform-lab
```

---

## 💪 Step 2: Modify Backend Configuration

Open `backend.tf` and update the following block , update the bucket with your own s3 bucket and update dynamodb\_table with your own dynamodb table:

```hcl
terraform {
  backend "s3" {
    bucket         = "REPLACE_ME_WITH_YOUR_BUCKET"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "REPLACE_ME_WITH_YOUR_DYNAMODB_TABLE"
    encrypt        = true
  }
}
```

---

## ❌ Step 3: **Remove Credential Variables**

Before initializing Terraform, you must:

* Delete the following from your code:

  ```hcl
  variable "aws_access_key" {}
  variable "aws_secret_key" {}
  ```
* And update the `provider` block to **remove** the `access_key` and `secret_key` lines:

  ```hcl
  provider "aws" {
    region = "us-east-1"
  }
  ```

This is because the `backend` is initialized **before variables** or `provider` credentials — using them causes errors.

---

## 🔐 Step 4: Export AWS Credentials

To authenticate, export your AWS credentials **as environment variables**:

```bash
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret-key
```

This is **required before running `terraform init`**, because Terraform needs to access the S3 backend and DynamoDB.

---

## 🔑 Step 5: Set Your EC2 Key Pair

Before proceeding, open `terraform.tfvars` or your variable file and set the `key_name` variable to the name of an **existing EC2 Key Pair** that you previously created in the AWS Console. This allows you to SSH into the provisioned EC2 instance.

```hcl
key_name = "your-keypair-name"
```

> You can create a key pair in the AWS Console under EC2 → Key Pairs.

---

## ⚙️ Step 6: Initialize Terraform

```bash
terraform init
```

This initializes the backend and downloads the AWS provider plugin.

---

## 🔍 Step 7: Plan the Infrastructure

```bash
terraform plan
```

You'll see a preview of the AWS resources Terraform will create.

---

## 🚀 Step 8: Apply and Create Infrastructure

```bash
terraform apply
```

This provisions:

* A new VPC, subnet, internet gateway, route table
* A security group for SSH (22) and HTTP (80)
* An EC2 instance with NGINX installed via `user_data`

---

## 🌐 Step 9: Access the Web Server

After the apply is complete, Terraform will output something like:

```
Outputs:
public_ip = "3.92.X.X"
web_url   = "http://3.92.X.X"
```

Open the URL in your browser and confirm NGINX is running.

---

## 🧹 Step 10: Destroy Resources

After verifying, destroy the environment to avoid AWS charges:

```bash
terraform destroy
```

---

## 🎯 Learning Objectives Recap

✅ Understand how to configure and authenticate S3 backend
✅ Learn why credentials must be exported when using backends
✅ Practice full Terraform flow: `init → plan → apply → destroy`
✅ Validate infrastructure output and functionality
