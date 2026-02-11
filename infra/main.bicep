// Azure OIDC Sample Infrastructure
// This Bicep template creates the necessary Azure resources for OIDC authentication

targetScope = 'resourceGroup'

@description('The name of the web application')
param appName string = 'oidc-sample-${uniqueString(resourceGroup().id)}'

@description('The location for all resources')
param location string = resourceGroup().location

@description('The pricing tier for the App Service plan')
@allowed([
  'F1'
  'B1'
  'S1'
  'P1v3'
])
param skuName string = 'F1'

@description('Node.js version')
param nodeVersion string = '20'

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${appName}-asp'
  location: location
  sku: {
    name: skuName
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
  tags: {
    Environment: 'Development'
    Project: 'Azure OIDC Sample'
  }
}

// Web App
resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: appName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'NODE|${nodeVersion}-lts'
      appSettings: [
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~${nodeVersion}'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'NODE_ENV'
          value: 'production'
        }
      ]
      alwaysOn: skuName != 'F1' // F1 tier doesn't support Always On
      ftpsState: 'Disabled'
      httpLoggingEnabled: true
      requestTracingEnabled: true
      detailedErrorLoggingEnabled: true
    }
    httpsOnly: true
  }
  tags: {
    Environment: 'Development'
    Project: 'Azure OIDC Sample'
  }
}

// Output the app URL and important information
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppName string = webApp.name
output resourceGroupName string = resourceGroup().name
output appServicePlanName string = appServicePlan.name
