# Mage Security Patcher

### Updates

12/19/17 - Support for Magento 2 Community Released

11/28/17 - Updated to include patch SUPEE-10415

9/15/17 - Updated to include patch SUPEE-10266

9/12/17 - Updated to include patch SUPEE-10336

7/13/17 - Updated to include v2 of patch SUPEE-9767

6/13/17 - Updated to include patches SUPEE-8167 and SUPEE-8967

6/1/17 - Updated to include patch SUPEE-9767

2/7/17 - Updated to include patch SUPEE-9652

### About
Mage Security Patcher is a more effective alternative to the standard magento patches. Patching Magento is prone to failure because you are applying patches over patches, and sometimes even multiple versions of patches.  Figuring out what patches you need and what versions is also painful and error prone.

Instead, this patcher updates the entire Magento installation to a fully patched state - automatically.  It works 100% of the time, because instead of applying individual patches and building up patched files, *it patches your Magento installation directly to the final state of having all patches applied*. It also adds in form keys to custom templates that would not be included in the standard patch libraries.

Works for Magento 1 & 2 Community Versions 1.5.0.1 - Current

### Disclaimer
This script applies all applicable patches for your Magento version. It will overwite any previously patched files.  It will also overwrite any modifications made to core files within the scope of core files being patched.

### Usage
Executing a dryrun will list the files to be overwritten / modified:

`sh magesecuritypatcher.sh [-h] [-q] [-d]`
  -h  Show this help message
  -q  Quiet - don't show disclaimer and except all prompts
  -d  Dryrun - Run peliminary checks for version an backup creation but do not upgrade

Execute the patcher:

`sh magesecuritypatcher.sh`

*A backup of overwritten / modified files will be created as:
`patch-backup-<timestamp>.tar.gz`*

###Magento 1 Patching Methodology
Magento 1 is patched through incremental updates to versions called SUPEE files. These files update the core Magento files to patch various security vulnerabilities and fix functionality. Due to their nature if the file they are updating does not precisely match what it is expecting due to some change in the file it is trying to update the install will fail. Due to the high likelihood of this occurring our patch system works by overwriting the core files with ones that are fully patched. Some patches also add form keys to templates which will not apply to templates outside of the default path. Our patching system will also attempt to add these necessary form keys to customized templates giving the patch a better chance of a successful install. However, sites should still be fully tested after any patching is done. A backup file will be created before the patching process begins in the website root.

###Magento 2 Patching Methodology
Magento 2 is patched via upgrades to build versions of the software. These versions will contain both bug fixes and security updates. As these are technically version upgrades there can be issues and incompatibilities with other installed modules. The patching system will perform these upgrades to the build version to bring it to the latest minor version of magento 2, ie. 2.0.10 to 2.0.17. It will not upgrade from 2.0 to 2.1 as that is a larger upgrade of functionality. The system will create a backup of any files that will be changed by the upgrade as well as any database tables that may be effected. The system will then put the site into maintenance mode and run the composer update to perform the upgrade, then recompile, then reindex. On success it will take the site out of maintenance mode. If any of these steps fail it will automatically rollback the site from the backups and again take the site out of maintenance mode. You will receive notification of the results of the patch with any relevant error reports.

### Feedback
Please contact us at the [Mage Security Council](https://magesec.org/contact)
