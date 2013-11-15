#!/bin/bash

ARCHIVE_DIR=/media/archive
GLACIER_STOP=.glacier-stop
GLACIER_LOCK=.glacier-lock
GLACIER_LOGS=.glacier-logs
GLACIER_VAULTS=.glacier-vaults
GLACIER_ARCHIVES=.glacier-archives
GLACIER_IGNORE=.glacier-ignore
GLACIER_MAX_SIZE=52428800 #50MB

# move to archive folder

cd $ARCHIVE_DIR

# stop processing script if it's already running

if [ -f $GLACIER_LOCK ] ; then
    echo "The script is already running, exiting"
    echo "If you're sure the script is not running, try to delete '$GLACIER_LOCK' file"
    exit 0
fi

# create lock file

touch $GLACIER_LOCK

# create files for bookkeeping

if ! [ -f $GLACIER_LOGS ] ; then
    touch $GLACIER_LOGS
fi

if ! [ -f $GLACIER_VAULTS ] ; then
    touch $GLACIER_VAULTS
fi

if ! [ -f $GLACIER_ARCHIVES ] ; then
    touch $GLACIER_ARCHIVES
fi

if ! [ -f $GLACIER_IGNORE ] ; then
    touch $GLACIER_IGNORE
    echo ".DS_Store" >> $GLACIER_IGNORE
    echo "._.DS_Store" >> $GLACIER_IGNORE
fi

# find all files, including in folders

find . -type f | sort | while read FILE ; do

    # stop processing script if glacier stop file found

    if [ -f $GLACIER_STOP ] ; then
        echo "$GLACIER_STOP file found, exiting"
        exit 0
    fi

    # extract vault name and archive name

    VAULT=$(dirname "$FILE")
    VAULT=${VAULT:2} # cut off first 2 chars
    VAULT=${VAULT////-} # replace all slashes with hyphens
    VAULT=${VAULT//_/-} # replace all underscores with hyphens
    VAULT=${VAULT// /-} # replace all spaces with hyphens
    VAULT=${VAULT,,} # to lowercase
    ARCHIVE=$(basename "$FILE")

    # check the size, zip up and split if too big (only if not uploaded yet)

    FILESIZE=$(du -b "$FILE" | cut -f 1)

    if [ $FILESIZE -gt $GLACIER_MAX_SIZE ] && ! grep -Fxq "$VAULT/$ARCHIVE" $GLACIER_ARCHIVES ; then
        echo "Splitting file"
        7z a -v"$GLACIER_MAX_SIZE"b "$FILE".zip "$FILE" && rm "$FILE"
    fi

done

# find all files, including in folders

find . -type f | sort | while read FILE ; do

    # stop processing script if glacier stop file found

    if [ -f $GLACIER_STOP ] ; then
        echo "$GLACIER_STOP file found, exiting"
        exit 0
    fi

    # extract vault name and archive name

    VAULT=$(dirname "$FILE")
    VAULT=${VAULT:2} # cut off first 2 chars
    VAULT=${VAULT////-} # replace all slashes with hyphens
    VAULT=${VAULT//_/-} # replace all underscores with hyphens
    VAULT=${VAULT// /-} # replace all spaces with hyphens
    VAULT=${VAULT,,} # to lowercase
    ARCHIVE=$(basename "$FILE")

    # check if file is not one of our bookkeeping files

    if [ "$ARCHIVE" != "$GLACIER_LOCK" ] && [ "$ARCHIVE" != "$GLACIER_LOGS" ] && [ "$ARCHIVE" != "$GLACIER_VAULTS" ] && [ "$ARCHIVE" != "$GLACIER_ARCHIVES" ] && [ "$ARCHIVE" != "$GLACIER_IGNORE" ]; then

        # check if file should be ignored

        if ! grep -Fxq "$ARCHIVE" $GLACIER_IGNORE ; then

            # create vault if doesn't exist yet, mark as created

            if ! grep -Fxq "$VAULT" $GLACIER_VAULTS ; then
                echo "Creating vault '$VAULT'"
                glacier-cmd mkvault "$VAULT" | tee -a $GLACIER_LOGS && echo "$VAULT" >> $GLACIER_VAULTS
                echo "Vault '$VAULT' created"
            fi

            # upload file if not uploaded yet, mark as uploaded

            if ! grep -Fxq "$VAULT/$ARCHIVE" $GLACIER_ARCHIVES ; then
                echo "Uploading [$VAULT] $ARCHIVE"
                glacier-cmd upload "$VAULT" "$FILE" --description "$ARCHIVE" | tee -a $GLACIER_LOGS && echo "$VAULT/$ARCHIVE" >> $GLACIER_ARCHIVES
                echo "Uploaded [$VAULT] $ARCHIVE"
            fi

        fi

    fi

done

# sort bookkeeping files

sort -o $GLACIER_VAULTS $GLACIER_VAULTS
sort -o $GLACIER_ARCHIVES $GLACIER_ARCHIVES

# remove lock file

rm $GLACIER_LOCK

echo "Script finished"
