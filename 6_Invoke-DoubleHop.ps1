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

# Avoid WinRM limitations of RB KCD by passing creds with $Using to the second hop

$ServerB = 'sb'
$ServerC = 'sc'

$Cred = (Get-Credential proseware\administrator)

# Works without RB KCD, passing creds again with $using:
# NOTE: PSComputerName returns ServerB, not ServerC!
Invoke-Command -ComputerName $ServerB -Credential $Cred -ScriptBlock {

    Invoke-Command -ComputerName $using:ServerC -Credential $using:Cred -ScriptBlock {"Invoked on ServerC: $(hostname)"}

    $cim = New-CimSession -ComputerName $using:ServerC -Credential $using:Cred
    Get-CimInstance -ClassName win32_computersystem -CimSession $cim
    Get-ScheduledTask -CimSession $cim | Select-Object -First 1
    Get-NetAdapter -CimSession $cim | Select-Object -First 1
    Remove-CimSession $cim

}


# Works across domains

$ServerB = 'sb.proseware.com'
$ServerC = 'ms1.alpineskihouse.com'

$DomainBCred = (Get-Credential proseware\administrator)
$DomainCCred = (Get-Credential alpineskihouse\administrator)

# Works without RB KCD, passing creds again with $using:
# NOTE: PSComputerName returns ServerB, not ServerC!
Invoke-Command -ComputerName $ServerB -Credential $DomainBCred -ScriptBlock {

    Invoke-Command -ComputerName $using:ServerC -Credential $using:DomainCCred -ScriptBlock {"Invoked on ServerC: $(hostname)"}

    $cim = New-CimSession -ComputerName $using:ServerC -Credential $using:DomainCCred
    Get-CimInstance -ClassName win32_computersystem -CimSession $cim
    Get-ScheduledTask -CimSession $cim | Select-Object -First 1
    Get-NetAdapter -CimSession $cim | Select-Object -First 1
    Remove-CimSession $cim

}



# Helper function INVOKE-DOUBLEHOP
Import-Module C:\PshSummit\RBKCD.psm1
Get-Command -Module RBKCD

Invoke-DoubleHop -ServerB sb -ServerC dc -DomainBCred $DomainBCred -Scriptblock {
    dir \\dc\c$
}

Invoke-DoubleHop -ServerB sb -ServerC dc -DomainBCred $DomainBCred -Scriptblock {
    $PSSenderInfo
    $PSSenderInfo.UserInfo.Identity
    $PSSenderInfo.UserInfo.WindowsIdentity
}

Invoke-DoubleHop -ServerB sb -ServerC dc -DomainBCred $DomainBCred -Scriptblock {
    hostname
    $env:COMPUTERNAME
    Get-WmiObject Win32_ComputerSystem
    Get-CimInstance Win32_ComputerSystem
}

Invoke-DoubleHop -ServerB sb -ServerC dc -DomainBCred $DomainBCred -Scriptblock {
    Unlock-ADAccount -Identity alice -Verbose
}

Invoke-DoubleHop -ServerB sb -ServerC dc -DomainBCred $DomainBCred -Scriptblock {
    Get-WinEvent -LogName Microsoft-Windows-WinRM/Operational -MaxEvents 5
}


# Now cross-domain

$p = @{
    ServerB = 'sb'
    ServerC = 'dc1.alpineskihouse.com'
    DomainBCred = $DomainBCred
    DomainCCred = $DomainCCred 
}

Invoke-DoubleHop @p -Scriptblock {
    dir C:\
}

Invoke-DoubleHop @p -Scriptblock {
    $env:COMPUTERNAME
    $PSSenderInfo
}

Invoke-DoubleHop @p -Scriptblock {
    hostname
    $env:COMPUTERNAME
    Get-WmiObject Win32_ComputerSystem
    Get-CimInstance Win32_ComputerSystem
}

Invoke-DoubleHop @p -Scriptblock {
    Unlock-ADAccount -Identity alice -Verbose
}


# Now criss-cross-domain
# proseware -> alpineskihouse -> proseware

$p = @{
    ServerB = 'ms1.alpineskihouse.com'
    ServerC = 'sb.proseware.com'
    DomainBCred = $DomainCCred
    DomainCCred = $DomainBCred 
}

Invoke-DoubleHop @p -Scriptblock {
    dir \\sb\C$
}

Invoke-DoubleHop @p -Scriptblock {
    $env:COMPUTERNAME
    $PSSenderInfo
    $PSSenderInfo.UserInfo.Identity
    $PSSenderInfo.UserInfo.WindowsIdentity
}

Invoke-DoubleHop @p -Scriptblock {
    hostname
    $env:COMPUTERNAME
    Get-WmiObject Win32_ComputerSystem
    Get-CimInstance Win32_ComputerSystem
}
