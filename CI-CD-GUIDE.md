# CI/CD Guide for a Distributed, Multi-Environment FAST Architecture

This document outlines the CI/CD strategy for managing your Google Cloud Foundation, which is composed of multiple FAST stages. This architecture uses a distributed pipeline model, where each FAST stage has its own independent CI/CD pipeline, enabling modular, parallel, and environment-aware deployments.

## CI/CD Architecture

Instead of a single, monolithic pipeline, this repository uses a distributed architecture where each FAST stage (`0-org-setup`, `1-vpcsc`, `2-networking`, `2-security`, etc.) contains its own `cloudbuild.yaml` file.

This approach has several advantages:
*   **Modularity**: Each stage can be deployed and managed independently.
*   **Parallelism**: Changes to different stages can be planned and reviewed in parallel.
*   **Scalability**: It's easy to add new FAST stages without modifying a central pipeline.
*   **Clarity**: The CI/CD logic for a stage is located within the stage's own directory.

## Initial Bootstrap Sequence (First-Time Deployment)

Due to dependencies between the stages, you must perform a one-time manual bootstrap to deploy the stages in the correct order for the first time.

**IMPORTANT**: The `0-org-setup` stage creates the `iac-0` project, which is where the Cloud Build service account will be granted permissions and where the `github-token` secret must be stored. You must run this stage first to enable the CI/CD automation for the other stages.

The correct bootstrap order is:
1.  **`0-org-setup`**: Deploys the core organization structure and the `iac-0` project.
2.  **`0-secrets`**: Creates the secrets in Secret Manager.
3.  **`1-vpcsc`**: Establishes the VPC Service Controls perimeter.
4.  **`2-networking`**: Deploys the core networking infrastructure.
5.  **`2-security`**: Deploys the centralized security services.

You will need to manually trigger the Cloud Build pipeline for each of these stages, in order, from the Google Cloud Console to provision your first environment.

## Environment and Branching Strategy

Each environment is tied to a specific Git branch:

*   **`development` branch**: Deploys to the `development` GCP environment.
*   **`non-production` branch**: Deploys to the `non-production` GCP environment.
*   **`main` branch**: Deploys to the `production` GCP environment.

## Cloud Build Trigger Configuration

You will need to create a separate Cloud Build trigger for each FAST stage and for each environment. For example, for the `development` environment, you will have five triggers:

*   `deploy-dev-0-org-setup`
*   `deploy-dev-0-secrets`
*   `deploy-dev-1-vpcsc`
*   `deploy-dev-2-networking`
*   `deploy-dev-2-security`

### Recommended Trigger Configuration

*   **Name**: A descriptive name (e.g., `deploy-dev-0-org-setup`).
*   **Event**: "Push to a branch".
*   **Source**:
    *   **Repository**: Your `aviato-cloud-foundation-fabric` repository.
    *   **Branch**: The name of the environment-specific branch (e.g., `^development$`).
*   **Configuration**:
    *   **Type**: "Cloud Build configuration file (yaml or json)".
    *   **Location**: The path to the stage-specific `cloudbuild.yaml` file (e.g., `fast/stages/0-org-setup/cloudbuild.yaml`).
*   **Substitution variables**:
    *   `_TF_VARS_FILE`: The environment-specific `.tfvars` file (e.g., `gcp-development.tfvars`).
    *   `_GITHUB_TOKEN_SECRET_VERSION`: The full version string for your GitHub token secret in Secret Manager (e.g., `projects/your-iac-0-project-id/secrets/github-token/versions/latest`).

## Pull Request and Deployment Workflow

1.  **Development**: Developers create feature branches off of the `development` branch. When they open a pull request against `development`, the appropriate stage-specific Cloud Build pipeline(s) will be triggered. The pipeline runs a `terraform plan` and posts the plan to the PR.
2.  **Approval**: After the PR is reviewed and the plan is approved, the code is merged into the `development` branch.
3.  **Deployment to Development**: The merge to the `development` branch triggers the corresponding "deploy-dev-*" Cloud Build trigger, which applies the Terraform configuration to the `development` environment.
4.  **Promotion to Non-Production and Production**: To promote changes to the next environment, you will create a pull request from the `development` branch to the `non-production` branch, and then from `non-production` to `main`. The same review and approval process is followed at each stage.
