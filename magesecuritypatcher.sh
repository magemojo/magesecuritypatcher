#!/bin/bash

function formkey {
  FILELIST=""
  FILENAME=$1
  SEARCH=$2
  DRY=$3
  for FILE in $(find app/design/frontend/ -name $FILENAME); do
    if [[ $FILE != "app/design/frontend/base"* ]]
    then
      STRINGSEARCH=`grep -n $SEARCH $FILE | cut -d : -f1 | tr "\n" " " | tr -d "\r"`
      if [ ! -z $STRINGSEARCH ]
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

echo "----------------------------DISCLAIMER-------------------------------"
echo "This script applies all applicable patches for Magento.              "
echo "It will overwite any files that patches have been historically       "
echo "applied to. Any modifications that were made to core files that      "
echo "patches have been applied to will be overwritten as a result.        "
echo "                                                                     "
echo "Usage: sh magesecuritypatcher.sh <dryrun>                        "
echo "Executing a dryrun will list the files to be overwritten / modified. "
echo "                                                                     "
echo "A backup of overwritten / modified files will be created as          "
echo "patch-backup-<timestamp>.tar.gz                                      "
echo "---------------------------------------------------------------------"

if [ ! -z "$1" ]
then
  if [ $1 == "dryrun" ]
  then
    DRYRUN=1
  else
    DRYRUN=0
  fi
else
  DRYRUN=0
fi

echo 'Detecting Magento Version'
VERSION=`php -r "require \"./app/Mage.php\"; echo Mage::getVersion(); "`
EDITION=`php -r "require \"./app/Mage.php\"; echo Mage::getEdition(); "`
if [ -z $VERSION ] || [ -z $EDITION ]
then
  echo "Failed to determine Magento Version exiting"
  exit
fi
echo "Version $EDITION $VERSION"
EDITION=`echo "$EDITION" | awk '{print tolower($0)}'`

while true; do
    read -p "Patch this install?" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

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
RESULTS=`formkey view.phtml $SEARCH Y`
TEMPLATELIST="$TEMPLATELIST $RESULTS"

#cart.phtml
SEARCH='$this->getUrl('"'"'checkout/cart/updatePost'"'"')'
RESULTS=`formkey cart.phtml $SEARCH Y`
TEMPLATELIST="$TEMPLATELIST $RESULTS"

#login.phtml
SEARCH='$this->getPostActionUrl()'
RESULTS=`formkey login.phtml $SEARCH Y`
TEMPLATELIST="$TEMPLATELIST $RESULTS"

#form.phtml
SEARCH='<form action="<?php echo $this->getAction() ?>" method="post" id="review-form">'
RESULTS=`formkey form.phtml $SEARCH Y`
TEMPLATELIST="$TEMPLATELIST $RESULTS"

#sidebar.phtml
SEARCH='<form method="post" action="<?php echo $this->getFormActionUrl() ?>" id="reorder-validate-detail">'
RESULTS=`formkey sidebar.phtml $SEARCH Y`
TEMPLATELIST="$TEMPLATELIST $RESULTS"

#register.phtml
SEARCH='$this->getPostActionUrl()'
RESULTS=`formkey register.phtml $SEARCH Y`
TEMPLATELIST="$TEMPLATELIST $RESULTS"

DELETELIST="./skin/adminhtml/default/default/media/flex.swf ./skin/adminhtml/default/default/media/uploader.swf ./skin/adminhtml/default/default/media/uploaderSingle.swf ./skin/adminhtml/default/default/media/editor.swf"

BACKUPLIST="$PATCHLIST $TEMPLATELIST $DELETELIST"

NOW=$(date +"%s")
BACKUPNAME="patch-backup-$NOW.tar.gz"
echo "Creating backup tar...."
tar -zcf $BACKUPNAME $BACKUPLIST > /dev/null 2>&1
echo "$BACKUPNAME created"

if [ $DRYRUN -eq 1 ]
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
  RESULTS=`formkey view.phtml $SEARCH Y`
  TEMPLATELIST="$TEMPLATELIST $RESULTS"

  #cart.phtml
  SEARCH='$this->getUrl('"'"'checkout/cart/updatePost'"'"')'
  RESULTS=`formkey cart.phtml $SEARCH Y`
  TEMPLATELIST="$TEMPLATELIST $RESULTS"

  #login.phtml
  SEARCH='$this->getPostActionUrl()'
  RESULTS=`formkey login.phtml $SEARCH Y`
  TEMPLATELIST="$TEMPLATELIST $RESULTS"

  #form.phtml
  SEARCH='<form action="<?php echo $this->getAction() ?>" method="post" id="review-form">'
  RESULTS=`formkey form.phtml $SEARCH Y`
  TEMPLATELIST="$TEMPLATELIST $RESULTS"

  #sidebar.phtml
  SEARCH='<form method="post" action="<?php echo $this->getFormActionUrl() ?>" id="reorder-validate-detail">'
  RESULTS=`formkey sidebar.phtml $SEARCH Y`
  TEMPLATELIST="$TEMPLATELIST $RESULTS"

  #register.phtml
  SEARCH='$this->getPostActionUrl()'
  RESULTS=`formkey register.phtml $SEARCH Y`
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
