#!/bin/bash
#
# Copyright 2019 Yulio Aleman Jimenez (@yulioaj290)
# 
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions 
# are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in 
# the documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived 
# from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT 
# NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
# THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# NPM_UPLOADER.sh
# This script allows to upload automatically some resources to NPMJS.com as chunk packages.
# The resources could be stored locally or online. 
#
# ================================================
# PROMPT VARIABLES
# ================================================
RED=$'\e[0;31m'
GREEN=$'\e[0;32m'
BLUE=$'\e[0;34m'
NC=$'\e[0m'

# --------------------------------------------------
# |                                                |
# |                 NPM UPLOADER                   |
# |                                                |
# --------------------------------------------------
# |             Yulio Aleman Jimenez               |
# |                  @yulioaj290                   |
# --------------------------------------------------

# ================================================
# FUNCTIONS
# ================================================

# Check if Git is installed
check_git_func(){
    # Must return "/usr/bin/git"
    GIT_INSTALLED="$(echo `which git | grep 'not found'`)"
    if [[ ! -z $GIT_INSTALLED ]]; then
        echo "false"
    else
        echo "true"
    fi
}

# Check if 7Zip is installed
check_7zip_func(){
    # Must return "/usr/bin/7z"
    ZIP7_INSTALLED="$(echo `which 7z | grep 'not found'`)"
    if [[ ! -z $ZIP7_INSTALLED ]]; then
        echo "false"
    else
        echo "true"
    fi
}

