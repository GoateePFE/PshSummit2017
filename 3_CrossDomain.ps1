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

# Now go across domains

# Direct success
dir \\ms1.alpineskihouse.com\Source

# Second hop failure
Invoke-Command -ComputerName sb -ScriptBlock {
    dir \\ms1.alpineskihouse.com\Source
}

# Enable RB KCD
$p = @{
    ServerB     = 'sb.proseware.com'
    ServerC     = 'ms1.alpineskihouse.com'
    DomainBCred = $DomainBCred
    DomainCCred = $DomainCCred
    Verbose     = $true
}
Enable-RBKCD @p

# Validate
Get-RBKCD -ServerC ms1.alpineskihouse.com -DomainCCred $DomainCCred


# Second hop test
# Success with RB KCD
Invoke-Command -ComputerName sb -ScriptBlock {
    dir \\ms1.alpineskihouse.com\Source
}
# Failure without RB KCD (different ServerB for comparison)
Invoke-Command -ComputerName sc -ScriptBlock {
    dir \\ms1.alpineskihouse.com\Source
}


# Multiple ServerB
# Enable RB KCD
$p = @{
    ServerB     = 'sa.proseware.com','sb.proseware.com','sc.proseware.com'
    ServerC     = 'ms1.alpineskihouse.com'
    DomainBCred = $DomainBCred
    DomainCCred = $DomainCCred
    Verbose     = $true
}
Enable-RBKCD @p

Get-RBKCD -ServerC ms1.alpineskihouse.com -DomainCCred $DomainCCred


# Second hop test
Invoke-Command -ComputerName sa -ScriptBlock {
    dir \\ms1.alpineskihouse.com\Source
}

Invoke-Command -ComputerName sb -ScriptBlock {
    dir \\ms1.alpineskihouse.com\Source
}

Invoke-Command -ComputerName sc -ScriptBlock {
    dir \\ms1.alpineskihouse.com\Source
}


# Turn it off and try again
Disable-RBKCD -ServerC ms1.alpineskihouse.com -DomainCCred $DomainCCred




# Multiple ServerB & ServerC
$p = @{
    ServerB     = 'sa.proseware.com','sb.proseware.com','sc.proseware.com'
    ServerC     = 'ms1.alpineskihouse.com','dc1.alpineskihouse.com'
    DomainBCred = $DomainBCred
    DomainCCred = $DomainCCred
    Verbose     = $true
}
Enable-RBKCD @p

# Validate
# cross-domain returns the SID
Get-RBKCD -ServerC ms1.alpineskihouse.com -DomainCCred $DomainCCred
Get-RBKCD -ServerC dc1.alpineskihouse.com -DomainCCred $DomainCCred

Invoke-Command -ComputerName sa,sb,sc -ScriptBlock {
    dir \\ms1.alpineskihouse.com\source\*.msi -File
}

Invoke-Command -ComputerName sa,sb,sc -ScriptBlock {
    dir \\dc1.alpineskihouse.com\sysvol
}



# All computers with RB KCD configured
Get-ADComputer -LDAPFilter '(msDS-AllowedToActOnBehalfOfOtherIdentity=*)' -Properties PrincipalsAllowedToDelegateToAccount -Server dc1.alpineskihouse.com | Format-List Name,PrincipalsAllowedToDelegateToAccount
Get-ADComputer -LDAPFilter '(msDS-AllowedToActOnBehalfOfOtherIdentity=*)' -Properties PrincipalsAllowedToDelegateToAccount -Server dc.proseware.com | Format-List Name,PrincipalsAllowedToDelegateToAccount

# Clear all computers with this configured
Get-ADComputer -LDAPFilter '(msDS-AllowedToActOnBehalfOfOtherIdentity=*)' -Server dc1.alpineskihouse.com | % {Set-ADComputer -Identity $_ -PrincipalsAllowedToDelegateToAccount $null -Server dc1.alpineskihouse.com -Credential $DomainCCred}
Get-ADComputer -LDAPFilter '(msDS-AllowedToActOnBehalfOfOtherIdentity=*)' -Server dc.proseware.com | % {Set-ADComputer -Identity $_ -PrincipalsAllowedToDelegateToAccount $null -Server dc.proseware.com -Credential $DomainBCred}
