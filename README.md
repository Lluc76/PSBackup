# PSBackup
A script made with Powershell to make backups, include the possibility of version control with GIT

## How it works:
In a csv file, you need to specify the Soruce and the Destination (File or Folder), delimited with a _;_ between columns (Only 2 accepted, Source & Destination) (Only _%username%_ variable accepted, no other wildcards will work)<br />
If the Destination doesn't exists will copy directly, but if exists, will navigate through every subpath checking if the files are equal or not<br />
If are the same exact file will not override, otherwise will be overwritten<br />
If a file/folder is deleted form the origin, and exists in the destination, will NOT be deleted in this last one<br />
All the events will be logged in log file<br />

## GIT Configuration:
_$EnableGit_ If it's $True will run Git<br />
_$GitDir_ An array when every directory specified will create a _.git_ folder<br />
_$GitName_ Your Git Name<br />
_$GitEmail_ Your Git email<br />
_$GitBranch_ The branch name<br />
