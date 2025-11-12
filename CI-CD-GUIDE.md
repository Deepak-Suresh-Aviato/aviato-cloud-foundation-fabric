# CI/CD Guide for a GitOps-Driven FAST Architecture

This document outlines the CI/CD strategy for managing your Google Cloud Foundation using a best-practice, two-trigger GitOps workflow. This model uses separate pipelines for planning (`terraform plan`) and applying (`terraform apply`), triggered by different Git events to ensure a safe and reviewable deployment process.

## CI/CD Architecture: Plan on PR, Apply on Merge

This repository uses a distributed, two-trigger architecture where each FAST stage (`0-org-setup`, `1-vpcsc`, etc.) has two corresponding Cloud Build pipelines:

1.  **Plan Pipeline (`cloudbuild-plan.yaml`):**
    *   **Trigger:** Runs when a **Pull Request** is opened or updated.
    *   **Action:** Executes `terraform plan` to generate a plan file.
    *   **Output:** Saves the plan file as an artifact in a central Google Cloud Storage (GCS) bucket and posts a status check (Success/Failure) back to the GitHub PR.

2.  **Apply Pipeline (`cloudbuild-apply.yaml`):**
    *   **Trigger:** Runs when a commit is **pushed to a main branch** (i.e., when a PR is merged).
    *   **Action:** Downloads the plan artifact from the GCS bucket.
    *   **Output:** Executes `terraform apply` using the approved plan file.

This workflow ensures that the exact plan reviewed in the Pull Request is the one that gets applied, with the PR approval and merge serving as the explicit sign-off for deployment.

## Initial Setup: Create the Plan Artifact Bucket

Before you can use this CI/CD system, you must create a Google Cloud Storage bucket to store the Terraform plan artifacts.

1.  **Choose a globally unique name** for your bucket (e.g., `avlab-gcp-tf-plans`).
2.  **Create the bucket** in the Google Cloud Console or using the `gcloud` CLI:
    ```sh
    gcloud storage buckets create gs://your-unique-bucket-name --project=your-iac-0-project-id
    ```
3.  **Enable Object Versioning** on the bucket. This is a critical safety measure to prevent plans from being overwritten and to keep a history.
    ```sh
    gcloud storage buckets update gs://your-unique-bucket-name --versioning
    ```

## Cloud Build Trigger Configuration

You will need to create **two triggers for each FAST stage and for each environment**. For a `development` environment, you would have:

*   `plan-dev-0-org-setup` and `apply-dev-0-org-setup`
*   `plan-dev-0-secrets` and `apply-dev-0-secrets`
*   ...and so on for all five stages.

---

### **Trigger 1: The "Plan" Trigger**

*   **Name:** A descriptive name (e.g., `plan-dev-0-org-setup`).
*   **Event:** "Pull request".
*   **Source:**
    *   **Repository:** Your `aviato-cloud-foundation-fabric` repository.
    *   **Base branch:** The branch the PR is targeting (e.g., `^development$`).
    *   **Comment control:** (Optional but recommended) "Required for new contributors only".
*   **Configuration:**
    *   **Type:** "Cloud Build configuration file (yaml or json)".
    *   **Location:** The path to the stage-specific `cloudbuild-plan.yaml` file (e.g., `fast/stages/0-org-setup/cloudbuild-plan.yaml`).
*   **Substitution variables:**
    *   `_TF_VARS_FILE`: `gcp-development.tfvars`
    *   `_PLAN_BUCKET`: The name of the GCS bucket you created (e.g., `avlab-gcp-tf-plans`).
    *   `_BRANCH_NAME`: `${_BASE_BRANCH}` (This is a built-in variable from the trigger).

---

### **Trigger 2: The "Apply" Trigger**

*   **Name:** A descriptive name (e.g., `apply-dev-0-org-setup`).
*   **Event:** "Push to a branch".
*   **Source:**
    *   **Repository:** Your `aviato-cloud-foundation-fabric` repository.
    *   **Branch:** The name of the environment-specific branch (e.g., `^development$`).
    *   **Included files filter (IMPORTANT):** To prevent all "apply" pipelines from running on every merge, add a path filter.
        *   Example for `apply-dev-0-org-setup`: `fast/stages/0-org-setup/**`
*   **Configuration:**
    *   **Type:** "Cloud Build configuration file (yaml or json)".
    *   **Location:** The path to the stage-specific `cloudbuild-apply.yaml` file (e.g., `fast/stages/0-org-setup/cloudbuild-apply.yaml`).
*   **Substitution variables:**
    *   `_PLAN_BUCKET`: The name of the GCS bucket you created (e.g., `avlab-gcp-tf-plans`).
    *   `_BRANCH_NAME`: `${_BRANCH_NAME}` (This is a built-in variable from the trigger).

---

## Initial Bootstrap Sequence

Due to dependencies, you must perform a one-time manual deployment of the stages in the correct order. For the very first deployment, you will need to trigger the **"apply" pipeline** for each stage manually from the Google Cloud Console, targeting your `development` branch.

**Correct Bootstrap Order:**
1.  `apply-dev-0-org-setup`
2.  `apply-dev-0-secrets`
3.  `apply-dev-1-vpcsc`
4.  `apply-dev-2-networking`
5.  `apply-dev-2-security`

---

## Managing Inter-Stage Dependencies

**IMPORTANT:** The FAST stages are not independent. Later stages depend on the outputs of earlier stages (e.g., the networking stage needs to know the folder IDs created by the org setup stage).

If you make a change to an upstream stage (like `0-org-setup`), you **must** re-run the pipelines for all downstream stages that depend on it to keep your infrastructure in sync.

### Recommended Workflow: The "Trivial Change" PR

The safest way to manage these cascading changes is to make them all visible in a single Pull Request.

**Scenario:** You need to change the name of a folder in `0-org-setup`. You know this will affect `2-networking` and `2-security`.

1.  **Create your branch** as usual.
2.  **Make your intended change** in the `fast/stages/0-org-setup/` directory.
3.  **Make a trivial change** in the downstream directories. For example, add a comment to `fast/stages/2-networking/main.tf`:
    ```tf
    # Re-running to pick up changes from 0-org-setup
    ```
4.  **Commit and create the Pull Request.**

**Result:**
Because you have changed files in all three stage directories, the "plan" triggers for `0-org-setup`, `2-networking`, and `2-security` will all run on your PR. This allows you to see the full, cascading impact of your change in one place before you approve it. When you merge the PR, the corresponding "apply" pipelines will run, bringing everything into sync.
