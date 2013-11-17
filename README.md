## Glacier auto upload

The main purpose of this script is to automatically upload archives to Amazon Glacier from a selected folder on your machine. It works great on [Raspberry Pi](http://blog.self.li/post/63281257339)!

### What does it do

The script tries to chunk all files within archive directory into manageable 50MB parts and sends them to your Amazon Glacier account, creating vaults based on folder names and uploading files to these vaults. It keeps track of files already uploaded as well as created vaults. If file is kept in a subfolder, the vault name will reflect that:

    photos/holiday 2013/week-1.zip        => photos-holiday/week-1.zip
    photos/holiday 2013/week-2.zip        => photos-holiday/week-2.zip
    photos/dinner with friends/photos.zip => photos-dinner-with-friends/photos.zip

### Requirements

- Linux machine that can stay on for days (or even months, depends on your upload speed and amount of data)
- installed and configured [glacier-cmd](https://github.com/uskudnik/amazon-glacier-cmd-interface)
- installed 7zip
- Amazon AWS account

### Installation

1. Put the file in a convenient location, possibly in your home folder or in /usr/local/bin/
2. Make sure that the file is executable: `sudo chmod +x glacier-auto-upload.sh`
3. Point `ARCHIVE_DIR` variable to the directory containing your data
4. Add script to your crontab, executing as `bash glacier-auto-upload.sh`

### Known issues

- Can't upload files directly within the `ARCHIVE_DIR`, they have to be kept in a subfolder within that folder
- Failed uploads are not terminated automatically
