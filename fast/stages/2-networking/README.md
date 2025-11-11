# Networking Stage Configuration

This stage deploys the core networking infrastructure for your Google Cloud Foundation.

## Connecting to Azure

The configuration for the HA VPN connection to Azure requires you to provide the public IP addresses of the Azure VPN gateway instances. These values are passed to Terraform as variables.

To provide these values, you must create a `*.auto.tfvars` file in this directory (e.g., `credentials.auto.tfvars`) and define the following variables:

```tf
azure_peer_ip_0 = "x.x.x.x"  // Replace with the first Azure VPN gateway IP
azure_peer_ip_1 = "y.y.y.y"  // Replace with the second Azure VPN gateway IP
```

**IMPORTANT:** Do not commit this file to your Git repository. It should be created and managed locally or injected into your CI/CD pipeline at runtime.
