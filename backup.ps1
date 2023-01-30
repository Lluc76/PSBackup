# Main Configuration
$scriptLocation = Get-Location
$Logfile = "$scriptLocation\backup.log"
$csvFile = "$scriptLocation\paths.csv"
$ErrorView = 'CategoryView'

# Git Configuration
$EnableGit = $True
$GitDir = @('E:\BackUp')
$GitName = "YourName"
$GitEmail = "Your@Email.com"
$GitBranch = "backup"

function StartGit
{
    # Check $EnableGit variable
    if (!($EnableGit))
    {
        WriteLog "[Info] Git is not Enabled"
        return 0
    }

    # Check if Git is installed
    try
    {
        git | Out-Null
        WriteLog "[Info] Git is installed"
    }
    catch [System.Management.Automation.CommandNotFoundException]
    {
        WriteLog "[Error] Git is not installed"
        return 1
    }

    # Run Git's procedure foreach specified folder
    foreach ($git in $GitDir)
    {
        $date = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
        # If git is not initialized
        if (!(Test-Path -Path "$git\.git" -PathType container))
        {            
            Set-Location $git
            WriteLog "[Info] $(git init)"
            if (!($?))
            {
                WriteLog "[Error] Creating GIT Repository at `"$git`""
            }
            
        }

        # Git Configuration
        git config --global user.name $GitName
        git config --global user.email $GitEmail
        git config --global init.defaultBranch $GitBranch

        # Staging and commit
        git add .
        if (git diff --name-only --cached)
        {
            git commit -m `"$date`"
            if ($?)
            {
                WriteLog "[Info] Commited at `"$git`""
            } else {
                WriteLog "[Error] Commiting at `"$git`""
            }

        } else {
            WriteLog "[Warn] Couldn't commit due a no staged files at `"$git`""
        }
        
        # Returns to script path
        Set-Location $scriptLocation
    }
}

function backup 
{
    param (
        [Parameter(Mandatory)]
        [String]$Src,
        [Parameter(Mandatory)]
        [String]$Dest
    )

    # Is a FILE
    if (Test-Path -LiteralPath $Src -PathType leaf)
    {
        # If Dest path is valid
        if (Test-Path -LiteralPath $Dest -IsValid)
        {
            # If the Dest path exists
            if (Test-Path -LiteralPath $Dest )
            {
                WriteLog "[Info] Dest file `"$Dest`" already exists"
                # If the file has changed
                if (!(compare_file $Src $Dest))
                {
                    Copy-Item -LiteralPath $Src $Dest -Force
                    if ($?)
                    {
                        WriteLog "[Info] Success: Copied `"$Src`" to `"$Dest`""
                    } else {
                        WriteLog "[Info] Failed: Trying to copy `"$Src`" to `"$Dest`""
                    }
                }

            } else {
                # If the Dest path doesn't exists
                WriteLog "[Info] Dest file `"$Dest`" doesn't exists"

                #Get only parent folder
                $parent = ([System.IO.FileInfo]$Dest).Directory

                # Creates parent folder
                New-Item $parent -ItemType "directory" -Force | Out-Null
                if ($?)
                {
                    WriteLog "[Info] Created parent folder `"$parent`""
                } else {
                    WriteLog "[Error] Creating parent folder `"$parent`""
                }

                # Copy file into parent folder
                Copy-Item -LiteralPath $Src $Dest -Force -Recurse
                if ($?)
                {
                    WriteLog "[Info] Success: Copied `"$Src`" to `"$Dest`""
                } else {
                    WriteLog "[Error] Failed: Trying to copy `"$Src`" to `"$Dest`""
                }
            }

        } else {
            WriteLog "[Error] The Dest path `"$Dest`" doesn't exists"
        }

    # Is a FOLDER
    } elseif (Test-Path -LiteralPath $Src -PathType container){

        # If Dest Folder Path is valid
        if (Test-Path -LiteralPath $Dest -IsValid)
        {
            # If the Dest Folder exists
            if (Test-Path -LiteralPath $Dest -PathType container)
            {
                WriteLog "[Info] Dest folder `"$Dest`" already exists"

                $files = (Get-ChildItem -LiteralPath $Src -Force | Select-Object FullName)

                # Recursively calls the backup function
                foreach ($file in $files.FullName){
                    $destFile = $file.replace($Src,$Dest)
                    backup $file $destFile
                }

            } else {

                WriteLog "[Info] Dest folder `"$Dest`" doesn't exists"
                Copy-Item -LiteralPath $Src $Dest -Force -Recurse
                if ($?)
                {
                    WriteLog "[Info] Success: Copied folder `"$Src`" to `"$Dest`""
                } else {
                    WriteLog "[Error] Failed: Trying to copy folder `"$Src`" to `"$Dest`""
                }                    
            }

        } else {
            WriteLog "[Error] The Dest path: `"$Dest`" is not valid"
        }
         
    } else {
        WriteLog "[Error] The Source `"$Src`" doesn't exists"
    }
}

function compare_file 
{
    param (
        [Parameter(Mandatory)]
        [String]$Src,
        [Parameter(Mandatory)]
        [String]$Dest
    )

    $HashSrc = Get-FileHash -LiteralPath $Src -Algorithm "SHA256"
    $HashDest = Get-FileHash -LiteralPath $Dest -Algorithm "SHA256"

    if ($hashSrc.Hash -eq $hashDest.Hash)
    {
        WriteLog "[Info] Same files: `"$Src`" `"$Dest`""
        return $True
    }

    WriteLog "[Info] Different Files: `"$Src`" `"$Dest`""
    return $False
}

function WriteLog
{
    Param (
        [Parameter(ValuefromPipeline)]
        [string]$LogString
    )
    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $LogMessage = "$Stamp $LogString"
    Add-content $LogFile -value $LogMessage
}

$CSV = Import-Csv -LiteralPath $CSVFile -Delimiter ";" -Header 'Src', 'Dest'

foreach ($row in $CSV)
{
    # Changing Wildcards to Environment Variables
    $row.Src = $row.Src.replace('%username%',$env:UserName)
    $row.Dest = $row.Dest.replace('%username%',$env:UserName)
    backup $row.Src $row.Dest
}

StartGit