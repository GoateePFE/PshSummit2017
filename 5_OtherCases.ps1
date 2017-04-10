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

<#
CASE:
    Workstation -> JumpServer -> Domain Controller
#>

$p = @{
    ServerB     = 'sb.proseware.com'
    ServerC     = 'dc.proseware.com'
    Credential  = $DomainBCred
    Verbose     = $true
}
Enable-RBKCD @p

Get-RBKCD -ServerC dc.proseware.com -DomainCCred $DomainBCred

Enter-PSSession -ComputerName sb
    cd \
    Get-Process lsass -ComputerName dc
    Get-EventLog -LogName System -Newest 1 -ComputerName dc
    #This line takes a while.
    #Get-Service -Name bits -ComputerName dc
    Get-DnsServer -ComputerName dc
    (Get-DnsServer -ComputerName dc).ServerSetting
    Add-DnsServerResourceRecordA -Name foo -IPv4Address 172.168.1.12 -ZoneName proseware.com -ComputerName dc -PassThru
    Remove-DnsServerResourceRecord -RRType A -Name foo -ZoneName proseware.com -ComputerName dc -PassThru -Force
Exit-PSSession

# Now demonstrate without RB KCD
Disable-RBKCD -ServerC dc.proseware.com -DomainCCred $DomainBCred
