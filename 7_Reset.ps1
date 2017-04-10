# All computers with RB KCD configured
Get-ADComputer -LDAPFilter '(msDS-AllowedToActOnBehalfOfOtherIdentity=*)' -Properties PrincipalsAllowedToDelegateToAccount -Server dc1.alpineskihouse.com | Format-List Name,PrincipalsAllowedToDelegateToAccount
Get-ADComputer -LDAPFilter '(msDS-AllowedToActOnBehalfOfOtherIdentity=*)' -Properties PrincipalsAllowedToDelegateToAccount -Server dc.proseware.com | Format-List Name,PrincipalsAllowedToDelegateToAccount

# Clear all computers with this configured
Get-ADComputer -LDAPFilter '(msDS-AllowedToActOnBehalfOfOtherIdentity=*)' -Server dc1.alpineskihouse.com | % {Set-ADComputer -Identity $_ -PrincipalsAllowedToDelegateToAccount $null -Server dc1.alpineskihouse.com -Credential $DomainCCred}
Get-ADComputer -LDAPFilter '(msDS-AllowedToActOnBehalfOfOtherIdentity=*)' -Server dc.proseware.com | % {Set-ADComputer -Identity $_ -PrincipalsAllowedToDelegateToAccount $null -Server dc.proseware.com -Credential $DomainBCred}
