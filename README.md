[![MageMojo](https://magetalk.com/wp-content/uploads/2017/11/q7xJZaM5TImMN7mUIb0c.png)](https://magemojo.com/)

# MageMojo Magento 1 Security Patcher

### Updates

06/25/20 - Updated to include patch SUPEE-11346

05/14/20 - Updated to include patch SUPEE-11314

02/07/20 - Updated to include patch SUPEE-11295

10/11/19 - Updated to include patch SUPEE-11219

06/26/19 - Updated to include patch SUPEE-11155

03/28/19 - Updated to include patch SUPEE-11086

03/19/19 - Updated to include Authorize.net MD5 Patch and Admin Dashboard Charts Patch

11/29/18 - Updated to include patch SUPEE-10975 and PHP 7 compatibility updates

10/17/18 - Updated for Magento 2 versions 2.1.15 / 2.2.6

9/19/18 - Updated to include patch SUPEE-10888

6/28/18 - Updated to include patch SUPEE-10752

2/27/18 - Updated for SUPEE-10570 and Magento 2 Versions 2.0.18 / 2.1.12 / 2.2.3

12/19/17 - Support for Magento 2 Community Released

11/28/17 - Updated to include patch SUPEE-10415

9/15/17 - Updated to include patch SUPEE-10266

9/12/17 - Updated to include patch SUPEE-10336

7/13/17 - Updated to include v2 of patch SUPEE-9767

6/13/17 - Updated to include patches SUPEE-8167 and SUPEE-8967

6/1/17 - Updated to include patch SUPEE-9767

2/7/17 - Updated to include patch SUPEE-9652

### About
MageMojo Magento 1 Security Patcher is a more effective alternative to the standard magento patches. Patching Magento is prone to failure because you are applying patches over patches, and sometimes even multiple versions of patches.  Figuring out what patches you need and what versions is also painful and error prone.

Instead, this patcher updates the entire Magento installation to a fully patched state - automatically.  It works 100% of the time as long as it can determine the version and has a patchable archive for it, because instead of applying individual patches and building up patched files, *it patches your Magento installation directly to the final state of having all patches applied*. It also adds in form keys to custom templates that would not be included in the standard patch libraries.

Works for Magento 1 Community Versions 1.5.0.1 - Current

### Disclaimer
This script applies all applicable patches for your Magento version. It will overwite any previously patched files.  It will also overwrite any modifications made to core files within the scope of core files being patched.

### Usage

Make the script executable, running as `sh magesecuritypatcher.sh` can throw errors under some sh shells.

```
chmod a+x magesecuritypatcher.sh
```

Executing a dryrun will list the files to be overwritten / modified:

`./magesecuritypatcher.sh [-h] [-q] [-d]`
  -h  Show this help message
  -q  Quiet - don't show disclaimer and except all prompts
  -d  Dryrun - Run peliminary checks for version an backup creation but do not upgrade

Execute the patcher:

```
./magesecuritypatcher.sh
```

*A backup of overwritten / modified files will be created as:
`patch-backup-<timestamp>.tar.gz`*

### Magento 1 Patching Methodology

Magento 1 is patched through incremental updates to versions called SUPEE files. These files update the core Magento files to patch various security vulnerabilities and fix functionality. Due to their nature if the file they are updating does not precisely match what it is expecting due to some change in the file it is trying to update the install will fail. Due to the high likelihood of this occurring our patch system works by overwriting the core files with ones that are fully patched. Some patches also add form keys to templates which will not apply to templates outside of the default path. Our patching system will also attempt to add these necessary form keys to customized templates giving the patch a better chance of a successful install. However, sites should still be fully tested after any patching is done. A backup file will be created before the patching process begins in the website root.

### Feedback
Please contact us at [MageMojo](https://magemojo.com/contact.php)
