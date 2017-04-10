<##############################################################################
Ashley McGlone
Microsoft Premier Field Engineer
April 2017
http://aka.ms/GoateePFE

This script is part of a demo of Kerberos Double Hop mitigations in
PowerShell. Presented at the PowerShell and DevOps Global Summit 2017.
http://aka.ms/pskdh

LEGAL DISCLAIMER
This Sample Code is provided for the purpose of illustration only and is not
intended to be used in a production environment.  THIS SAMPLE CODE AND ANY
RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a
nonexclusive, royalty-free right to use and modify the Sample Code and to
reproduce and distribute the object code form of the Sample Code, provided
that You agree: (i) to not use Our name, logo, or trademarks to market Your
software product in which the Sample Code is embedded; (ii) to include a valid
copyright notice on Your software product in which the Sample Code is embedded;
and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and
against any claims or lawsuits, including attorneys’ fees, that arise or result
from the use or distribution of the Sample Code.
##############################################################################>

<#
.SYNOPSIS
Displays the identities allowed to delegate to ServerC
.DESCRIPTION
Retrives the msDS-AllowedToActOnBehalfOfOtherIdentity computer object attribute which contains an ACL. Displays only the identity portion of the ACL.
.PARAMETER ServerC
FQDN of ServerC
.PARAMETER DomainCCred
Credential to view the ServerC computer account from the domain where ServerC resides. Can be a domain admin, but only needs delegated authority to the computer object.
Will prompt for credential if not provided
.EXAMPLE
Get-RBKCD -ServerC sc.proseware.com
.EXAMPLE
Get-RBKCD -ServerC sc.proseware.com -Credential (Get-Credential proseware\adminacct)
.LINK
http://aka.ms/pskdh
#>
Function Get-RBKCD {
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('\w+\.\w+\.\w+')]
    [string]
    $ServerC,
    [Parameter(Mandatory=$true)]
    [PSCredential]
    $DomainCCred = (Get-Credential -Message 'DomainC credential')
)
    "Computers configured for resource-based Kerberos constrained delegation to $ServerC"
    (Get-ADComputer -Identity $ServerC.Substring(0,$ServerC.IndexOf('.')) -Credential $DomainCCred -Server $ServerC.Substring($ServerC.IndexOf('.')+1) -Properties 'msDS-AllowedToActOnBehalfOfOtherIdentity').'msDS-AllowedToActOnBehalfOfOtherIdentity'.Access.IdentityReference.Value
}


<#
.SYNOPSIS
Removes all accounts allowed to delegate to ServerC
.DESCRIPTION
Sets the msDS-AllowedToActOnBehalfOfOtherIdentity computer object attribute to $null (by using the aliased attribute PrincipalsAllowedToDelegateToAccount)
.PARAMETER ServerC
FQDN of ServerC
.PARAMETER DomainCCred
Credential to edit the ServerC computer account from the domain where ServerC resides. Can be a domain admin, but only needs delegated authority to the computer object.
Will prompt for credential if not provided
.EXAMPLE
Disable-RBKCD -ServerC sc.proseware.com
.EXAMPLE
Disable-RBKCD -ServerC sc.proseware.com -Credential (Get-Credential proseware\adminacct)
.LINK
http://aka.ms/pskdh
#>
Function Disable-RBKCD {
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('\w+\.\w+\.\w+')]
    [string]
    $ServerC,
    [Parameter(Mandatory=$true)]
    [PSCredential]
    $DomainCCred = (Get-Credential -Message 'DomainC credential')
)
    Set-ADComputer -Identity $ServerC.Substring(0,$ServerC.IndexOf('.')) -Credential $DomainCCred -Server $ServerC.Substring($ServerC.IndexOf('.')+1) -PrincipalsAllowedToDelegateToAccount $null
}


