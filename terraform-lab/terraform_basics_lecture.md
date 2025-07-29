# Terraform Basics - Lecture Notes

## 📘 Introduction to Infrastructure as Code (IaC)

Infrastructure as Code (IaC) is the practice of managing and provisioning computing infrastructure using machine-readable configuration files. IaC eliminates the need for manual processes and allows for automation, version control, and repeatability.

**Benefits of IaC:**

* Version-controlled infrastructure
* Reusability and modularity
* Automation and consistency
* Easier collaboration and auditing

## 🚀 What is Terraform?

Terraform is an open-source IaC tool developed by HashiCorp. It allows you to define infrastructure in a high-level configuration language called HashiCorp Configuration Language (HCL). With Terraform, you can provision, manage, and automate your infrastructure across multiple cloud providers and services.

## 🌐 Providers

Providers are plugins that allow Terraform to interact with cloud platforms or other APIs. Each provider is responsible for understanding API interactions and exposing resources.

**Examples:**

* `aws` (Amazon Web Services)
* `azurerm` (Microsoft Azure)
* `google` (Google Cloud Platform)

## 🧱 Resources

Resources are the most important element in a Terraform configuration. They represent the infrastructure components, such as servers, databases, and networking components.

```hcl
resource "aws_instance" "example" {
  ami           = "ami-123456"
  instance_type = "t2.micro"
}
```

## 🔢 Variables

Variables allow customization and parameterization of Terraform configurations.

### Types of Variables

Terraform supports several variable types:

* **string**: A sequence of characters.
* **number**: Numeric values.
* **bool**: Boolean values (`true` or `false`).
* **list**: An ordered sequence of values.
* **map**: A key-value pair.
* **object**: A collection of named attributes that each have their own type.

### Declaring Variables

```hcl
variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
  default     = "t2.micro"
}
```

### Using Variables

```hcl
resource "aws_instance" "example" {
  ami           = "ami-123456"
  instance_type = var.instance_type
}
```

### Providing Variable Values

* **Command line**: `terraform apply -var="instance_type=t3.micro"`
* **Variable file**: `terraform.tfvars` or custom files with `-var-file`

```hcl
# terraform.tfvars
instance_type = "t3.micro"
```

* **Environment variables**: `TF_VAR_instance_type="t3.micro"`

### Sensitive Variables

To avoid logging or showing secret values:

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}
```

## ⚙️ Terraform Init

`terraform init` initializes the working directory containing Terraform configuration files. It downloads the required providers and sets up the backend if configured.

```bash
terraform init
```

**Purpose:**

* Downloads provider plugins
* Sets up backend configuration
* Prepares the environment for planning and applying changes

## 🧮 Terraform Plan

`terraform plan` shows the changes Terraform will make to your infrastructure without applying them. It is a dry-run that helps you understand what will happen before you execute changes.

```bash
terraform plan
```

**Purpose:**

* Displays actions that will be taken
* Helps avoid unexpected changes
* Essential for review in CI/CD pipelines

## 📤 Terraform Apply

`terraform apply` executes the changes required to reach the desired state described in the configuration files.

```bash
terraform apply
```

**Purpose:**

* Creates or updates infrastructure
* Applies changes after user approval (or automatically with `-auto-approve`)

## 📥 Outputs

Outputs in Terraform allow you to display or export specific values after your infrastructure is applied.

### Declaring Outputs

```hcl
output "instance_ip" {
  value = aws_instance.example.public_ip
}
```

### Accessing Outputs

```bash
terraform output instance_ip
```

Use outputs to:

* View important data after apply
* Pass values to modules or external systems

## 🔁 Idempotency

Idempotency ensures that applying the same configuration multiple times results in the same infrastructure state. Terraform compares the desired state with the current infrastructure and only makes necessary changes.

## 📂 State File (`terraform.tfstate`)

Terraform stores the state of the infrastructure in a state file. This file maps your configuration to the real-world resources.

**Importance:**

* Tracks the current state
* Used to determine changes on `terraform apply`

## 🔒 Lock File (`.terraform.lock.hcl`)

The lock file records the provider versions in use, ensuring consistent behavior across environments.

## ☁️ Remote Backends (S3 + DynamoDB Example)

Using remote backends allows you to store state files in a shared location, enabling team collaboration and avoiding conflicts.

**Common Setup:**

* Store `terraform.tfstate` in **S3**
* Use **DynamoDB** table to handle state locking and consistency

## 🔄 Terraform Import

Allows importing existing infrastructure into your Terraform state without recreating it.

```bash
terraform import aws_instance.example i-0abcd1234
```

## 🧩 Modules

Modules help organize and reuse Terraform code. You can split complex infrastructure into smaller, manageable components. Modules can be **local** or **remote**.

### Local Module Example

```hcl
module "vpc" {
  source = "./modules/vpc"
  cidr_block = "10.0.0.0/16"
}
```

### Remote Module Example

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"
  name    = "my-vpc"
  cidr    = "10.0.0.0/16"
}
```

**Notes:**

* Local modules are stored in your project directory.
* Remote modules are pulled from Terraform Registry or other sources like GitHub.

## ⚠️ Terraform Taint

Marks a resource for recreation during the next apply.

```bash
terraform taint aws_instance.example
```

## ✅ Terraform Validate

Validates the Terraform configuration files for syntax errors and internal consistency.

```bash
terraform validate
```

---

✅ **Summary:** Terraform enables you to define infrastructure declaratively and manage it efficiently with automation, modularity, and best practices. Understanding core concepts like providers, variables, resources, state management, and lifecycle commands (`init`, `plan`, `apply`, `taint`, etc.) is essential to mastering Terraform.
