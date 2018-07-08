NPM Uploader
===============================
Script Bash for uploading NPM pachages to npmjs.com. 

__You must pass 3 required arguments:__ _name_ of the file/directory to include on the packages, _prefix_ name of the packages, and _number_ of chunks/packages to upload.

This script is capable to upload all packages to __npmjs.com__ secuencially and to remove the same packages if it is executed again immediately, following the information on the __"remove.lock"__ file create previously.

Requirements
------------

  * NodeJS 8.4.0 or higher.
  * NPM 5.3.0 or higher.
  * P7zip-full 16.02 or higher.

To prepare the environment for the script follow this steps (based on Ubuntu 14.04):

  0. (Optional) Update your linux repositories and upgrade all packages.
  ```bash
  $ sudo apt-get update
  $ sudo apt-get upgrade
  ```

  1. Install p7zip-full on your system, it is neccesary to compress and divide in chunks all the file/directory included.
  ```bash
  $ sudo apt-get install p7zip-full
  ```

  2. Install NodeJS.
  ```bash
  $ sudo apt-get install nodejs
  ```

  3. Execute the script.

  ```bash
  $ bash NPM_UPLOADER.sh video.mp4 video-clip 30
  ```