
# If hosted in Azure Web Jobs modules are auto loaded
if ($PSScriptRoot){ 
    Import-Module ".\modules\azuread\2.0.0.109\azuread.psd1"
    Import-Module ".\modules\hexa-functions.psm1"
}

Enter-Hexa $req $res $PSScriptRoot

$account = Connect-AzureAD -Credential $global:credentials -ErrorAction:Stop

$usersCreated = 0
foreach ($email in $global:request.users) {
    $name = $email.Replace("@",".")
    
    $upn = $name + "@" + $global:o365Tenant + ".onmicrosoft.com"
    $admupn = "admin-" + $name + "@" + $global:o365Tenant + ".onmicrosoft.com"

    $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $PasswordProfile.Password = "Password123456!"
    $user = $null
    $user = Get-AzureADUser -ObjectId $upn -ErrorAction:SilentlyContinue
    if ($user -eq $null){
        New-AzureADUser -DisplayName "$email ($($global:o365Tenant))" `
                        -PasswordProfile $PasswordProfile `
                        -UserPrincipalName $upn `
                        -AccountEnabled $true `
                        -MailNickName $name `
                        -UsageLocation "DK"
        $usersCreated += 1
    }
    Set-AzureADUser -ObjectId $upn -UsageLocation "DK"      
    
    # Create the objects we'll need to add and remove licenses
    $license = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
    $licenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses

    # Find the SkuID of the license we want to add - in this exmample we'll use the O365_BUSINESS_PREMIUM license
    $license.SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value "ENTERPRISEPACK" -EQ).SkuID

    # Set the OFFice license as the license we want to add in the $licenses object
    $licenses.AddLicenses = $license

    # Call the Set-AzureADUserLicense cmdlet to set the license.
    Set-AzureADUserLicense -ObjectId $upn -AssignedLicenses $licenses


## KOMPLEKS PASSWORD

    $admuser = $null
    $admuser = Get-AzureADUser -ObjectId $admupn  -ErrorAction:SilentlyContinue
    if ($admuser -eq $null){
        New-AzureADUser -DisplayName ("$name ADMIN ($($global:o365Tenant))").ToUpper() `
                        -PasswordProfile $PasswordProfile `
                        -UserPrincipalName $admupn `
                        -AccountEnabled $true `
                        -MailNickName "adm-$name" 
        $usersCreated += 1
    }
}


Exit-Hexa "Created $usersCreated users"
