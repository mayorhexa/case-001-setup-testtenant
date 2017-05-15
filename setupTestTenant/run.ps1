# If hosted in Azure Web Jobs modules are auto loaded
if ($PSScriptRoot){ 
    Import-Module ".\modules\azuread\2.0.0.109\azuread.psd1"
    Import-Module ".\modules\hexa-functions.psm1"
}

Get-Hexa $req $res $PSScriptRoot

$account = Connect-AzureAD -Credential $global:credentials -ErrorAction:Stop

$usersCreated = 0
foreach ($user in $global:request.users) {
    $name = $user.Replace("@",".")
    $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $PasswordProfile.Password = "Password123456!"
    $upn = $name + "@" + $global:o365Tenant + ".onmicrosoft.com"

    $aduser = Get-AzureADUser $upn
    if ($aduser -eq $null){
        New-AzureADUser -DisplayName "User $name" -PasswordProfile $PasswordProfile -UserPrincipalName $upn -AccountEnabled $true -MailNickName $name 
        $usersCreated += 1
    }
}


Set-Hexa $usersCreated