# Check if NPM is installed and loged in
check_npm_func(){
    # Must return "/usr/bin/npm"
    NPM_INSTALLED="$(echo `which npm | grep 'not found'`)"
    if [[ ! -z $NPM_INSTALLED ]]; then
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

# Check if YARN is installed
check_yarn_func(){
    # Must return "/usr/bin/7z"
    YARN_INSTALLED="$(echo `which yarn | grep 'not found'`)"
    if [[ ! -z $YARN_INSTALLED ]]; then
        echo "false"
    else
        echo "true"
    fi
}

# Check if given URL is valid
check_url_func(){
    local regex='^(?:(?:(?:https?|ftp):)?\/\/)(?:\S+(?::\S*)?@)?(?:(?!(?:10|127)(?:\.\d{1,3}){3})(?!(?:169\.254|192\.168)(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)(?:\.(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)*(?:\.(?:[a-z\u00a1-\uffff]{2,})))(?::\d{2,5})?(?:[/?#]\S*)?$';
    
    if [[ $1 =~ $regex ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Check if given Prefix is valid
check_prefix_func(){
    local REGEX="^[a-zA-Z0-9-]*$";
    
    if [[ ! $1 =~ $REGEX ]]; then
        echo "regex"

    elif [[ -e "$1" ]]; then
        echo "exist"

    elif [[ -e "remove.lock" ]]; then
        local PUBLISH=""
        for PACKAGE in $(cat remove.lock);
        do
            RM_PREFIX=$(echo "$PACKAGE" | cut -d'_' -f1)
            
            if [[ "$RM_PREFIX" == "$1" ]]; then
                PUBLISH="publish"
                break
            else
                PUBLISH="true"
            fi
        done
        echo "$PUBLISH"

    else
        echo "true"
    fi
}

# Check if given Weight is valid
check_weight_func(){
    local regex='^[1-9][0-9]*$';
    
    if [[ $1 =~ $regex ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Check if given ZIP Level is valid
check_ziplevel_func(){
    local regex='^[1-9]$';
    
    if [[ $1 =~ $regex ]]; then
        echo "true"
    else
        echo "false"
    fi
}


# ================================================
# MAIN PROCESS
# ================================================

# STEP 1: Verify requirements
#   * 7zip-full package installed
#   * NPM installed and loged in

if [[ $(check_7zip_func) == "false" ]]; then
    echo "${RED}[ ERROR ]: You must to install 7zip or 7zip-full package first.${NC}"
elif [[ $(check_git_func) == "false" ]]; then
    echo "${RED}[ ERROR ]: You must to install Git package first.${NC}"
elif [[ $(check_npm_func) == "installed" ]]; then
    echo "${RED}[ ERROR ]: You must to install NPM package first.${NC}"
# elif [[ $(check_npm_func) == "logedin" ]]; then
    # echo "${RED}[ ERROR ]: You must loged into the online NPM Registry.${NC}"
# elif [[ ! -e "remove.lock" ]]; then
elif [[ $1 != "-unpush" ]]; then

    # ================================================
    # STEP 2: Initialize variables
    # ================================================
    ARG_URL="false"         #   * url       : Download resource from URL
    ARG_LINK="false"        #   * link      : Make all chunk npm packages as dependencies of the 1st chunk package
    ARG_RM="false"          #   * rm        : Remove original resources
    ARG_PUSH="false"        #   * push      : Publish to NPM Registry automatically
    ARG_CRON="false"        #   * cron      : Set crontab task to automatically unpublish npm packages
    ARG_UNZIP="false"       #   * unzip     : Provide to the NPM pachages auto unzip functions
    ARG_GITCLON="false"     #   * gitclon   : Download resource as Git Repository, with 'git clone'
    ARG_DEPSNPM="false"     #   * depsnpm   : Install NPM dependencies of a project downloaded from git repository
    ARG_DEPSYARN="false"    #   * depsyarn  : Install NPM dependencies with YARN of a project downloaded from git repository
    #   ==============================================
    ARG_FILE=""             #   * file  : Resource name or URL
    ARG_PREFIX=""           #   * prefix: Prefix to use in npm packages
    ARG_WEIGHT=""           #   * weight: Chunks weight
    ARG_ZIPLV=""            #   * ziplv : Compression level


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
            *-gitclon*) 
                NUM_OPT_ARGS=$NUM_OPT_ARGS+1
                ARG_GITCLON="true";;
            *-depsnpm*) 
                NUM_OPT_ARGS=$NUM_OPT_ARGS+1
                ARG_DEPSNPM="true";;
            *-depsyarn*) 
                NUM_OPT_ARGS=$NUM_OPT_ARGS+1
                ARG_DEPSYARN="true";;
        esac
    done

    shift $NUM_OPT_ARGS

    # ================================================
    # STEP 4: Set and Validate required arguments
    # ================================================

    ARG_PREFIX=$1
    ARG_WEIGHT=$2
    ARG_ZIPLV=$3
    shift 3
    ARG_FILE=("$@")     # Assign rest of arguments, like an array of Files/URLs

    if [[ $ARG_FILE = '' ]]; then
        echo "${RED}[ ERROR ]: You must to provide the \"NAME\" of the file or directory.${NC}"
        exit 128
    elif [[ "$ARG_URL" == "false" ]]; then
        for ITEM_FILE in "${ARG_FILE[@]}";
        do
            if [[ ! -e "$ITEM_FILE" ]]; then
                echo "${RED}[ ERROR ]: The file or directory \"$ITEM_FILE\" does not exist.${NC}"
                exit 128
            fi
        done
    elif [[ "$ARG_URL" == "true" ]]; then
        for ITEM_FILE in "${ARG_FILE[@]}";
        do
            VALIDATE_URL="$(check_url_func $ITEM_FILE)"
            if [[ VALIDATE_URL = "false" ]]; then
                echo "${RED}[ ERROR ]: Invalid URL [$ITEM_FILE].${NC}"
                exit 128
            fi
        done
    fi

    if [[ $ARG_PUSH = "false" && $ARG_RM = "true" ]]; then
        echo "${RED}[ ERROR ]: Processed data would be loose if you use \"-rm\" option without \"-push\".${NC}"
        exit 128
    fi

    VALIDATE_PREFIX="$(check_prefix_func $ARG_PREFIX)"
    if [[ "$VALIDATE_PREFIX" == "regex" ]]; then
        echo "${RED}[ ERROR ]: The \"PREFIX\" must be only alphanumeric and (-), without spaces.${NC}"
        exit 128
    elif [[ "$VALIDATE_PREFIX" == "exist" ]]; then
        echo "${RED}[ ERROR ]: The file or directory \"$ARG_PREFIX\" already exist.${NC}"
        exit 128
    elif [[ "$VALIDATE_PREFIX" == "publish" ]]; then
        echo "${RED}[ ERROR ]: A package with the prefix \"$ARG_PREFIX\" has already published.${NC}"
        exit 128
    fi

    VALIDATE_WEIGHT="$(check_weight_func $ARG_WEIGHT)"
    if [[ "$VALIDATE_WEIGHT" == "false" ]]; then
        echo "${RED}[ ERROR ]: You must to provide a valid \"WEIGHT\" of chunks, a positive integer number.${NC}"
        exit 128
    fi

    VALIDATE_ZIPLEVEL="$(check_ziplevel_func $ARG_ZIPLV)"
    if [[ "$VALIDATE_ZIPLEVEL" == "false" ]]; then
        echo "${RED}[ ERROR ]: You must to provide a valid \"ZIP LEVEL\" compression, between 1 and 9.${NC}"
        exit 128
    fi

    if [[ "$ARG_UNZIP" == "true" && "$ARG_LINK" == "false" ]]; then
        echo "${RED}[ ERROR ]: To provide Auto UnZip functions, you need to link dependencies with the \"-link\" option.${NC}"
        exit 128
    fi

    if [[ "$ARG_DEPSNPM" == "true" && "$ARG_GITCLON" == "false" ]]; then
        echo "${RED}[ ERROR ]: To install NPM dependencies, you need to download from GIT repository with the \"-gitclon\" option.${NC}"
        exit 128
    fi

    if [[ "$ARG_DEPSYARN" == "true" && "$ARG_GITCLON" == "false" ]]; then
        echo "${RED}[ ERROR ]: To install dependencies with YARN, you need to download from GIT repository with the \"-gitclon\" option.${NC}"
        exit 128
    fi

    if [[ "$ARG_DEPSYARN" == "true" && $(check_yarn_func) == "false" ]]; then
        echo "${RED}[ ERROR ]: To install dependencies with YARN, you need to install \"YARN\" package first.${NC}"
        exit 128
    fi

    if [[ "$ARG_URL" == "true" && "$ARG_GITCLON" == "true" ]]; then
        echo "${RED}[ ERROR ]: You can use only one of these options [ -url | -gitclon ].${NC}"
        exit 128
    fi

    if [[ ${#ARG_FILE[@]} -gt 1 && "$ARG_GITCLON" == "true" ]]; then
        echo "${RED}[ ERROR ]: You can download only one GIT repository with the \"-gitclon\" option.${NC}"
        exit 128
    fi

    # ================================================
    # STEP 5: Sumarize arguments values
    # ================================================

    echo "===================================================="
    echo "[ Resource(s) Name(s) ] ..... ${ARG_FILE[@]}"
    # echo "[ Resource Weight ] ......... $(echo `du -hs ${ARG_FILE[@]}` | awk '{print $1}')""B"
    echo "[ Package Prefix ] .......... $ARG_PREFIX"
    echo "[ Weight of Chunks ] ........ $ARG_WEIGHT""MB"
    echo "[ Compression Level ] ....... $ARG_ZIPLV"
    echo "--------------------------------------------------"
    echo "[ Resource from URL ] ....... $ARG_URL"
    echo "[ Link Dependencies ] ....... $ARG_LINK"
    echo "[ Remove Resources ] ........ $ARG_RM"
    echo "[ Publish to NPM ] .......... $ARG_PUSH"
    # echo "[ Unpublish with CRON ] ..... $ARG_CRON"
    echo "[ Auto UnZip Functions ] .... $ARG_UNZIP"
    echo "[ Clone GIT Repository ] .... $ARG_GITCLON"
    echo "===================================================="


    # ================================================
    # STEP 6: Download resource from external URL
    # ================================================

    mkdir $ARG_PREFIX       # Creating directory of archives
    cd $ARG_PREFIX          # Moving into the directory of archives
    
    if [[ "$ARG_URL" == "true" ]]; then
        for ITEM_FILE in "${ARG_FILE[@]}";
        do
            echo "${GREEN}[ INFO ]: Downloading \"$ITEM_FILE\" from external URL...${NC}"
            echo "===================================================="

            BASENAME_FILE="$(basename "$ITEM_FILE" | cut -d'?' -f1)"
        
            wget -O "$BASENAME_FILE" --quiet "$ITEM_FILE"
        done
    elif [[ "$ARG_GITCLON" == "true" ]]; then
        for ITEM_FILE in "${ARG_FILE[@]}";
        do
            echo "${GREEN}[ INFO ]: Cloning GIT repository \"$ITEM_FILE\" ...${NC}"
            echo "===================================================="

            URL_MINUS_PARAMS="$(echo "$ITEM_FILE" | cut -d'?' -f1)"

            BASENAME_FILE="$(basename "${URL_MINUS_PARAMS%.git*}")"
        
            git clone "$ITEM_FILE"

            if [[ "$ARG_DEPSNPM" == "true" ]]; then
                echo "${GREEN}[ INFO ]: Installing dependencies with NPM ...${NC}"
                echo "===================================================="

                cd "$BASENAME_FILE"
                npm install
                cd ../
            elif [[ "$ARG_DEPSYARN" == "true" ]]; then
                echo "${GREEN}[ INFO ]: Installing dependencies with YARN ...${NC}"
                echo "===================================================="

                cd "$BASENAME_FILE"
                yarn install
                cd ../
            fi
        done
    else
        echo "${GREEN}[ INFO ]: Grouping files inside \"$ARG_PREFIX\" directory...${NC}"
        echo "===================================================="

        for ITEM_FILE in "${ARG_FILE[@]}";
        do
        
            mv "../$ITEM_FILE" "./"
        done
    fi

    cd ../                  # Moving outside the directory of archives


    # ================================================
    # STEP 7: Check number of chunks
    # ================================================

    FILES_WEIGHT="$(echo `du -s $ARG_PREFIX` | cut -d' ' -f1)"

    WEIGHT_IN_MB="$(( ($FILES_WEIGHT + (1024 - 1) ) / 1024 ))"

    CHUNKS_NUM="$(( ($WEIGHT_IN_MB + ( $ARG_WEIGHT - 1) ) / $ARG_WEIGHT ))"


    # ================================================
    # STEP 8: Compressing and splitting resource
    # ================================================

    echo "${GREEN}[ INFO ]: Splitting file(s) of [ $ARG_PREFIX ] directory into [ $CHUNKS_NUM ] chunks ...${NC}"

    7za a -t7z -m0=lzma -mx=$ARG_ZIPLV -ms=on -v"$ARG_WEIGHT"m $ARG_PREFIX.7z $ARG_PREFIX

    echo "===================================================="

    # ================================================
    # STEP 9: Removing original resource
    # ================================================

    if [[ "$ARG_RM" == "true" ]]; then
        echo "${GREEN}[ INFO ]: Removing original files [ $ARG_PREFIX ] ...${NC}"
        echo "===================================================="

        rm -rf $ARG_PREFIX
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
            UNZIP_SCRIPT="$UNZIP_SCRIPT""mv ../$CHUNK_DIR_NAME/$CURRENT_PKG ../ \n"
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
    UNZIP_SCRIPT="$UNZIP_SCRIPT""echo \"${NC}Remember to unpublish all pachages from 'NPMJS.com'.${NC}\" \n"
    UNZIP_SCRIPT="$UNZIP_SCRIPT""echo \"${NC}Remember to delete the '${ARG_PREFIX}_001' package folder.${NC}\" \n"
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
    
        if [[ "$ARG_RM" == "true" ]]; then
            echo "        :.. Removed local package ..."

            rm -rf $CHUNK_DIR_NAME
        fi

        echo "--------------------------------------------------"
    done

    echo "${ARG_PREFIX}_${CHUNKS_NUM}" >> remove.lock

    echo "${GREEN}[ INFO ]: Processed [ $CHUNKS_NUM ] NPM chunk packages.${NC}"
    echo "===================================================="

    echo "success"

elif [[ $1 == "-unpush" ]]; then

    echo "===================================================="
    echo "${GREEN}[ INFO ]: Preparing to unpublish NPM Packages ...${NC}"
    echo "===================================================="

    if [[ ! -z $2 ]]; then

        for PACKAGE in $(cat remove.lock);
        do
            if [[ "$PACKAGE" == "$2" ]]; then
                RM_PREFIX=$(echo "$2" | cut -d'_' -f1)
                RM_NUM_CHUNKS=$(echo "$2" | cut -d'_' -f2)

                for (( i=1 ; i <= $RM_NUM_CHUNKS ; i++ ))
                do

                    if [[ $i -lt 10 ]]; then
                        CHUNK_ITEM_NUM="00$i"
                    elif [[ $i -ge 10 ]] && [[ $i -lt 100 ]]; then
                        CHUNK_ITEM_NUM="0$i"
                    else
                        CHUNK_ITEM_NUM="$i"
                    fi

                    echo "     [*]: Unpublided Package: ${RM_PREFIX}_${CHUNK_ITEM_NUM}"

                    npm unpublish --force $PACKAGE
                done

                echo "--------------------------------------------------"
            else
                echo "$PACKAGE" >> tmp.lock
            fi
        done

        rm -rf "remove.lock"

        if [[ -e "tmp.lock" ]]; then
            mv "tmp.lock" "remove.lock"
        fi

    else

        for PACKAGE in $(cat remove.lock);
        do
            RM_PREFIX=$(echo "$PACKAGE" | cut -d'_' -f1)
            RM_NUM_CHUNKS=$(echo "$PACKAGE" | cut -d'_' -f2)


            for (( i=1 ; i <= $RM_NUM_CHUNKS ; i++ ))
            do

                if [[ $i -lt 10 ]]; then
                    CHUNK_ITEM_NUM="00$i"
                elif [[ $i -ge 10 ]] && [[ $i -lt 100 ]]; then
                    CHUNK_ITEM_NUM="0$i"
                else
                    CHUNK_ITEM_NUM="$i"
                fi

                echo "     [*]: Unpublided Package: ${RM_PREFIX}_${CHUNK_ITEM_NUM}"

                npm unpublish --force $PACKAGE
            done

            echo "--------------------------------------------------"
        done

        rm -rf remove.lock
    fi

    echo "===================================================="
fi
