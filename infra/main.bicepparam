// Parameters for Azure OIDC Sample deployment
using 'main.bicep'

// Application configuration
param appName = 'azure-oidc-sample'
param location = 'East US'
param skuName = 'F1'  // Free tier for testing
param nodeVersion = '20'
