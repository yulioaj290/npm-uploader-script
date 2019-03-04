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
  
Parts of the Script command execution
---------------------------------------
  
```bash
$ bash NPM_UPLOADER.sh video.mp4 video-clip 30 9
```
  
  * __NPM_UPLOADER.sh__: Name of the script file. __Required__.
  * __video.mp4__: Name of the file to upload to npmjs.com as package(s). __Required__.
  * __video-clip__:  Name _prefix_ of the packages to upload. __Required__.
  * __30__: Upper limit of the size of the packages to upload. It must be expressed in MegaBytes (MB). __Required__.
  * __9__: Level of compression of the packages to upload. It must be between 1 _(min compression)_ and 9 _(max compression)_.