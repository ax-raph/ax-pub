<#
.SYNOPSIS
  Create an AD service account and/or grant domain-wide read ACLs for Axonius.

.DESCRIPTION
  -Use -CreateSA to create or update the service account.
  -Use -AddACL to grant GenericRead on the domain root (inherited).
  You can use both in the same run.

.PARAMETER CreateSA
  Create or update the service account.

.PARAMETER AddACL
  Grant GenericRead on the domain root to the specified account.

.PARAMETER SamAccountName
  The sAMAccountName for the service account (e.g., axonius-svc).

.PARAMETER UPNSuffix
  UPN suffix/domain (e.g., contoso.local). Defaults to the forest root if omitted.

.PARAMETER PasswordPlain
  Plaintext password for the account (alternative to -Password).

.PARAMETER Password
  SecureString password for the account (alternative to -PasswordPlain).

.PARAMETER TargetOU
  DistinguishedName of the OU/Container to create the account in.
  Defaults to CN=Users,<domain DN> if omitted.

.EXAMPLE
  # Create service account only
  .\create_svc_account.ps1 `
    -CreateSA `
    -SamAccountName axonius-svc `
    -UPNSuffix contoso.local `
    -PasswordPlain 'Str0ngP@ss!' `
    -TargetOU 'OU=Service Accounts,DC=contoso,DC=local'

.EXAMPLE
  # Grant ACL only (GenericRead on domain)
  .\create_svc_account.ps1 `
    -AddACL `
    -SamAccountName axonius-svc

.EXAMPLE
  # Create service account AND grant ACL in one run (what most users want)
  .\create_svc_account.ps1 `
    -CreateSA -AddACL `
    -SamAccountName axonius-svc `
    -UPNSuffix contoso.local `
    -PasswordPlain 'Str0ngP@ss!' `
    -TargetOU 'OU=Service Accounts,DC=contoso,DC=local'

.NOTES
  Run from a domain-joined machine with sufficient rights (Domain Admin or delegated).
  If you plan to fetch permissions via WinRM, add the account to the local
  "Remote Management Users" group on endpoints using GPO.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [switch]$CreateSA,
  [switch]$AddACL,
  [string]$SamAccountName,
  [string]$UPNSuffix,
  [string]$PasswordPlain,
  [SecureString]$Password,
  [string]$TargetOU
)

function Show-Usage {
  Write-Host "Usage examples:"
  Write-Host "  .\create_svc_account.ps1 -CreateSA -SamAccountName axonius-svc -UPNSuffix contoso.local -PasswordPlain 'Str0ngP@ss!' -TargetOU 'OU=Service Accounts,DC=contoso,DC=local'"
  Write-Host "  .\create_svc_account.ps1 -AddACL -SamAccountName axonius-svc"
  Write-Host "  .\create_svc_account.ps1 -CreateSA -AddACL -SamAccountName axonius-svc -UPNSuffix contoso.local -PasswordPlain 'Str0ngP@ss!' -TargetOU 'OU=Service Accounts,DC=contoso,DC=local'"
}

# Require at least one action
if (-not $CreateSA -and -not $AddACL) {
  Write-Error "You must specify at least one option: -CreateSA and/or -AddACL."
  Show-Usage
  exit 1
}

# Load AD module
try {
  if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    throw "The 'ActiveDirectory' module is not installed. Install RSAT: Active Directory tools or run on a Domain Controller."
  }
  Import-Module ActiveDirectory -ErrorAction Stop
} catch {
  Write-Error $_.Exception.Message
  exit 1
}

# Domain context
try {
  $domain = Get-ADDomain -ErrorAction Stop
  $DomainDN = $domain.DistinguishedName
  $DefaultUpnSuffix = ($domain.Forest).RootDomain
} catch {
  Write-Error "Unable to read domain context. $_"
  exit 1
}

# Defaults
if ([string]::IsNullOrWhiteSpace($TargetOU)) {
  $TargetOU = "CN=Users,$DomainDN"
}

# Convert password if provided in plain text
if (-not $Password -and $PasswordPlain) {
  try {
    $Password = ConvertTo-SecureString -String $PasswordPlain -AsPlainText -Force
  } catch {
    Write-Error "Failed to convert plaintext password to SecureString. $_"
    exit 1
  }
}

function Ensure-Params-ForCreate {
  if ([string]::IsNullOrWhiteSpace($SamAccountName)) {
    throw "Missing -SamAccountName for -CreateSA."
  }
  if (-not $Password) {
    throw "Missing -Password or -PasswordPlain for -CreateSA."
  }
  if ([string]::IsNullOrWhiteSpace($UPNSuffix)) {
    $script:UPNSuffix = $DefaultUpnSuffix
  }
}

