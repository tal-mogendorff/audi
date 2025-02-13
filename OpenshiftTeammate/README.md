# 🤖 OpenShift Conversational Proxy

[Previous sections remain the same until Quick Start]

## 🚀 Quick Start

### Prerequisites

Before you begin, ensure you have:
- Terraform v1.0+ installed
- OpenShift CLI (oc) installed
- Access to an OpenShift cluster
- Kubiya API key
- JIRA instance configured for webhooks

### Installation Steps

1. **Create Your Terraform Working Directory**:
```bash
mkdir openshift-proxy
cd openshift-proxy
```

2. **Create the Following Files**:

**main.tf**:
```hcl
terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
  }
}

provider "kubiya" {
  // API key is set as an environment variable KUBIYA_API_KEY
}

# Store OpenShift Password in Kubiya secrets store
resource "kubiya_secret" "openshift_password" {
    name     = "OPENSHIFT_PASSWORD"
    value    = "${var.openshift_password}"
    description = "OpenShift password for authentication"
}

# Configure the source for OpenShift CLI
resource "kubiya_source" "openshift_source" {
  url  = "https://github.com/kubiyabot/community-tools/tree/main/openshift_cli"
  runner = var.kubiya_runner
}

# Create the OpenShift proxy assistant
resource "kubiya_agent" "openshift_teammate" {
  name         = "OpenShift Expert"
  runner       = var.kubiya_runner
  description  = "I am an OpenShift expert. I can help you with OpenShift operations, such as creating projects, deploying applications, and managing resources."
  instructions = ""
  environment_variables = {
    OPENSHIFT_URL:      var.openshift_url,
    OPENSHIFT_USERNAME: var.openshift_username,
  }
  sources = [kubiya_source.openshift_source.name]
  secrets = ["OPENSHIFT_PASSWORD"]
  groups  = ["Admins", "Users"]
  integrations = ["slack"]

  depends_on = [kubiya_secret.openshift_password, kubiya_source.openshift_source]
}

# Configure JIRA webhook integration
resource "kubiya_webhook" "jira_webhook" {
  filter = ""
  name   = "${kubiya_agent.openshift_teammate.name}-jira-webhook"
  source = "JIRA"
  prompt = <<-EOT
    Title: {{event.issue.summary}}
    Body: {{event.issue.description}}
  EOT
  agent       = kubiya_agent.openshift_teammate.name
  destination = "social"
  depends_on  = [kubiya_agent.openshift_teammate]
}

# Output configuration details
output "openshift_cli_teammate" {
  value = {
    name         = kubiya_agent.openshift_teammate.name
    runner       = var.kubiya_runner
    integrations = kubiya_agent.openshift_teammate.integrations
    webhook      = kubiya_webhook.jira_webhook.name
  }
  description = "Details about the deployed OpenShift CLI teammate"
}
```

**variables.tf**:
```hcl
variable "openshift_url" {
  description = "🌐 OpenShift URL (e.g., https://openshift.example.com)"
  type        = string

  validation {
    condition     = can(regex("^(http|https)://", var.openshift_url))
    error_message = "🚫 OpenShift URL must start with http:// or https://"
  }
}

variable "openshift_username" {
  description = "👤 OpenShift username for Cluster access"
  type        = string
  default     = ""
}

variable "openshift_password" {
  description = "🔑 OpenShift password for authentication (sensitive)"
  type        = string
  sensitive   = true
}

variable "kubiya_runner" {
  description = "🏃 Infrastructure runner that will execute the OpenShift operations"
  type        = string
}
```

**terraform.tfvars** (create this file and add your values):
```hcl
openshift_url      = "https://your-openshift-cluster.example.com"
openshift_username = "your-username"
kubiya_runner      = "kubiya-hosted"
# Do not put sensitive values in this file
```

3. **Set Environment Variables**:
```bash
# Set your Kubiya API key
export KUBIYA_API_KEY="your-api-key"

# Set sensitive variables (recommended over tfvars)
export TF_VAR_openshift_password="your-openshift-password"
```

4. **Initialize Terraform**:
```bash
# Initialize Terraform and download required providers
terraform init
```

5. **Review the Deployment Plan**:
```bash
# See what resources will be created
terraform plan
```

6. **Apply the Configuration**:
```bash
# Deploy the resources
terraform apply
```

7. **Verify the Deployment**:
```bash
# Check the outputs
terraform output openshift_cli_teammate
```

### Post-Installation Setup

1. **Configure JIRA Webhook**:
   - Go to your JIRA settings
   - Navigate to System > WebHooks
   - Create a new webhook using the URL from the Terraform output
   - Configure the events you want to trigger the webhook

2. **Verify Integration**:
   - Create a test JIRA issue
   - Verify the webhook triggers successfully
   - Check Slack for the notification (if configured)

3. **Test OpenShift Connection**:
   Try basic commands like:
   ```
   Ask the OpenShift Expert: "List all projects"
   ```

### Updating Configuration

To update your deployment:

1. Modify the relevant `.tf` files
2. Run:
```bash
terraform plan  # Review changes
terraform apply # Apply changes
```

### Cleanup

To remove all created resources:
```bash
terraform destroy
```

[Rest of the document remains the same...]
