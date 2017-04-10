# Help for module RBKCD

## Disable-RBKCD

### Synopsis
Removes all accounts allowed to delegate to ServerC

### Description
Sets the msDS-AllowedToActOnBehalfOfOtherIdentity computer object attribute to $null (by using the aliased attribute PrincipalsAllowedToDelegateToAccount)

### Parameters

-ServerC <String>
    FQDN of ServerC
    
    Required?                    true
    Position?                    1
    Default value                
    Accept pipeline input?       false
    Accept wildcard characters?  false
    

-DomainCCred <PSCredential>
    Credential to edit the ServerC computer account from the domain where ServerC resides. Can be a domain admin, but only 
    needs delegated authority to the computer object.
    Will prompt for credential if not provided
    
    Required?                    true
    Position?                    2
    Default value                (Get-Credential -Message 'DomainC credential')
    Accept pipeline input?       false
    Accept wildcard characters?  false
    

### Examples
-------------------------- EXAMPLE 1 --------------------------

```
PS C:\> Disable-RBKCD -ServerC sc.proseware.com

```
-------------------------- EXAMPLE 2 --------------------------

```
PS C:\> Disable-RBKCD -ServerC sc.proseware.com -Credential (Get-Credential proseware\adminacct)

```

## Enable-RBKCD

### Synopsis
Enables Resource-Based Kerberos Constrained Delegation for ServerB to access ServerC

### Description
Enables Resource-Based Kerberos Constrained Delegation for one or more ServerB computers to access one or more ServerC computers. Optionally, these computers can reside in separate domains, requiring two sets of credentials for the command.

### Parameters

-ServerB <String[]>
    FQDN of ServerB. Accepts an array.
    
    Required?                    true
    Position?                    named
    Default value                
    Accept pipeline input?       false
    Accept wildcard characters?  false
    

-ServerC <String[]>
    FQDN of ServerC. Accepts an array.
    
    Required?                    true
    Position?                    named
    Default value                
    Accept pipeline input?       false
    Accept wildcard characters?  false
    

-Credential <PSCredential>
    Credential when both ServerB and ServerC are in the same domain.
    
    Required?                    true
    Position?                    named
    Default value                
    Accept pipeline input?       false
    Accept wildcard characters?  false
    

-DomainBCred <PSCredential>
    Credential to query the domain of the ServerB computer account, also having admin rights on ServerB.
    
    Required?                    true
    Position?                    named
    Default value                
    Accept pipeline input?       false
    Accept wildcard characters?  false
    

-DomainCCred <PSCredential>
    Credential to update the ServerC computer account from the domain where ServerC resides. Can be a domain admin, but only 
    needs delegated authority to the computer object.
    
    Required?                    true
    Position?                    named
    Default value                
    Accept pipeline input?       false
    Accept wildcard characters?  false
    

### Notes
This code is still a work in progress. There are some obvious areas for optimization.

### Examples
-------------------------- EXAMPLE 1 --------------------------

```
PS C:\> Enable-RBKCD -ServerB sb.proseware.com -ServerC sc.proseware.com -Credential (Get-Credential)
Both ServerB and ServerC in the same domain.

```
-------------------------- EXAMPLE 2 --------------------------

```
PS C:\> Enable-RBKCD -ServerB sb.proseware.com -ServerC ms1.alpineskihouse.com -DomainBCred (Get-Credential) -DomainCCred (Get-Credential)
ServerB and ServerC in different domains.

```
-------------------------- EXAMPLE 3 --------------------------

```
PS C:\> Enable-RBKCD -ServerB sa.proseware.com,sb.proseware.com,sc.proseware.com -ServerC ms1.alpineskihouse.com,ms1.alpineskihouse.com -DomainBCred (Get-Credential) -DomainCCred (Get-Credential)
Multiple ServerB and multiple ServerC in different domains.
If passing multiples to either server parameter, they must be in the same domain. This is a limitation of the way the code is written. It is not a limitation of resource-based kerberos constrained delegation.

```

## Get-RBKCD

### Synopsis
Displays the identities allowed to delegate to ServerC

### Description
Retrives the msDS-AllowedToActOnBehalfOfOtherIdentity computer object attribute which contains an ACL. Displays only the identity portion of the ACL.

### Parameters

-ServerC <String>
    FQDN of ServerC
    
    Required?                    true
    Position?                    1
    Default value                
    Accept pipeline input?       false
    Accept wildcard characters?  false
    

-DomainCCred <PSCredential>
    Credential to view the ServerC computer account from the domain where ServerC resides. Can be a domain admin, but only 
    needs delegated authority to the computer object.
    Will prompt for credential if not provided
    
    Required?                    true
    Position?                    2
    Default value                (Get-Credential -Message 'DomainC credential')
    Accept pipeline input?       false
    Accept wildcard characters?  false
    

### Examples
-------------------------- EXAMPLE 1 --------------------------

```
PS C:\> Get-RBKCD -ServerC sc.proseware.com

```
-------------------------- EXAMPLE 2 --------------------------

```
PS C:\> Get-RBKCD -ServerC sc.proseware.com -Credential (Get-Credential proseware\adminacct)

```

## Invoke-DoubleHop

### Synopsis
Nested Invoke-Command from ServerB to ServerC

### Description
Passes fresh credentials to ServerC Invoke-Command from a nested Invoke-Command on ServerB with $using:.

### Parameters

-ServerB <String>
    First hop computer
    
    Required?                    true
    Position?                    1
    Default value                
    Accept pipeline input?       false
    Accept wildcard characters?  false
    

-ServerC <String>
    Second hop computer
    
    Required?                    true
    Position?                    2
    Default value                
    Accept pipeline input?       false
    Accept wildcard characters?  false
    

-DomainBCred <PSCredential>
    Credentials to access ServerB
    
    Required?                    true
    Position?                    3
    Default value                
    Accept pipeline input?       false
    Accept wildcard characters?  false
    

-DomainCCred <PSCredential>
    Credentials to access ServerC. This can be omitted if both ServerB and ServerC are in the same domain.
    
    Required?                    false
    Position?                    4
    Default value                
    Accept pipeline input?       false
    Accept wildcard characters?  false
    

-Scriptblock <ScriptBlock>
    
    Required?                    true
    Position?                    5
    Default value                
    Accept pipeline input?       false
    Accept wildcard characters?  false
    

### Notes
The output PSComputerName property reflects ServerB, while the output is actually from ServerC.

### Examples
-------------------------- EXAMPLE 1 --------------------------

```
PS C:\> Invoke-DoubleHop -ServerB sb -ServerC dc -DomainBCred $DomainBCred -Scriptblock {
dir \\dc\c$
}

```
-------------------------- EXAMPLE 2 --------------------------

```
PS C:\> $p = @{
ServerB = 'sb'
    ServerC = 'dc1.alpineskihouse.com'
    DomainBCred = (Get-Credential)
    DomainCCred = (Get-Credential)
}

Invoke-DoubleHop @p -Scriptblock {
    dir C:\
}

```
