# Azure OIDC Sample Project

A minimal Azure OIDC (OpenID Connect) workflow project to test `az login` authentication using GitHub Actions and Azure Workload Identity Federation.

## Overview

This project demonstrates how to:
- Set up Azure Workload Identity Federation (OIDC) for secure authentication
- Use GitHub Actions to authenticate with Azure without storing credentials
- Deploy a simple Node.js application to Azure
- Test Azure CLI authentication in CI/CD pipelines

## Prerequisites

1. Azure subscription
2. GitHub repository
3. Azure CLI installed locally (for setup)

## Setup Instructions

### 1. Create Azure Resources

First, create the necessary Azure resources using Bicep:

```bash
# Login to Azure
az login

# Create a resource group
az group create --name rg-oidc-sample --location "East US"

# Deploy the infrastructure
az deployment group create \
  --resource-group rg-oidc-sample \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

### 2. Configure Azure Workload Identity Federation

Create an Azure AD application and configure OIDC:

```bash
# Create Azure AD application
az ad app create \
  --display-name "GitHub OIDC Sample" \
  --sign-in-audience AzureADMyOrg

# Get the application ID (client ID)
APP_ID=$(az ad app list --display-name "GitHub OIDC Sample" --query "[0].appId" -o tsv)
echo "Application ID: $APP_ID"

# Create service principal
az ad sp create --id $APP_ID

# Get service principal object ID
SP_OBJECT_ID=$(az ad sp show --id $APP_ID --query "id" -o tsv)

# Assign Contributor role to the service principal
az role assignment create \
  --assignee-object-id $SP_OBJECT_ID \
  --role Contributor \
  --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/rg-oidc-sample

# Configure federated credentials for GitHub Actions
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "GitHubOIDC",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### 2. Configure Azure Managed Identity Workload Identity Federation

Create an Azure AD application and configure OIDC:

```bash

# Create idenity will give a clientID
az identity create --name MyIdentity --resource-group rg-oidc-sample

# Get the application ID (client ID)
MI_OBJECT_ID=$(az identity show --id id-from-above --query "id" -o tsv)

az role assignment create \
  --assignee-object-id $MI_OBJECT_ID \
  --role Contributor \
  --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/rg-oidc-sample

# list and take "id" of managedIdentiy created
 az ad sp list --all --filter "servicePrincipalType eq 'ManagedIdentity'"

# Assign Contributor role to the service principal
 az role assignment create \
  --assignee-object-id id-from-previous-line \
  --role Contributor \
  --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/rg-oidc-sample

# Configure federated credentials for GitHub Actions

az identity federated-credential create --name "GitHubOIDC1" --identity-name MyIdentity --resource-group rg-oidc-sample --issuer "https://token.actions.githubusercontent.com" --subject "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:ref:refs/heads/main"


```


### 3. Configure GitHub Secrets

Add the following secrets to your GitHub repository:

- `AZURE_CLIENT_ID`: Application (client) ID from step 2
- `AZURE_TENANT_ID`: Your Azure tenant ID
- `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID

```bash
# Get tenant ID
az account show --query tenantId -o tsv

# Get subscription ID
az account show --query id -o tsv
```

### 4. Update GitHub Workflow

Replace `YOUR_GITHUB_USERNAME/YOUR_REPO_NAME` in the federated credential subject with your actual GitHub username and repository name.

## Local Development

1. Install dependencies:
   ```bash
   npm install
   ```

2. Run in development mode:
   ```bash
   npm run dev
   ```

3. Build for production:
   ```bash
   npm run build
   npm start
   ```

## API Endpoints

- `GET /` - Application info
- `GET /health` - Health check endpoint
- `GET /info` - Environment information

## Docker

Build and run the Docker container:

```bash
# Build the image
docker build -t azure-oidc-sample .

# Run the container
docker run -p 3000:3000 azure-oidc-sample
```

## GitHub Actions Workflow

The workflow in `.github/workflows/deploy.yml`:

1. **Build Job**: Builds the Node.js application
2. **Authentication Test**: Demonstrates OIDC authentication with Azure
3. **Azure CLI Test**: Verifies Azure CLI access after authentication

## Key Features

- **No stored credentials**: Uses Azure Workload Identity Federation
- **Secure authentication**: OIDC tokens are short-lived and automatically managed
- **Multi-environment support**: Easy to configure for different environments
- **Health monitoring**: Built-in health check endpoints
- **Infrastructure as Code**: Bicep templates for Azure resources

## Troubleshooting

### Common Issues

1. **Authentication fails**: Verify GitHub secrets and federated credential configuration
2. **Wrong subject in federated credential**: Ensure the subject matches your repository and branch
3. **Permission denied**: Check role assignments for the service principal

### Debugging

Enable debug mode in GitHub Actions by setting the `ACTIONS_STEP_DEBUG` secret to `true`.

## Security Notes

- Never commit Azure credentials to your repository
- Use least privilege principle for role assignments
- Regularly rotate service principal credentials
- Monitor authentication logs in Azure AD

## Next Steps

- Deploy to Azure Container Apps or AKS
- Add automated testing and security scanning
- Implement monitoring and alerting
- Set up multiple environments (dev, staging, prod)