<#
.SYNOPSIS
Enables Resource-Based Kerberos Constrained Delegation for ServerB to access ServerC
.DESCRIPTION
Enables Resource-Based Kerberos Constrained Delegation for one or more ServerB computers to access one or more ServerC computers. Optionally, these computers can reside in separate domains, requiring two sets of credentials for the command.
.PARAMETER ServerB
FQDN of ServerB. Accepts an array.
.PARAMETER ServerC
FQDN of ServerC. Accepts an array.
.PARAMETER Credential
Credential when both ServerB and ServerC are in the same domain.
.PARAMETER DomainBCred
Credential to query the domain of the ServerB computer account, also having admin rights on ServerB.
.PARAMETER DomainCCred
Credential to update the ServerC computer account from the domain where ServerC resides. Can be a domain admin, but only needs delegated authority to the computer object.
.EXAMPLE 
Enable-RBKCD -ServerB sb.proseware.com -ServerC sc.proseware.com -Credential (Get-Credential)
Both ServerB and ServerC in the same domain.
.EXAMPLE
Enable-RBKCD -ServerB sb.proseware.com -ServerC ms1.alpineskihouse.com -DomainBCred (Get-Credential) -DomainCCred (Get-Credential)
ServerB and ServerC in different domains.
.EXAMPLE
Enable-RBKCD -ServerB sa.proseware.com,sb.proseware.com,sc.proseware.com -ServerC ms1.alpineskihouse.com,ms1.alpineskihouse.com -DomainBCred (Get-Credential) -DomainCCred (Get-Credential)
Multiple ServerB and multiple ServerC in different domains.
If passing multiples to either server parameter, they must be in the same domain. This is a limitation of the way the code is written. It is not a limitation of resource-based kerberos constrained delegation.
.NOTES
This code is still a work in progress. There are some obvious areas for optimization.
.LINK
http://aka.ms/pskdh
#>
Function Enable-RBKCD {
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true,ParameterSetName='1')]
    [Parameter(Mandatory=$true,ParameterSetName='2')]
    [ValidatePattern('\w+\.\w+\.\w+')]
    [string[]]
    $ServerB,
    [Parameter(Mandatory=$true,ParameterSetName='1')]
    [Parameter(Mandatory=$true,ParameterSetName='2')]
    [ValidatePattern('\w+\.\w+\.\w+')]
    [string[]]
    $ServerC,
    [Parameter(Mandatory=$true,ParameterSetName='1')]
    [PSCredential]
    $Credential,
    [Parameter(Mandatory=$true,ParameterSetName='2')]
    [PSCredential]
    $DomainBCred,
    [Parameter(Mandatory=$true,ParameterSetName='2')]
    [PSCredential]
    $DomainCCred
)
    If (!$PSBoundParameters.ContainsKey('DomainCCred')) {$DomainCCred = $DomainBCred = $Credential}

    # Split out the hostname and domain name portions of the FQDN where appropriate

    ForEach ($ServerCEach in $ServerC) {
        $C = Get-ADComputer -Identity $ServerCEach.Substring(0,$ServerCEach.IndexOf('.')) -Credential $DomainCCred -Server $ServerCEach.Substring($ServerCEach.IndexOf('.')+1) -Properties 'msDS-AllowedToActOnBehalfOfOtherIdentity'

        # We don't want to overwrite any pre-existing allowed delegations
        If ($C.'msDS-AllowedToActOnBehalfOfOtherIdentity') {
            $NullGuid = [GUID]'00000000-0000-0000-0000-000000000000'

            ForEach ($ServerBEach in $ServerB) {

                Write-Verbose "Allowing $ServerBEach to delegate to $ServerCEach"

                $B = Get-ADComputer -Identity $ServerBEach.Substring(0,$ServerBEach.IndexOf('.')) -Credential $DomainBCred -Server $ServerBEach.Substring($ServerBEach.IndexOf('.')+1)

                # Ran into difficulty appending computers to PrincipalsAllowedToDelegateToAccount.
                # Did this the hard way by directly updating the ACL stored in msDS-AllowedToActOnBehalfOfOtherIdentity.
                # There should be a better way to do this.
                $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $B.SID, 'GenericAll', 'Allow', $NullGuid, 'None', $NullGuid
                $C.'msDS-AllowedToActOnBehalfOfOtherIdentity'.AddAccessRule($ACE)

                $void = Invoke-Command -ComputerName $B.Name -Credential $DomainBCred -ScriptBlock {
                    klist purge -li 0x3e7
                }
            }

            # Could not get the Instance parameter to set the value, so changed method.
            #Set-ADComputer -Instance $C -Credential $DomainCCred -Server $ServerC.Substring($ServerC.IndexOf('.')+1)
            Set-ADObject -Identity $C -Replace @{'msDS-AllowedToActOnBehalfOfOtherIdentity'=$C.'msDS-AllowedToActOnBehalfOfOtherIdentity'} -Credential $DomainCCred -Server $ServerCEach.Substring($ServerCEach.IndexOf('.')+1)

        } Else {

            # If there are no other current delegations
            $B = ForEach ($ServerBEach in $ServerB) {
                Write-Verbose "Allowing $ServerBEach to delegate to $ServerCEach"
                Get-ADComputer -Identity $ServerBEach.Substring(0,$ServerBEach.IndexOf('.')) -Credential $DomainBCred -Server $ServerBEach.Substring($ServerBEach.IndexOf('.')+1)
            }
            Set-ADComputer -Identity $C -PrincipalsAllowedToDelegateToAccount $B -Credential $DomainCCred -Server $ServerCEach.Substring($ServerCEach.IndexOf('.')+1)

            $void = Invoke-Command -ComputerName $B.Name -Credential $DomainBCred -ScriptBlock {
                klist purge -li 0x3e7
            }
        }
    }
}


