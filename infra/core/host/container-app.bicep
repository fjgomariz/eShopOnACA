param name string
param location string = resourceGroup().location
param tags object = {}

// Reference Properties
param containerAppsEnvironmentName string
param containerRegistryName string
param keyVaultName string = ''
param managedIdentity bool = !empty(keyVaultName)

// Container Properties
param containerCpuCoreCount string = '0.5'
param containerMemory string = '1.0Gi'
param containerMinReplicas int = 1
param containerMaxReplicas int = 10
param imageName string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
param targetPort int = 8080

// App settings
param env array = []

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: name
  location: location
  tags: tags
  identity: { type: managedIdentity ? 'SystemAssigned' : 'None' }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: targetPort
        transport: 'auto'
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: 'system'
        }
      ]
    }
    template: {
      containers: [
        {
          image: imageName
          name: 'main'
          env: env
          resources: {
            cpu: json(containerCpuCoreCount)
            memory: containerMemory
          }
        }
      ]
      scale: {
        minReplicas: containerMinReplicas
        maxReplicas: containerMaxReplicas
      }
    }
  }
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: containerAppsEnvironmentName
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = if (!empty(keyVaultName)) {
  name: keyVaultName
}

output identityPrincipalId string = managedIdentity ? containerApp.identity.principalId : ''
output imageName string = imageName
output name string = containerApp.name
output uri string = 'https://${containerApp.properties.configuration.ingress.fqdn}'