function Create-ServiceAccount {
  param(
    [string]$Sam,
    [SecureString]$SecPw,
    [string]$UpnSuffix,
    [string]$OuDn
  )
  $created = $false
  $userDn  = $null
  try {
    $existing = Get-ADUser -Filter "sAMAccountName -eq '$Sam'" -ErrorAction SilentlyContinue
    if ($existing) {
      Write-Host "Service account '$Sam' already exists. Updating properties..."
      Set-ADUser -Identity $existing -UserPrincipalName "$Sam@$UpnSuffix" -Enabled $true -ErrorAction Stop
      Set-ADUser -Identity $existing -PasswordNeverExpires $true -ErrorAction Stop
      Set-ADAccountPassword -Identity $existing -NewPassword $SecPw -Reset -ErrorAction Stop
      $userDn = $existing.DistinguishedName
    } else {
      Write-Host "Creating service account '$Sam' in '$OuDn'..."
      New-ADUser -Name $Sam `
                 -SamAccountName $Sam `
                 -UserPrincipalName "$Sam@$UpnSuffix" `
                 -Path $OuDn `
                 -Enabled $true `
                 -ChangePasswordAtLogon $false `
                 -PasswordNeverExpires $true `
                 -AccountPassword $SecPw `
                 -ErrorAction Stop
      $created = $true
      $userDn = (Get-ADUser -Filter "sAMAccountName -eq '$Sam'" -ErrorAction Stop).DistinguishedName
    }

    # Add to Account Operators
    $acctOps = Get-ADGroup -Identity "Account Operators" -ErrorAction Stop
    Add-ADGroupMember -Identity $acctOps -Members $Sam -ErrorAction SilentlyContinue

    return Get-ADUser -Identity $Sam -Properties * -ErrorAction Stop
  } catch {
    Write-Error "Failed while creating/updating user '$Sam'. $_"
    if ($created -and $userDn) {
      Write-Host "Rolling back: removing newly created user '$Sam'."
      try { Remove-ADUser -Identity $userDn -Confirm:$false -ErrorAction Stop } catch { Write-Host "Rollback failed: $_" }
    }
    throw
  }
}

function Grant-DomainGenericRead {
  param([string]$Sam)

  $user = Get-ADUser -Identity $Sam -ErrorAction Stop

  # Build ACE: GenericRead on domain root, inherited
  try {
    $nt = New-Object System.Security.Principal.NTAccount($user.SID.Translate([System.Security.Principal.NTAccount]).Value)
  } catch {
    $nt = New-Object System.Security.Principal.NTAccount("$($domain.NetBIOSName)\$Sam")
  }

  $adRights = [System.DirectoryServices.ActiveDirectoryRights]::GenericRead
  $type     = [System.Security.AccessControl.AccessControlType]::Allow
  $inherit  = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::All
  $rule     = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($nt, $adRights, $type, $inherit)

  $path = "AD:$DomainDN"
  $acl  = Get-Acl -Path $path
  $acl.AddAccessRule($rule) | Out-Null
  Set-Acl -Path $path -AclObject $acl -ErrorAction Stop

  Write-Host "Granted GenericRead to '$Sam' on $DomainDN (inherited)."
}

# Run actions
try {
  if ($CreateSA) {
    Ensure-Params-ForCreate
    $user = Create-ServiceAccount -Sam $SamAccountName -SecPw $Password -UpnSuffix $UPNSuffix -OuDn $TargetOU
    Write-Host "Service account ready: $($user.SamAccountName) / $($user.UserPrincipalName)"
    Write-Host "Added to 'Account Operators'."
  }

  if ($AddACL) {
    if ([string]::IsNullOrWhiteSpace($SamAccountName)) {
      throw "Missing -SamAccountName for -AddACL."
    }
    Grant-DomainGenericRead -Sam $SamAccountName
  }

  # Summary
  if ($SamAccountName) {
    $u = Get-ADUser -Identity $SamAccountName -Properties UserPrincipalName,PasswordNeverExpires,Enabled -ErrorAction SilentlyContinue
    if ($u) {
      Write-Host ("Summary:")
      Write-Host ("  sAMAccountName : {0}" -f $u.SamAccountName)
      Write-Host ("  UPN            : {0}" -f $u.UserPrincipalName)
      Write-Host ("  Enabled        : {0}" -f $u.Enabled)
      Write-Host ("  PwdNeverExp    : {0}" -f $u.PasswordNeverExpires)
    }
  }
} catch {
  Write-Error $_.Exception.Message
  exit 1
}
