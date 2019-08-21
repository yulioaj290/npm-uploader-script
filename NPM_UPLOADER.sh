#!/bin/bash

# ================================================
# FUNCTIONS
# ================================================

# Check if 7Zip is installed
check_7zip_func(){
    # Must return "/usr/bin/7z"
    ZIP7_INSTALLED="$(echo `whereis 7z` | awk -F "7z: " '{print $2}' | awk '{print $1}')"
    if [[ -z $ZIP7_INSTALLED ]]; then
        echo "false"
    else
        echo "true"
    fi
}

# Check if NPM is installed and loged in
check_npm_func(){
    # Must return "/usr/bin/npm"
    NPM_INSTALLED="$(echo `whereis npm` | awk -F "npm: " '{print $2}' | awk '{print $1}')"
    if [[ -z $NPM_INSTALLED ]]; then
        echo "installed"
    else
        # NPM_LOGED_IN="$(echo `npm whoami` | awk '{print $2}')"
        # if [[ $NPM_LOGED_IN == "ERR!" ]]; then
        #     echo "logedin"
        # else
            echo "true"
        # fi
    fi
}


# ================================================
# MAIN PROCESS
# ================================================

# STEP 1: Verify requirements
#   * 7zip-full package installed
#   * NPM installed and loged in

if [[ $(check_7zip_func) == "false" ]]; then
    echo "[ ERROR ]: You must to install 7zip or 7zip-full package first."
elif [[ $(check_npm_func) == "installed" ]]; then
    echo "[ ERROR ]: You must to install NPM package first."
# elif [[ $(check_npm_func) == "logedin" ]]; then
    # echo "[ ERROR ]: You must loged into the online NPM Registry."
