# The script removes users from a sites specified User Settings Template if they haven't connected in more than 150 days and their account is older than 90 days 
# It also logs the removed user's details for record-keeping
# Recommended to do a export/report of your current accounts on EFT before running this cleanup script

# Load SFTP COM object
$SFTPServer = New-Object -COM "SFTPCOMInterface.CIServer"

# Auth Parameters
$ComputerName = "NLAGSFMVA01"
$ServicePort = 1100
$Username = "username"	# Define your username here
$Password = "password"  # Define your password here

# Date
$Today = Get-Date

# Connection String
$SFTPServer.Connect($ComputerName, $ServicePort, $Username, $Password)

# Get List of Sites
$SFTPSites = $SFTPServer.Sites()

# Initialize Users Array and CSV content
$UserList = @()
$RemovedAccounts = @()

# Select the first site and Get Users
$site = $SFTPSites.Item(0)
$users = $site.GetSettingsLevelUsers('External Warm-Body Account') # specify your User Settings Template here

# For each user, compare the dates and delete if they have not connected in the past 150 days and have not been created in the past 90 days
Write-Host "Removing Users That Have Not Connected in the past 150 days):`n`n"
Write-Host "UserName -- Last Connection Time"
foreach ($user in $users) {
    $UserSettings = $site.GetUserSettings($user)
    
    if ($UserSettings.LastConnectionTime -lt $Today.AddDays(-150)) {
        if ($UserSettings.AccountCreationTime -lt $Today.AddDays(-90)) {
            Write-Host $user " -- " $UserSettings.LastConnectionTime
            $site.RemoveUser($user)
            $RemovedAccounts += [PSCustomObject]@{
                UserName           = $user
                LastConnectionTime = $UserSettings.LastConnectionTime
                AccountCreationTime = $UserSettings.AccountCreationTime
            }
        }
    }
}

# Save removed accounts to CSV
$RemovedAccounts | Export-Csv -Path "RemovedAccounts_User_Settings_Template.csv" -NoTypeInformation # Adjust your export file name here to align with your targeted User Settings Template

$SFTPServer.Close()
Read-Host -Prompt "Press Enter to exit"