<#
.SYNOPSIS
Nested Invoke-Command from ServerB to ServerC
.DESCRIPTION
Passes fresh credentials to ServerC Invoke-Command from a nested Invoke-Command on ServerB with $using:. 
.PARAMETER ServerB
First hop computer
.PARAMETER ServerC
Second hop computer
.PARAMETER DomainBCred
Credentials to access ServerB
.PARAMETER DomainCCred
Credentials to access ServerC. This can be omitted if both ServerB and ServerC are in the same domain.
.EXAMPLE
Invoke-DoubleHop -ServerB sb -ServerC dc -DomainBCred $DomainBCred -Scriptblock {
    dir \\dc\c$
}
.EXAMPLE
$p = @{
    ServerB = 'sb'
    ServerC = 'dc1.alpineskihouse.com'
    DomainBCred = (Get-Credential)
    DomainCCred = (Get-Credential)
}
Invoke-DoubleHop @p -Scriptblock {
    dir C:\
}
.NOTES
The output PSComputerName property reflects ServerB, while the output is actually from ServerC.
.LINK
http://aka.ms/pskdh
#>
Function Invoke-DoubleHop {
[CmdletBinding()]
param(
    [parameter(mandatory=$true)]
    [string]
    $ServerB,
    [parameter(mandatory=$true)]
    [string]
    $ServerC,
    [parameter(mandatory=$true)]
    [PSCredential]
    $DomainBCred,
    [PSCredential]
    $DomainCCred,
    [parameter(mandatory=$true)]
    [Scriptblock]
    $Scriptblock
)
    If (!$PSBoundParameters.ContainsKey('DomainCCred')) {$DomainCCred = $DomainBCred}
    Write-Warning 'PSComputerName property reflects ServerB, while the output is actually from ServerC.'

    Invoke-Command -ComputerName $ServerB -Credential $DomainBCred -Verbose -ScriptBlock {
        # The Scriptblock gets serialized to a string when used remotely.
        # Recast it as a scriptblock.
        # Yes, this is a violation of PowerShell security best practices.
        $sb2 = [scriptblock]::Create($using:Scriptblock)
        Invoke-Command -ComputerName $using:ServerC -Credential $using:DomainCCred -ScriptBlock $sb2
    }
}