elif [[ ! -e "remove.lock" ]]; then

    # ================================================
    # STEP 2: Initialize variables
    # ================================================
    ARG_URL="false"     #   * url   : Download resource from URL
    ARG_LINK="false"    #   * link  : Make all chunk npm packages as dependencies of the 1st chunk package
    ARG_RM="false"      #   * rm    : Remove original resources
    ARG_PUSH="false"    #   * push  : Publish to NPM Registry automatically
    ARG_CRON="false"    #   * cron  : Set crontab task to automatically unpublish npm packages
    ARG_UNZIP="false"   #   * unzip : Provide to the NPM pachages auto unzip functions
    #   ==============================================
    ARG_FILE=""         #   * file  : Resource name or URL
    ARG_PREFIX=""       #   * prefix: Prefix to use in npm packages
    ARG_WEIGHT=""       #   * weight: Chunks weight
    ARG_ZIPLV=""        #   * ziplv : Compression level


    # Init "package.json" file vars
    # ================================================
    NPM_FILE_NAME=''                                    # Name  : Name of the package
    NPM_FILE_DEPS=''                                    # Deps  : Dependencies of the first package
    NPM_FILE_UNZIP='"postinstall": "bash unzip.sh"'     # UnZip : Script for postinstall automatically unzip


    # ================================================
    # STEP 3: Check optional arguments
    # ================================================

    ARGS=(`echo "$*"`)

    declare -i NUM_OPT_ARGS=0

    for ARG in ${ARGS[*]}
    do
        case $ARG in
            *-url*) 
                NUM_OPT_ARGS=$NUM_OPT_ARGS+1
                ARG_URL="true";;
            *-link*) 
                NUM_OPT_ARGS=$NUM_OPT_ARGS+1
                ARG_LINK="true";;
            *-rm*) 
                NUM_OPT_ARGS=$NUM_OPT_ARGS+1
                ARG_RM="true";;
            *-push*) 
                NUM_OPT_ARGS=$NUM_OPT_ARGS+1
                ARG_PUSH="true";;
            *-cron*) 
                NUM_OPT_ARGS=$NUM_OPT_ARGS+1
                ARG_CRON="true";;
            *-unzip*) 
                NUM_OPT_ARGS=$NUM_OPT_ARGS+1
                ARG_UNZIP="true";;
        esac
    done

    shift $NUM_OPT_ARGS

    # ================================================
    # STEP 4: Set and Validate required arguments
    # ================================================

    ARG_FILE=$1
    ARG_PREFIX=$2
    ARG_WEIGHT=$3
    ARG_ZIPLV=$4

    if [[ $ARG_FILE = '' ]]; then
        echo "[ ERROR ]: You must to provide the \"NAME\" of the file or directory."
        exit 128
    else
        if [[ ! -e "$ARG_FILE" && "$ARG_URL" == "false" ]]; then
            echo "[ ERROR ]: The file or directory \"$ARG_FILE\" does not exist."
            exit 128
        fi
    fi

    if [[ $ARG_PREFIX = '' ]]; then
        echo "[ ERROR ]: You must to provide the \"PREFIX\" of NPM Packages."
        exit 128
    fi

    if [[ $ARG_WEIGHT = '' ]]; then
        ARG_WEIGHT=50
    fi

    if [[ $ARG_ZIPLV = '' ]]; then
        ARG_ZIPLV=5
    fi

    if [[ "$ARG_UNZIP" == "true" && "$ARG_LINK" == "false" ]]; then
        echo "[ ERROR ]: To provide Auto UnZip functions, you need to link dependencies with the \"-link\" option."
    fi


    # ================================================
    # STEP 5: Sumarize arguments values
    # ================================================

    echo "=================================================="
    echo "[ Resource Name ] ........... $ARG_FILE"
    echo "[ Resource Weight ] ......... $(echo `du -hs $ARG_FILE` | awk '{print $1}')""B"
    echo "[ Package Prefix ] .......... $ARG_PREFIX"
    echo "[ Weight of Chunks ] ........ $ARG_WEIGHT""MB"
    echo "[ Compression Level ] ....... $ARG_ZIPLV"
    echo "--------------------------------------------------"
    echo "[ Resource from URL ] ....... $ARG_URL"
    echo "[ Link Dependencies ] ....... $ARG_LINK"
    echo "[ Remove Resources ] ........ $ARG_RM"
    echo "[ Publish to NPM ] .......... $ARG_PUSH"
    echo "[ Unpublish with CRON ] ..... $ARG_CRON"
    echo "[ Auto UnZip Functions ] .... $ARG_UNZIP"
    echo "=================================================="


    # ================================================
    # STEP 6: Download resource from external URL
    # ================================================

    if [[ "$ARG_URL" == "true" ]]; then
        if [[ -e "$ARG_FILE" ]]; then
            echo "[ ERROR ]: The file or directory \"$ARG_FILE\" already exist."
            echo "=================================================="
            exit 128
        elif [[ -e "$ARG_PREFIX" ]]; then
            echo "[ ERROR ]: The file or directory \"$ARG_PREFIX\" already exist."
            echo "=================================================="
            exit 128
        else
            echo "[ INFO ]: Downloading \"$ARG_FILE\" from external URL..."
            echo "=================================================="
        
            wget -O "$ARG_PREFIX" --quiet "$ARG_FILE"

            ARG_FILE=$ARG_PREFIX
        fi
    fi


    # ================================================
    # STEP 7: Check number of chunks
    # ================================================

    FILE_WEIGHT="$(echo `du $ARG_FILE` | cut -d' ' -f1)"

    WEIGHT_IN_MB="$(( ($FILE_WEIGHT + (1024 - 1) ) / 1024 ))"

    CHUNKS_NUM="$(( ($WEIGHT_IN_MB + ( $ARG_WEIGHT - 1) ) / $ARG_WEIGHT ))"


    # ================================================
    # STEP 8: Compressing and splitting resource
    # ================================================

    echo "[ INFO ]: Splitting file [ $ARG_FILE ] into [ $CHUNKS_NUM ] chunks ..."

    7za a -t7z -m0=lzma -mx=$ARG_ZIPLV -ms=on -v"$ARG_WEIGHT"m $ARG_PREFIX.7z $ARG_FILE

    echo "=================================================="

    # ================================================
    # STEP 9: Removing original resource
    # ================================================

    if [[ "$ARG_RM" == "true" ]]; then
        echo "[ INFO ]: Removing original file [ $ARG_FILE ] ..."
        echo "=================================================="

        rm -rf $ARG_FILE
    fi


    # ================================================
    # STEP 10: Build package dependencies
    # ================================================

    FIRST_PKG_DEPS=''               # Store package names and versions in JSON format [less first]
    ZIP_PKG_LIST=''                 # Store zip package names separated by spaces
    UNZIP_SCRIPT="#!/bin/bash \n"   # Store all command of the UnZip script

    for (( i=1 ; i <= $CHUNKS_NUM ; i++ ))
    do

        if [[ $i -lt 10 ]]; then
            CHUNK_ITEM_NUM="00$i"
        elif [[ $i -ge 10 ]] && [[ $i -lt 100 ]]; then
            CHUNK_ITEM_NUM="0$i"
        else
            CHUNK_ITEM_NUM="$i"
        fi

        CHUNK_DIR_NAME="$ARG_PREFIX""_""$CHUNK_ITEM_NUM"

        # unzip script
        CURRENT_PKG="$ARG_PREFIX.7z.$CHUNK_ITEM_NUM"
        ZIP_PKG_LIST="$ZIP_PKG_LIST $CURRENT_PKG"

        if [[ $i -ne 1 ]]; then
            FIRST_PKG_DEPS="$FIRST_PKG_DEPS"'"'$CHUNK_DIR_NAME'": "1.0.0"'
            
            if [[ $i -ne $CHUNKS_NUM ]]; then
                FIRST_PKG_DEPS="$FIRST_PKG_DEPS"',
                '
            fi


            # unzip script
            UNZIP_SCRIPT="$UNZIP_SCRIPT""mv node_modules/$CHUNK_DIR_NAME/$CURRENT_PKG ../ \n"
        else
            # unzip script
            UNZIP_SCRIPT="$UNZIP_SCRIPT""mv $CURRENT_PKG ../ \n"
        fi
    done

    # unzip script
    UNZIP_SCRIPT="$UNZIP_SCRIPT""cd ../ \n"
    UNZIP_SCRIPT="$UNZIP_SCRIPT""7z x $ARG_PREFIX.7z.001 \n"
    UNZIP_SCRIPT="$UNZIP_SCRIPT""rm -rf $ZIP_PKG_LIST \n"
    UNZIP_SCRIPT="$UNZIP_SCRIPT""echo \"===================================\" \n"
    UNZIP_SCRIPT="$UNZIP_SCRIPT""echo \"Remember to unpublish all pachages from 'NPMJS.com'.\" \n"
    UNZIP_SCRIPT="$UNZIP_SCRIPT""echo \"Remember to delete the '${ARG_PREFIX}_001' package folder.\" \n"
    UNZIP_SCRIPT="$UNZIP_SCRIPT""echo \"===================================\" \n"

    # Setting "dependencies" of the first package to use in "package.json"
    NPM_FILE_DEPS=$FIRST_PKG_DEPS


    # ================================================
    # STEP 11: Build, Publish and Remove NPM chunk packages
    # ================================================

    for (( i=1 ; i <= $CHUNKS_NUM ; i++ ))
    do

        if [[ $i -lt 10 ]]; then
            CHUNK_ITEM_NUM="00$i"
        elif [[ $i -ge 10 ]] && [[ $i -lt 100 ]]; then
            CHUNK_ITEM_NUM="0$i"
        else
            CHUNK_ITEM_NUM="$i"
        fi

        # Building name of the package based on "prefix" and "chunk number"
        CHUNK_DIR_NAME="$ARG_PREFIX""_""$CHUNK_ITEM_NUM"

        # Setting "package name" to use in "package.json"
        NPM_FILE_NAME=$CHUNK_DIR_NAME

        echo "     [*]: Processing NPM chunk Package No. $i [ $CHUNK_DIR_NAME ]"

        mkdir $CHUNK_DIR_NAME

        mv $ARG_PREFIX.7z.$CHUNK_ITEM_NUM $CHUNK_DIR_NAME/
        
        cd $CHUNK_DIR_NAME


        if [[ $i -eq 1 ]]; then
            if [[ "$ARG_LINK" == "false" ]]; then
                NPM_FILE_DEPS=''
            fi

            # unzip script
            if [[ "$ARG_UNZIP" == "true" ]]; then
                echo -e $UNZIP_SCRIPT >> unzip.sh
            else
                NPM_FILE_UNZIP=''
            fi

        else
            NPM_FILE_DEPS=''
            NPM_FILE_UNZIP=''
        fi
        
        NPM_FILE='{
            "name": "'$NPM_FILE_NAME'",
            "version": "1.0.0",
            "description": "",
            "main": "index.js",
            "author": "",
            "license": "ISC",
            "dependencies": {
                '$NPM_FILE_DEPS'
            },
            "scripts": {
                '$NPM_FILE_UNZIP'
            }
        }'

        echo "$NPM_FILE" >> package.json

        echo "        :.. Created package ..."

        if [[ "$ARG_PUSH" == "true" ]]; then
            npm publish
            
            echo "        :.. Uploaded package to \"npmjs.com\" registry ..."
        fi

        cd ../

        echo $CHUNK_DIR_NAME >> remove.lock
        
        if [[ "$ARG_RM" == "true" ]]; then
            echo "        :.. Removed local package ..."

            rm -rf $CHUNK_DIR_NAME
        fi

        echo "--------------------------------------------------"
    done

    echo "[ INFO ]: Processed [ $CHUNKS_NUM ] NPM chunk packages"
    echo "=================================================="

    echo "success"

else

    echo "=================================================="
    echo "[ INFO ]: Preparing to unpublish NPM Packages"
    echo "=================================================="

    for PACKAGE in $(cat remove.lock);
    do
        npm unpublish --force $PACKAGE

        echo "     [*]: Unpublided Package: $PACKAGE"
    done

    rm -rf remove.lock

    echo "=================================================="

fi
