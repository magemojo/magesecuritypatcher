# Mage Security Patcher

###Updates
2/7/17 - Updated to include patch SUPEE-9652

###About
Mage Security Patcher is a more effective alternative to the standard magento patches. Patching Magento is prone to failure because you are applying patches over patches, and sometimes even multiple versions of patches.  Figuring out what patches you need and what versions is also painful and error prone.

Instead, this patcher updates the entire Magento installation to a fully patched state automatically.  It works 100% of the time, because instead of applying individual patches and building up patched files, it patches your Magento installation to final state of having all patches applied. The complete patch also adds in form keys into custom templates that would not be included in the standard patch libraries.

Works for Magento 1 Community Versions 1.5.0.1 - Current

###Disclaimer
This script applies all applicable patches for your Magento version. It will overwite any previously patched files.  It will also overwrite any modifications made to core files within the scope of core files being patched.

###Usage
Executing a dryrun will list the files to be overwritten / modified:

`sh magesecuritypatcher.sh <dryrun>`

Execute the patcher:

`sh magesecuritypatcher.sh`

*A backup of overwritten / modified files will be created as:
`patch-backup-<timestamp>.tar.gz`*

###Feedback
Please contact us at the [Mage Security Council](https://magesec.org/contact)
