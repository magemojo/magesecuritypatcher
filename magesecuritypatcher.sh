#!/bin/bash

getopts q QUIET
getopts d DRYRUN
getopts h HELP

if [ $HELP = "h" ]
then
  echo "Usage: magesecuritypatcher.sh [-h] [-q] [-d]"
  echo "  -h  Show this help message"
  echo "  -q  Quiet - don't show disclaimer and except all prompts"
  echo "  -d  Dryrun - Run peliminary checks for version an backup creation but do not upgrade"
  exit 0
fi

function formkey {
  FILELIST=""
  FILENAME=$1
  SEARCH=`echo "${2//\'/''}"`
  DRY=$3
  for FILE in $(find app/design/frontend/ -name $FILENAME); do
    if [[ $FILE != "app/design/frontend/base"* ]]
    then
      STRINGSEARCH=`grep -n "$SEARCH" $FILE | cut -d : -f1 | tr "\n" " " | tr -d "\r"`
      if [ ! -z "$STRINGSEARCH" ]
      then
        #check if formkey already exists
        FORMKEY=`grep -n '<?php echo $this->getBlockHtml('"'"'formkey'"'"'); ?>' $FILE | cut -d : -f1 | tr "\n" " " | tr -d "\r"`
        if [ ! -z $FORMKEY ]
        then
          if [ $DRY == "N" ]
          then
            ADD=1
            for LINENUM in $SEARCHSTRING
            do
              #echo $LINENUM
              LINENUM=$((LINENUM+$ADD))
              INSERT=$LINENUM"i<?php echo $this->getBlockHtml(\'formkey\'); ?>"
              sed -i "$INSERT" $FILE
              ADD=$(($ADD+1))
            done
          fi
          FILELIST="$FILELIST $FILE"
        fi
      fi
    fi
  done
  echo $FILELIST
}

if [ $QUIET != "q" ]
then
  echo "----------------------------DISCLAIMER-------------------------------"
  echo "This script applies all applicable patches for Magento.              "
  echo "It will overwite any files that patches have been historically       "
  echo "applied to. Any modifications that were made to core files that      "
  echo "patches have been applied to will be overwritten as a result.        "
  echo "                                                                     "
  echo "Usage: sh magesecuritypatcher.sh [-h] [-q] [-d]                      "
  echo "Executing a dryrun will list the files to be overwritten / modified. "
  echo "                                                                     "
  echo "A backup of overwritten / modified files will be created as          "
  echo "patch-backup-<timestamp>.tar.gz                                      "
  echo "---------------------------------------------------------------------"
fi

echo 'Detecting Magento Version'
if [ -f app/etc/local.xml ];
then
  MAGENTOBRANCH=1
  VERSION=`php -r "require \"./app/Mage.php\"; echo Mage::getVersion(); "`
  if [[ "$VERSION" = "1.5."* ]] || [[ "$VERSION" = "1.6."* ]]
  then
    EDITION="community"
  else
    EDITION=`php -r "require \"./app/Mage.php\"; echo Mage::getEdition(); "`  
  fi
fi
if [ -f app/etc/env.php ];
then
  MAGENTOBRANCH=2
  AUTHFILE=`cat $HOME/.composer/auth.json | jq -r '.["http-basic"] | .["repo.magento.com"]'`
  if [ "$AUTHFILE" = 'null' ] || [ "$AUTHFILE" = "" ]
  then
    echo 'It does not appear your install was installed via composer, in order to upgrade you will need to follow the instructions here to create an access key to the Magento update repo. http://devdocs.magento.com/guides/v2.0/install-gde/prereq/connect-auth.html'
    exit 1
  fi
  FULLEDITION=`cat composer.json | jq -r '.name'`
  FULLEDITION=${FULLEDITION/project/product}
  if [ "$FULLEDITION" = "magento/product-community-edition" ]
  then
    EDITION="community"
  else
    EDITION="enterprise"
  fi
  VERSION=`cat composer.json | jq -r '.["require"] | .["magento/product-community-edition"]'`
