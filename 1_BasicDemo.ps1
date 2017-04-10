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

break

# proseware.com domain
# servers: dc, sa, sb, sc

$B = Get-ADComputer -Identity sb
$C = Get-ADComputer -Identity sc

# Test before the delegation
$cred = Get-Credential proseware\administrator
# Note that SMB firewall rule is enabled to allow SMB on server SC
Invoke-Command -ComputerName $B.Name -Credential $cred -ScriptBlock {
    dir \\$($Using:C.Name)\C$
}

# Allow ServerB to delegate to ServerC
Set-ADComputer -Identity $C -PrincipalsAllowedToDelegateToAccount $B
$void = Invoke-Command -ComputerName $B.Name -ScriptBlock {
    klist purge -li 0x3e7
}

# View the computer account attribute
$ServerC = Get-ADComputer -Identity $C -Properties PrincipalsAllowedToDelegateToAccount,'msDS-AllowedToActOnBehalfOfOtherIdentity'
$ServerC.PrincipalsAllowedToDelegateToAccount
$ServerC.'msDS-AllowedToActOnBehalfOfOtherIdentity'
$ServerC.'msDS-AllowedToActOnBehalfOfOtherIdentity'.Access

# Test again with success now

# Remove delegation
Set-ADComputer -Identity $C -PrincipalsAllowedToDelegateToAccount $null

# Test again with failure after removal
