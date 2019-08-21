# NPM Uploader

Script Bash for uploading NPM pachages to npmjs.com.

__You must pass 2 required arguments:__ 

* __name__ of the file/directory (could be a public URL) to include on the packages and;
* __prefix__ name of the packages.

This script is capable to upload all packages to __npmjs.com__ secuencially and to remove the same packages if it is executed again immediately, following the information on the __"remove.lock"__ file created previously.

## Requirements

----------------

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
$ bash NPM_UPLOADER.sh -link -unzip video.mp4 video-clip 50 9
```
  
## Usage of the Script

------------------------

```bash
$ bash NPM_UPLOADER.sh -link -unzip -rm -push video.mp4 video-clip 50 9
```
  
```bash
$ bash NPM_UPLOADER.sh -url -link -unzip -rm http://mi.website.com/video.mp4 video-clip 50 9
```

### Required arguments

* __NPM_UPLOADER.sh__: Name of the script file. __Required__.
* __video.mp4__: Name of the file to upload to npmjs.com as package(s). __Required__.
* __video-clip__:  Name _prefix_ of the packages to upload. __Required__.
* __50__: Upper limit of the size of the packages to upload. It must be expressed in MegaBytes (MB). __Required__.
* __9__: Level of compression of the packages to upload. It must be between 1 _(min compression)_ and 9 _(max compression)_.

### Optional arguments

* __-url__: Indicate that the file must be downloaded from the given URL _(http://mi.website.com/video.mp4),_ and then build package.
* __-link__: Include packages from 2nd to n(th) as dependencies of the 1st.
* __-rm__: Remove all original files automatically.
* __-push__: Publish all packages to 'npmjs.com' automatically. It requires to be loged in NPM in current terminal.
* __-unzip__: Include a script into the 1st package to automatically UnZip the packages. Must be used with the '-link' option.