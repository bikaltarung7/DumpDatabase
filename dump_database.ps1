[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null 

$server = Read-Host 'Server'
$database = Read-Host 'Database'
$path = Read-Host 'Path';

$SMOserver = New-Object ('Microsoft.SqlServer.Management.Smo.Server') -argumentlist $server 
$SMOserver.ConnectionContext.LoginSecure = $False

$credential = Get-Credential;
$SMOserver.ConnectionContext.set_login($credential.UserName);
$SMOserver.ConnectionContext.set_SecurePassword($credential.Password);

$db = $SMOserver.databases["$database"]

$Objects = $db.Tables
$Objects += $db.Views
$Objects += $db.StoredProcedures
$Objects += $db.UserDefinedFunctions

new-item -type directory -name "$database"-path "$path" | Out-Null

$scripter = New-Object ("Microsoft.SqlServer.Management.Smo.Scripter") ($SMOserver)
 
# Set general options
$scripter.Options.AppendToFile = $True
$scripter.Options.AllowSystemObjects = $False
$scripter.Options.ClusteredIndexes = $True
$scripter.Options.DriAll = $True
$scripter.Options.ScriptDrops = $False
$scripter.Options.IncludeHeaders = $True
$scripter.Options.ToFileOnly = $True
$scripter.Options.Indexes = $True
$scripter.Options.Permissions = $True
$scripter.Options.WithDependencies = $False


foreach ($item in $Objects | where {!($_.IsSystemObject)}) 
{
    #get object type
    $dirType = $item.GetType().Name
  
    #check if folder exists
    if ((Test-Path -Path "$path\$database\$dirType") -eq "true") 
    {
        "Scripting Out $dirType $item"
    }
    else 
    {
        new-item -type directory -name "$dirType"-path "$path\$database"
    }

    $ScriptFile = $item -replace "\[|\]"

    $scripter.Options.FileName = "$path\$database\$dirType\$ScriptFile.SQL"
    
    $scripter.Script($item)
}

pause
