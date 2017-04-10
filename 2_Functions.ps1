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

Import-Module C:\PshSummit\RBKCD.psm1
Get-Command -Module RBKCD

break

Get-Help Enable-RBKCD -ShowWindow
Get-Command Enable-RBKCD -Syntax

# Get creds for both domains
$DomainBCred = (Get-Credential proseware\administrator)
$DomainCCred = (Get-Credential alpineskihouse\administrator)


# Enable RB KCD
$p = @{
    ServerB     = 'sb.proseware.com'
    ServerC     = 'sc.proseware.com'
    Credential  = $DomainBCred
    Verbose     = $true
}
Enable-RBKCD @p

Get-RBKCD -ServerC sc.proseware.com -DomainCCred $DomainBCred

Invoke-Command -ComputerName sb -ScriptBlock {
    dir \\sc\C$
}

Disable-RBKCD -ServerC sc.proseware.com -DomainCCred $DomainBCred

# Try again to see failure without RB KCD
