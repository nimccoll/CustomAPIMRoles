$roles = Get-AzRoleDefinition -Custom
$i = 1
foreach ($role in $roles)
{
    Write-Host $i"." $role.Name
    $i = $i + 1
}
$roleNum = Read-Host -Prompt "Select your custom role"
$selectedRole = $roles[$roleNum - 1]
Write-Host Role $selectedRole.Name has write access to the following APIs:
$i = 1
foreach ($scope in $selectedRole.AssignableScopes)
{
    Write-Host $i"." $scope
    $i = $i + 1
}
$action = Read-Host -Prompt "Do you wish to delete this role and all of its associated role assignments [Y/N]?"
if ($action -eq "Y")
{
    # Remove role assignments
    $roleAssignments = Get-AzRoleAssignment -RoleDefinitionId $selectedRole.Id
    foreach ($roleAssignment in $roleAssignments)
    {
        Remove-AzRoleAssignment -ObjectId $roleAssignment.ObjectId -Scope $roleAssignment.Scope -RoleDefinitionId $selectedRole.Id
    }
    Write-Host "Sleeping for 30 seconds to ensure role assignments are deleted..."
    Start-Sleep -Seconds 30
    # Remove role
    Remove-AzRoleDefinition -Id $selectedRole.Id
    Write-Host "Sleeping for 30 seconds to ensure role is deleted..."
    Start-Sleep -Seconds 30        
}