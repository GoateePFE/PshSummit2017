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
CASE: Install software on remote machines
      while pulling source from third server,
      in this case also in a different domain

               /     ServerB     \
    ServerA    ->    ServerB     ->    ServerC
               \     ServerB     /

    Invoke-Command
                             Copy from ServerC
                 Install software
#>

# Multiple ServerB
# Enable RB KCD
$p = @{
    ServerB     = 'sb.proseware.com','sc.proseware.com'
    ServerC     = 'ms1.alpineskihouse.com'
    DomainBCred = $DomainBCred
    DomainCCred = $DomainCCred
    Verbose     = $true
}
Enable-RBKCD @p

Get-RBKCD -ServerC ms1.alpineskihouse.com -DomainCCred $DomainCCred

# Try to install software on these three computers.
# Pull source from "ServerC" in other domain.
# Only SB and SC have been delegated.
$Computers = 'sa','sb','sc'

Invoke-Command -ComputerName $Computers -ScriptBlock {

    $ErrorActionPreference = 'Stop'
    Try {
        md C:\temp\ -ErrorAction SilentlyContinue | Out-Null

        # Must use SMB file copy. WinRM file copy not supported with RB KCD.
        # This line fails without RB KCD.
        Copy-Item -Path \\ms1.alpineskihouse.com\Source\LogParser.msi `
            -Destination c:\temp\LogParser.msi -Force

        # Change /i to /x to uninstall
        $proc = Invoke-WMIMethod Win32_Process -name Create `
            -ArgumentList 'msiexec /i "c:\temp\LogParser.msi" /qn /norestart'
        do {$a = Get-Process -Id $proc.processid -ErrorAction SilentlyContinue}
        While ($a -ne $null)

        "Software installed on $(hostname)"
    }
    Catch {
        "Error installing software on $(hostname)"
    }
}


# Validate install
Invoke-Command -ComputerName $Computers -ScriptBlock {
    #dir c:\temp\
    #Get-CimInstance -Query 'SELECT * FROM Win32_Product WHERE Name LIKE "%parser%"'
    #Get-Package
    "$(hostname) $(Test-Path 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe')"
}



# Turn off delegation
Get-RBKCD -ServerC ms1.alpineskihouse.com -DomainCCred $DomainCCred

Disable-RBKCD -ServerC ms1.alpineskihouse.com -DomainCCred $DomainCCred

Get-RBKCD -ServerC ms1.alpineskihouse.com -DomainCCred $DomainCCred
