# Select APIM instance
$apimInstances = Get-AzApiManagement
$i = 1
foreach ($apimInstance in $apimInstances)
{
    Write-Host $i"." $apimInstance.Name
    $i = $i + 1
}
$apimInstanceNum = Read-Host -Prompt "Select your APIM instance"
$selectedAPIMInstance = $apimInstances[$apimInstanceNum - 1]
# Select APIs
$apimContext = New-AzApiManagementContext -ResourceGroupName $selectedAPIMInstance.ResourceGroupName -ServiceName $selectedAPIMInstance.Name
Get-AzApiManagementApi -Context $apimContext
$apis = Get-AzApiManagementApi -Context $apimContext
$i = 1
foreach ($api in $apis)
{
    Write-Host $i"." $api.Name
    $i = $i + 1
}
$apiNums = Read-Host -Prompt "Select your API(s) [use a comma-separated list no spaces]"
$selectedAPINums = $apiNums -split ","
$selectedAPIs = foreach ($selectedAPINum in $selectedAPINums)
{
    $apis[$selectedAPINum - 1]
}
# Create custom APIM role
$roleName = Read-Host -Prompt "Enter a name for your custom RBAC role"
$roleDescription = Read-Host Prompt "Enter a description for your custom RBAC role"
$role = Get-AzRoleDefinition "API Management Service Reader Role"
$role.Id = $null
$role.Name = $roleName
$role.Description = $roleDescription
$role.Actions.Add('Microsoft.ApiManagement/service/apis/write')
$role.Actions.Add('Microsoft.ApiManagement/service/apis/*/write')
$role.AssignableScopes.Clear()
foreach ($selectedAPI in $selectedAPIs)
{
    $role.AssignableScopes.Add($selectedAPI.Id)
}
$newRole = New-AzRoleDefinition -Role $role
Write-Host "Sleeping for 30 seconds to ensure role is created..."
Start-Sleep -Seconds 30
$objectId = Read-Host "Enter the Object ID of the user or group to assign this role to"
foreach ($selectedAPI in $selectedAPIs)
{
    New-AzRoleAssignment -ObjectId $objectId -RoleDefinitionId $newRole.Id -Scope $selectedAPI.Id
}
Write-Host "Sleeping for 30 seconds to ensure role assignments are created..."
Start-Sleep -Seconds 30