# CI/CD Guide for Multi-Environment Deployments

This document outlines the strategy for managing multiple environments (`development`, `non-production`, `production`) using Google Cloud Build and a Git branching strategy.

## Environment Strategy

Each environment is tied to a specific Git branch:

*   **`development` branch**: Deploys to the `development` GCP environment.
*   **`non-production` branch**: Deploys to the `non-production` GCP environment.
*   **`main` branch**: Deploys to the `production` GCP environment.

## Cloud Build Triggers

You will need to create a separate Cloud Build trigger for each of these branches. Each trigger will be configured to use a different set of input variables and a different Terraform state file, ensuring that the environments remain isolated.

### Trigger Configuration

*   **Name**: A descriptive name for the trigger (e.g., "deploy-development", "deploy-production").
*   **Event**: "Push to a branch".
*   **Source**:
    *   **Repository**: Your `aviato-cloud-foundation-fabric` repository.
    *   **Branch**: The name of the environment-specific branch (e.g., `^development$`, `^main$`).
*   **Configuration**:
    *   **Type**: "Cloud Build configuration file (yaml or json)".
    *   **Location**: `/cloudbuild.yaml`.
*   **Substitution variables**: This is where you'll define the environment-specific configurations. For example:
    *   `_TERRAFORM_STATE_BUCKET`: `gs://your-tf-state-bucket/development`
    *   `_TERRAFORM_VARS_FILE`: `development.tfvars`

## Terraform Configuration

To support this multi-environment setup, you will need to:

1.  **Create environment-specific `.tfvars` files**: For example, `development.tfvars`, `non-production.tfvars`, and `production.tfvars`. These files will contain the environment-specific settings, such as machine types, project IDs, and network configurations.

2.  **Parameterize your Terraform backend**: Your Terraform backend configuration (`backend.tf`) should be parameterized to use the `_TERRAFORM_STATE_BUCKET` substitution variable, so that each environment uses a different state file.

## Workflow

1.  **Development**: Developers create feature branches off of the `development` branch. When they open a pull request to merge their feature branch into `development`, the Cloud Build pipeline runs a `terraform plan` and posts the plan to the PR.
2.  **Approval**: After the PR is reviewed and the plan is approved, the code is merged into the `development` branch.
3.  **Deployment to Development**: The merge to the `development` branch triggers the "deploy-development" Cloud Build trigger, which applies the Terraform configuration to the `development` environment.
4.  **Promotion to Non-Production and Production**: To promote changes to the next environment, you will create a pull request from the `development` branch to the `non-production` branch, and then from `non-production` to `main`. The same review and approval process is followed at each stage.
