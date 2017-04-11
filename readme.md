## PowerShell Remoting and Kerberos Double Hop: Old Problem - New Secure Solution

## PowerShell and DevOps Global Summit 2017

This week I enjoyed presenting at the annual PowerShell Summit.
If you have not attended, I highly encourage it.
You will get to meet PowerShell team members from Microsoft, MVPs, and the people you follow on Twitter!
Follow [@PshSummit](https://twitter.com/PSHSummit) on Twitter to get the alerts for registration.
I even work for Microsoft, and I learn a ton every year from the amazing sessions.
It is also great connecting with everyone in the PowerShell community.

## tl;dr
* This is a follow up to my [previous blog post](https://blogs.technet.microsoft.com/ashleymcglone/2016/08/30/powershell-remoting-kerberos-double-hop-solved-securely/) on Kerberos double hop and PowerShell remoting.
* I have published some helper functions for working with **resource-based Kerberos constrained delegation** (**RB KCD**) and PowerShell remoting: `Enable-RBKCD`, `Disable-RBKCD`, `Get-RBKCD`.
* Get the files and slides [on my GitHub here](https://github.com/GoateePFE/PshSummit2017).
* RB KCD works with a limited set of commands and functions running under SYSTEM account in the kernel context.
* RB KCD does not support WinRM / PowerShell remoting, because that runs under the NETWORK account.
* For cases where RB KCD does not work you can nest two `Invoke-Command` statements to make the double hop. See helper function `Invoke-DoubleHop`.

## The Problem
### Classic Kerberos Double Hop
I am on *ServerA*, connected to *ServerB* where I need to reach *ServerC*.
I have permissions to ServerC, but I still get *Access Denied*.
Default Kerberos rules prevent ServerB from passing credentials to ServerC.
The most common examle is a user (ServerA) connected to a web server (ServerB/frontend) that needs to use the user's credentials to access a database server (ServerC/backend).
In a [previous blog post](https://blogs.technet.microsoft.com/ashleymcglone/2016/08/30/powershell-remoting-kerberos-double-hop-solved-securely/) I described multiple popular (and not-so-popular) work-arounds.

### Scenario A: Jump Server
From my workstation I connect to my jump server (tool server, etc. whatever you like to call it) via PowerShell remoting (`Enter-PSSession`, `Invoke-Command`).
From that server I want to reach out and collect data from multiple other servers for a report.
I am in the Administrators group on all of these servers, but I get an *Access Denied* when attempting to access them from my jump server.

Why not connect directly to the servers? Perhaps I have limited network connectivity or restricted routing.
Maybe it is a DMZ or a hosted environment.
There are many legitimate scenarios why you may choose this approach.

### Scenario B: Remote Software Install
Another popular scenario is installing software remotely.
From my workstation (ServerA) I want to fan out to 50 servers (ServerB) and install an application whose source files are hosted on a file share (ServerC).
Here again I will get *Access Denied* at the file share even though I know I have permissions.
This is Kerberos double hop.

### Scenario X
There are many more scenarios for Kerberos double hop.
RB KCD will help with some of them.
`Invoke-DoubleHop` should help with more of them.
And some will likely have no other choice but to continue using *CredSSP* for the time being.
You will need to experiment to see which commands are compatible with RB KCD (running as SYSTEM in kernel context).

For example, from your workstation you connect to your SharePoint server with PowerShell remoting.
The SharePoint cmdlets need to access a backend SQL server, but they fail.
Typically CredSSP is the solution.
I have some peers who have not been successful yet getting RB KCD to work with this case.
I suspicion that it would need to be configured on service accounts and may work then.
Let me know if you figure this one out.

## PowerShell and DevOps Global Summit 2017
In a [previous blog post](https://blogs.technet.microsoft.com/ashleymcglone/2016/08/30/powershell-remoting-kerberos-double-hop-solved-securely/) I described the benefits of *resource-based Kerberos constrained delegation* and how it can apply to PowerShell remoting.
It is not a complete solution, but it works for the key scenarios described above and a few others.
The PowerShell documentation team took that article, tweaked it, and turned it into a documentation page [here](https://msdn.microsoft.com/en-us/powershell/scripting/setup/ps-remoting-second-hop).

This week I presented the topic and demos at the **PowerShell and DevOps Global Summit 2017**.
You can catch the video on YouTube or Pluralsight once it goes live.
Look for *PowerShell Remoting and Kerberos Double Hop: Old Problem - New Secure Solution*.
The demos files and slides are available [on my GitHub here](https://github.com/GoateePFE/PshSummit2017).

## Two Solutions, One Module
I created a helper module for quickly configuring RB KCD and for cheating with nested `Invoke-Command` commands.

```
PS> Import-Module rbkcd.psm1

PS> Get-Command -Module RBKCD

CommandType Name             Version Source
----------- ----             ------- ------
Function    Disable-RBKCD    0.0     RBKCD
Function    Enable-RBKCD     0.0     RBKCD
Function    Get-RBKCD        0.0     RBKCD
Function    Invoke-DoubleHop 0.0     RBKCD
```

Here are some examples:
```PowerShell
# Both ServerB and ServerC in the same domain.
Enable-RBKCD -ServerB sb.proseware.com -ServerC sc.proseware.com -Credential (Get-Credential)

# ServerB and ServerC in different domains.
Enable-RBKCD -ServerB sb.proseware.com -ServerC ms1.alpineskihouse.com -DomainBCred (Get-Credential) -DomainCCred (Get-Credential)

# See which identities are allowed to delegate to ServerC
Get-RBKCD -ServerC sc.proseware.com -Credential (Get-Credential proseware\adminacct)

# Remove all identities allowed to delegate to ServerC
Disable-RBKCD -ServerC sc.proseware.com -Credential (Get-Credential proseware\adminacct)

# For scenarios that do not work with RB KCD
Invoke-DoubleHop -ServerB sb -ServerC sc -DomainBCred $DomainBCred -Scriptblock {
    dir \\sc\c$
}
```

While these functions were written to help with RB KCD for PowerShell remoting, they could be used for any other RB KCD scenario.
Note that these only work with computer accounts.
You could expand the code to work with service accounts or user accounts also.

You can share these RB KCD articles and scripts with this short link: [http://aka.ms/pskdh](http://aka.ms/pskdh)

## Enjoy

This is a bit of a niche topic, but lots of people struggle with it. Hopefully this was helpful.
**Please use the comments below to help the community understand where this was helpful for you and where is was *not* helpful.** This is an on-going research project for me, and your feedback is valuable.