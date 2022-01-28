$roles = Get-AzRoleDefinition -Custom
$i = 1
foreach ($role in $roles)
{
    Write-Host $i"." $role.Name
    $i = $i + 1
}
$roleNum = Read-Host -Prompt "Select your custom role"
$selectedRole = Get-AzRoleDefinition -Id $roles[$roleNum - 1].Id
Write-Host Role $selectedRole.Name has write access to the following APIs:
$i = 1
foreach ($scope in $selectedRole.AssignableScopes)
{
    Write-Host $i"." $scope
    $i = $i + 1
}
$indexOfAPIs = $selectedRole.AssignableScopes[0].IndexOf("/apis/")
$apimResourceId = $selectedRole.AssignableScopes[0].Substring(0, $indexOfAPIs)
$apimInstance = Get-AzApiManagement -ResourceId $apimResourceId
Write-Host 1. Add an API to this role
Write-Host 2. Remove an API from this role
$action = Read-Host -Prompt "What would you like to do?"
if ($action -eq 1)
{
    # Select APIs to add
    $apimContext = New-AzApiManagementContext -ResourceGroupName $apimInstance.ResourceGroupName -ServiceName $apimInstance.Name
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
    # Update role definition
    foreach ($selectedAPI in $selectedAPIs)
    {
        $selectedRole.AssignableScopes.Add($selectedAPI.Id)
    }
    $updatedRole = Set-AzRoleDefinition -Role $selectedRole
    Write-Host "Sleeping for 30 seconds to ensure role is updated..."
    Start-Sleep -Seconds 30
    # Create new role assignments
    $roleAssignments = Get-AzRoleAssignment -RoleDefinitionId $updatedRole.Id
    $assignedObjects = foreach ($roleAssignment in $roleAssignments)
    {
        $roleAssignment.ObjectId
    }
    $uniqueAssignedObjects = $assignedObjects | sort-object | Get-Unique –AsString
    foreach ($selectedAPI in $selectedAPIs)
    {
        foreach ($objectId in $uniqueAssignedObjects)
        {
            New-AzRoleAssignment -ObjectId $objectId -RoleDefinitionId $updatedRole.Id -Scope $selectedAPI.Id
        }
    }
    Write-Host "Sleeping for 30 seconds to ensure role assignments are updated..."
    Start-Sleep -Seconds 30
}
if ($action -eq 2)
{
    # Select APIs to remove
    $i = 1
    foreach ($scope in $selectedRole.AssignableScopes)
    {
        Write-Host $i"." $scope
        $i = $i + 1
    }
    $apiNums = Read-Host -Prompt "Select your API(s) [use a comma-separated list no spaces]"
    $selectedAPINums = $apiNums -split ","
    $selectedAPIs = foreach ($selectedAPINum in $selectedAPINums)
    {
        $selectedRole.AssignableScopes[$selectedAPINum - 1]
    }
    $assignableScopes = foreach ($scope in $selectedRole.AssignableScopes)
    {
        $found = "false"
        foreach ($selectedAPI in $selectedAPIs)
        {
            if ($scope -eq $selectedAPI)
            {
                $found = "true"
            }
        }
        if ($found -eq "false")
        {
            $scope
        }
    }
    # Update assignable scopes
    $selectedRole.AssignableScopes.Clear()
    foreach ($assignableScope in $assignableScopes)
    {
        $selectedRole.AssignableScopes.Add($assignableScope)
    }
    # Remove role assignments
    $roleAssignments = Get-AzRoleAssignment -RoleDefinitionId $selectedRole.Id
    foreach ($roleAssignment in $roleAssignments)
    {
        foreach ($selectedAPI in $selectedAPIs)
        {
            if ($roleAssignment.Scope -eq $selectedAPI)
            {
                Remove-AzRoleAssignment -ObjectId $roleAssignment.ObjectId -RoleDefinitionId $selectedRole.Id -Scope $roleAssignment.Scope
            }
        }
    }
    Write-Host "Sleeping for 30 seconds to ensure role assignments are updated..."
    Start-Sleep -Seconds 30
    # Update role definition
    Set-AzRoleDefinition -Role $selectedRole
    Write-Host "Sleeping for 30 seconds to ensure role is updated..."
    Start-Sleep -Seconds 30
}
 