fi
if [ -z $VERSION ] || [ -z $EDITION ]
then
  echo "Failed to determine Magento Version exiting"
  exit
fi
echo "Version $EDITION $VERSION"
EDITION=`echo "$EDITION" | awk '{print tolower($0)}'`

if [ $QUIET != "q" ]
then
  if [ $DRYRUN != "d" ]
  then
    while true; do
        read -p "Patch this install? (y/n)" yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
  fi
fi

if [ $EDITION = "enterprise" ]
then
  echo "Enterprise patching is currently not supported exiting..."
  exit
fi

if [ -z $MAGENTOBRANCH ]
then
  echo "Magento version could not be determined"
  exit
fi

if [ $MAGENTOBRANCH -eq 1 ]
then
  echo "Requesting patch file..."
  if [ -e $EDITION-$VERSION-patch.tar.gz ]
  then
    rm -rf $EDITION-$VERSION-patch.tar.gz
  fi
  wget --quiet -O $EDITION-$VERSION-patch.tar.gz https://github.com/magesec/patchrepo/blob/master/$EDITION-$VERSION-patch.tar.gz?raw=true
  if [ ! -e $EDITION-$VERSION-patch.tar.gz ]
  then
    echo "Failed to download patch file, version may not be available"
    exit
  fi
  echo "Creating manifest of patched core files"
  PATCHLIST=`tar -tzf $EDITION-$VERSION-patch.tar.gz`
  echo "Creating manifest of template files that were ommited by standard patches"

  #view.phtml
  SEARCH='$this->getSubmitUrl($_product)'
  RESULTS=`formkey view.phtml "$SEARCH" Y`
  TEMPLATELIST="$TEMPLATELIST $RESULTS"

  #cart.phtml
  SEARCH='$this->getUrl('"'"'checkout/cart/updatePost'"'"')'
  RESULTS=`formkey cart.phtml "$SEARCH" Y`
  TEMPLATELIST="$TEMPLATELIST $RESULTS"

  #login.phtml
  SEARCH='$this->getPostActionUrl()'
  RESULTS=`formkey login.phtml "$SEARCH" Y`
  TEMPLATELIST="$TEMPLATELIST $RESULTS"

  #form.phtml
  SEARCH='<form action="<?php echo $this->getAction() ?>" method="post" id="review-form">'
  RESULTS=`formkey form.phtml "$SEARCH" Y`
  TEMPLATELIST="$TEMPLATELIST $RESULTS"

  #sidebar.phtml
  SEARCH='<form method="post" action="<?php echo $this->getFormActionUrl() ?>" id="reorder-validate-detail">'
  RESULTS=`formkey sidebar.phtml "$SEARCH" Y`
  TEMPLATELIST="$TEMPLATELIST $RESULTS"

  #register.phtml
  SEARCH='$this->getPostActionUrl()'
  RESULTS=`formkey register.phtml "$SEARCH" Y`
  TEMPLATELIST="$TEMPLATELIST $RESULTS"

  #shipping.phtml
  SEARCH='$this->__('"'"'Update Total'"'"')'
  RESULTS=`formkey shipping.phtml "$SEARCH" Y`
  TEMPLATELIST="$TEMPLATELIST $RESULTS"

  #shipping.phtml
  SEARCH='<?php echo $this->__('"'"'Continue to Review Your Order'"'"') ?>'
  RESULTS=`formkey shipping.phtml "$SEARCH" Y`
  TEMPLATELIST="$TEMPLATELIST $RESULTS"

  #billing.phtml
  SEARCH='images/opc-ajax-loader.gif'
  RESULTS=`formkey billing.phtml "$SEARCH" Y`
  TEMPLATELIST="$TEMPLATELIST $RESULTS"

  #payment.phtml
  SEARCH='images/opc-ajax-loader.gif'
  RESULTS=`formkey payment.phtml "$SEARCH" Y`
  TEMPLATELIST="$TEMPLATELIST $RESULTS"

  #shipping.phtml
  SEARCH='images/opc-ajax-loader.gif'
  RESULTS=`formkey shipping.phtml "$SEARCH" Y`
  TEMPLATELIST="$TEMPLATELIST $RESULTS"

  #shipping_method.phtml
  SEARCH='images/opc-ajax-loader.gif'
  RESULTS=`formkey shipping_method.phtml "$SEARCH" Y`
  TEMPLATELIST="$TEMPLATELIST $RESULTS"


  DELETELIST="./skin/adminhtml/default/default/media/flex.swf ./skin/adminhtml/default/default/media/uploader.swf ./skin/adminhtml/default/default/media/uploaderSingle.swf ./skin/adminhtml/default/default/media/editor.swf"

  BACKUPLIST="$PATCHLIST $TEMPLATELIST $DELETELIST"

  if [ $DRYRUN != "d" ]
  then
    NOW=$(date +"%s")
    BACKUPNAME="patch-backup-$NOW.tar.gz"
    echo "Creating backup tar...."
    tar -zcf $BACKUPNAME $BACKUPLIST > /dev/null 2>&1
    echo "$BACKUPNAME created"
  fi

  if [ $DRYRUN = "d" ]
  then
    echo "Dryrun files that would be modified...."
    for FILE in $BACKUPLIST ; do
      echo $FILE
    done
  else
    echo "Renaming applied.patches.list"
    LISTNAME="./app/etc/applied.patches.list.$NOW"
    mv ./app/etc/applied.patches.list $LISTNAME
    echo "Patching files...."
    echo "Updating core...."
    tar -zxf $EDITION-$VERSION-patch.tar.gz
    echo "Core updated"

    echo "Updating custom template form keys..."
    #view.phtml
    SEARCH='$this->getSubmitUrl($_product)'
    RESULTS=`formkey view.phtml "$SEARCH" N`
    TEMPLATELIST="$TEMPLATELIST $RESULTS"

    #cart.phtml
    SEARCH='$this->getUrl('"'"'checkout/cart/updatePost'"'"')'
    RESULTS=`formkey cart.phtml "$SEARCH" N`
    TEMPLATELIST="$TEMPLATELIST $RESULTS"

    #login.phtml
    SEARCH='$this->getPostActionUrl()'
    RESULTS=`formkey login.phtml "$SEARCH" N`
    TEMPLATELIST="$TEMPLATELIST $RESULTS"

    #form.phtml
    SEARCH='<form action="<?php echo $this->getAction() ?>" method="post" id="review-form">'
    RESULTS=`formkey form.phtml "$SEARCH" N`
    TEMPLATELIST="$TEMPLATELIST $RESULTS"

    #sidebar.phtml
    SEARCH='<form method="post" action="<?php echo $this->getFormActionUrl() ?>" id="reorder-validate-detail">'
    RESULTS=`formkey sidebar.phtml "$SEARCH" N`
    TEMPLATELIST="$TEMPLATELIST $RESULTS"

    #register.phtml
    SEARCH='$this->getPostActionUrl()'
    RESULTS=`formkey register.phtml "$SEARCH" N`
    TEMPLATELIST="$TEMPLATELIST $RESULTS"

    #shipping.phtml
    SEARCH='$this->__('"'"'Update Total'"'"')'
    RESULTS=`formkey shipping.phtml "$SEARCH" N`
    TEMPLATELIST="$TEMPLATELIST $RESULTS"

    #shipping.phtml
    SEARCH='<?php echo $this->__('"'"'Continue to Review Your Order'"'"') ?>'
    RESULTS=`formkey shipping.phtml "$SEARCH" N`
    TEMPLATELIST="$TEMPLATELIST $RESULTS"

    #billing.phtml
    SEARCH='images/opc-ajax-loader.gif'
    RESULTS=`formkey billing.phtml "$SEARCH" N`
    TEMPLATELIST="$TEMPLATELIST $RESULTS"

    #payment.phtml
    SEARCH='<?php echo $this->getChildHtml('"'"'methods'"'"') ?>'
    RESULTS=`formkey payment.phtml "$SEARCH" N`
    TEMPLATELIST="$TEMPLATELIST $RESULTS"

    #shipping.phtml
    SEARCH='images/opc-ajax-loader.gif'
    RESULTS=`formkey shipping.phtml "$SEARCH" N`
    TEMPLATELIST="$TEMPLATELIST $RESULTS"

    #shipping_method.phtml
    SEARCH='images/opc-ajax-loader.gif'
    RESULTS=`formkey shipping_method.phtml "$SEARCH" N`
    TEMPLATELIST="$TEMPLATELIST $RESULTS"

    echo "Templates updated"

    echo "Removing vulnerable files...."
    for FILE in $DELETELIST ; do
      rm -rf $FILE
    done
    echo "Vulnerable files removed"

    echo "PATCHING COMPLETE!"
    echo "REMEMBER TO CLEAR YOUR CACHES!"
  fi
