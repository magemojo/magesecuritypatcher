# Mage Security Patcher

###Updates
2/7/17 - Updated to include patch SUPEE-9652

###About
A more effective alternative to the standard magento patches. Instead of working on diffs of files it updates the entire file to the fully patched version. The complete patch also adds in form keys into custom templates that would not be included in the standard patch libraries.

Works for Magento 1 Community Versions 1.5.0.1 - Current

###Disclaimer
This script applies all applicable patches for Magento. It will overwite any files that patches have been historically applied to. Any modifications that were made to core files that patches have been applied to will be overwritten as a result. 

###Usage
Executing a dryrun will list the files to be overwritten / modified:

`sh magesecuritypatcher.sh <dryrun>`

Execute the patcher:

`sh magesecuritypatcher.sh`

*A backup of overwritten / modified files will be created as
patch-backup-<timestamp>.tar.gz*
