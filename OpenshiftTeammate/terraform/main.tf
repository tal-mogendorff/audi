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

# Create the Jenkins proxy assistant
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

resource "kubiya_webhook" "jira_webhook" {
  filter = ""
  
  name        = "${kubiya_agent.openshift_teammate.name}-jira-webhook"
  source      = "K8S"
  prompt      = <<-EOT
   Title: {{event.issue.summary}}
   Body: {{event.issue.description}}
    EOT
  agent       = "${kubiya_agent.openshift_teammate.name}"
  destination = "social"
  depends_on = [
    kubiya_agent.openshift_teammate
  ]
}

# Output the teammate jenkins_proxy 
output "openshift_cli_teammte" {
  value = {
    name         = kubiya_agent.openshift_teammate.name
    runner       = var.kubiya_runner
    integrations = kubiya_agent.openshift_teammate.integrations
    webhook      = kubiya_webhook.jira_webhook.name
  }
  description = "Details about the deployed OpenShift CLI teammate"
} 