else
  #Check for the php70 executable
  OUT=`which php70`
  if [[ $OUT = *"no php70"* ]]
  then
    PHP='php'
  else
    PHP='php70'
  fi
  #IFS=. read MAJOR MINOR BUILD <<EOF
  #$VERSION
  #EOF
  MAJOR=`echo "$VERSION" | awk -F'.' '{print $1}'`
  MINOR=`echo "$VERSION" | awk -F'.' '{print $2}'`
  BRANCH="$MAJOR.$MINOR"
  echo "Getting Backup Manifests for $BRANCH Branch"
  VERSIONING=$(curl -s -L https://github.com/magesec/patchrepo/blob/master/manifests/versioning.conf?raw=true)
  LINE=`echo "$VERSIONING" | grep "$BRANCH "`
  LATEST=`echo $LINE | awk '{print $2;}'`
  FILESBACKUP=$(curl -s -L https://github.com/magesec/patchrepo/blob/master/manifests/$EDITION/$VERSION.backup.manifest?raw=true)
  DBBACKUP=$(curl -s -L https://github.com/magesec/patchrepo/blob/master/manifests/$EDITION/$VERSION.dbbackup.manifest?raw=true)
  DBHOST=`php -r '$return =  include "./app/etc/env.php"; print $return["db"]["connection"]["default"]["host"];'`
  DBNAME=`php -r '$return =  include "./app/etc/env.php"; print $return["db"]["connection"]["default"]["dbname"];'`
  DBUSER=`php -r '$return =  include "./app/etc/env.php"; print $return["db"]["connection"]["default"]["username"];'`
  DBPASS=`php -r '$return =  include "./app/etc/env.php"; print $return["db"]["connection"]["default"]["password"];'`
  DBPREFIX=`php -r '$return =  include "./app/etc/env.php"; print $return["db"]["table_prefix"];'`
  DBBACKUP=`echo $DBBACKUP | tr '\n' ' '`
  CORE="core_config_data"
  BASEURL=`mysql -sN -u $DBUSER -p$DBPASS -h $DBHOST $DBNAME -e "select value from $DBPREFIX$CORE where scope = 'default' and scope_id = 0 and path = 'web/unsecure/base_url'"`
  BASELINECHECK=`curl -s -L $BASEURL`
  if [ ! -z "$DBPREFIX" ]
  then
    DBBACKUP=$(sed 's/^/$DBPREFIX/' <<< $DBBACKUP)
  fi
  if [ -z "$LATEST" ]
  then
    echo "Could not find latest version for branch $BRANCH exiting..."
    exit 1
  fi
  if [ -z "$FILESBACKUP" ] || [ "$FILESBACKUP" = "Not Found" ]
  then
    echo "Could not retrieve changed files list to backup exiting..."
    exit 1
  fi
  if [ -z "$DBHOST" ]
  then
    echo "Could not retrieve database host exiting..."
    exit 1
  fi
  if [ -z "$DBNAME" ]
  then
    echo "Could not retrieve database name exiting..."
    exit 1
  fi
  if [ -z "$DBUSER" ]
  then
    echo "Could not retrieve database user exiting..."
    exit 1
  fi
  if [ -z "$DBPASS" ]
  then
    echo "Could not retrieve database password exiting..."
    exit 1
  fi
  NOW=$(date +"%s")
  if [ $VERSION = $LATEST ]
  then
    echo "Magento $VERSION is already the latest of the $BRANCH branch, exiting..."
    exit 1
  fi
  if [ $DRYRUN != "d" ]
  then
    echo "Generate prebackup filelist"
    find . | grep -v './var/' | grep -v './pub/media/' > preupgradefilelist-$NOW.txt
    SETUPTABLE="setup_module"
    echo 'Creating Database Backup'
    mysqldump -u $DBUSER -p$DBPASS -h $DBHOST $DBNAME --tables $DBPREFIX$SETUPTABLE $DBBACKUP | gzip > database-backup-$NOW.sql.gz
    echo 'Creating Files Backup'
    tar -czf patch-backup-$NOW.tar.gz $FILESBACKUP database-backup-$NOW.sql.gz preupgradefilelist-$NOW.txt
    rm database-backup-$NOW.sql.gz
    echo "Upgrading to $LATEST"
    $PHP bin/magento maintenance:enable
    ROLLBACK=0
    composer require $FULLEDITION $LATEST --no-update
    composer update
    if [ $? != 0 ]
    then
      ROLLBACK=1
      echo "Composer update failed"
    else
      rm -rf var/cache/*
      rm -rf var/page_cache/*
      rm -rf var/generation/*
      rm -rf var/di/*
      $PHP bin/magento setup:upgrade
      if [ $? != 0 ]
      then
        ROLLBACK=1
        echo "Magento setup upgrade step failed"
      else
        LOG=`$PHP bin/magento setup:di:compile`
        echo $LOG
        if [ $? != 0 ] || [[ $LOG = *"Errors during compilation"* ]]
        then
          ROLLBACK=1
          echo "Magento compiler step failed"
        else
          $PHP bin/magento cache:flush
          $PHP bin/magento maintenance:disable
          echo "Checking $BASEURL"
          SANITYCHECK=`curl -s -L $BASEURL`
          DIFF=`diff <(echo $BASELINECHECK) <(echo $SANITYCHECK)`
          DIFF=`echo "$DIFF" | tr '[:upper:]' '[:lower:]'`
          if [[ $DIFF = *"error"* ]] || [[ $DIFF = *"exception"* ]]
          then
            ROLLBACK=1
            echo "Sanity check failed, errors on homepage"
          fi
        fi
      fi
    fi
    if [ $ROLLBACK -eq 1 ]
    then
      echo "Starting Rollback..."
      $PHP bin/magento maintenance:enable
      find . | grep -v './var/' | grep -v './pub/media/' > postupgradefilelist-$NOW.txt
      tar -zxf patch-backup-$NOW.tar.gz
      if [[ ! -z "$DBBACKUP" ]]
      then
        zcat database-backup-$NOW.sql.gz | mysql -u $DBUSER -p$DBPASS -h $DBHOST $DBNAME
      fi
      DELETELIST=`grep -Fxv -f postupgradefilelist-$NOW.txt preupgradefilelist-$NOW.txt | grep -v $NOW`
      rm -rf $DELETELIST
      rm -rf var/cache/*
      rm -rf var/page_cache/*
      rm -rf var/generation/*
      rm -rf var/di/*
      $PHP bin/magento setup:upgrade
      $PHP bin/magento setup:di:compile
      $PHP bin/magento cache:flush
      $PHP bin/magento maintenance:disable
      echo "Rollback Complete"
    fi
  fi
fi
