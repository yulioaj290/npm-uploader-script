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
    local regex="^[a-zA-Z0-9-]*$";
    
    if [[ $1 =~ $regex ]]; then
        echo "true"
    else
        echo "false"
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

    ARG_PREFIX=$1
    ARG_WEIGHT=$2
    ARG_ZIPLV=$3
    shift 3
    ARG_FILE=("$@")     # Assign rest of arguments, like an array of Files/URLs

    if [[ $ARG_FILE = '' ]]; then
        echo "[ ERROR ]: You must to provide the \"NAME\" of the file or directory."
        exit 128
    elif [[ "$ARG_URL" == "false" ]]; then
        for ITEM_FILE in "${ARG_FILE[@]}";
        do
            if [[ ! -e "$ITEM_FILE" ]]; then
                echo "[ ERROR ]: The file or directory \"$ITEM_FILE\" does not exist."
                exit 128
            fi
        done
    elif [[ "$ARG_URL" == "true" ]]; then
        for ITEM_FILE in "${ARG_FILE[@]}";
        do
            VALIDATE_URL="$(check_url_func $ITEM_FILE)"
            if [[ VALIDATE_URL = "false" ]]; then
                echo "[ ERROR ]: Invalid URL [$ITEM_FILE]."
                exit 128
            fi
        done
    fi

    if [[ $ARG_PUSH = "false" && $ARG_RM = "true" ]]; then
        echo "[ ERROR ]: Processed data would be loose if you use \"-rm\" option without \"-push\"."
        exit 128
    fi

    VALIDATE_PREFIX="$(check_prefix_func $ARG_PREFIX)"
    if [[ "$VALIDATE_PREFIX" == "false" ]]; then
        echo "[ ERROR ]: The \"PREFIX\" must be only alphanumeric and (-), without spaces."
        exit 128
    fi

    VALIDATE_WEIGHT="$(check_weight_func $ARG_WEIGHT)"
    if [[ "$VALIDATE_WEIGHT" == "false" ]]; then
        echo "[ ERROR ]: You must to provide a valid \"WEIGHT\" of chunks, a positive integer number."
        exit 128
    fi

    VALIDATE_ZIPLEVEL="$(check_ziplevel_func $ARG_ZIPLV)"
    if [[ "$VALIDATE_ZIPLEVEL" == "false" ]]; then
        echo "[ ERROR ]: You must to provide a valid \"ZIP LEVEL\" compression, between 1 and 9."
        exit 128
    fi

    if [[ "$ARG_UNZIP" == "true" && "$ARG_LINK" == "false" ]]; then
        echo "[ ERROR ]: To provide Auto UnZip functions, you need to link dependencies with the \"-link\" option."
    fi

    # ================================================
    # STEP 5: Sumarize arguments values
    # ================================================

    echo "=================================================="
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
    echo "[ Unpublish with CRON ] ..... $ARG_CRON"
    echo "[ Auto UnZip Functions ] .... $ARG_UNZIP"
    echo "=================================================="


    # ================================================
    # STEP 6: Download resource from external URL
    # ================================================

    mkdir $ARG_PREFIX       # Creating directory of archives
    cd $ARG_PREFIX          # Moving into the directory of archives
    
    if [[ "$ARG_URL" == "true" ]]; then
        for ITEM_FILE in "${ARG_FILE[@]}";
        do
            echo "[ INFO ]: Downloading \"$ITEM_FILE\" from external URL..."
            echo "=================================================="

            BASENAME_FILE="$(basename "$ITEM_FILE" | cut -d'?' -f1)"
        
            wget -O "$BASENAME_FILE" --quiet "$ITEM_FILE"
        done
    else
        echo "[ INFO ]: Grouping files inside \"$ARG_PREFIX\" directory..."
        echo "=================================================="

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

    echo "[ INFO ]: Splitting file(s) of [ $ARG_PREFIX ] directory into [ $CHUNKS_NUM ] chunks ..."

    7za a -t7z -m0=lzma -mx=$ARG_ZIPLV -ms=on -v"$ARG_WEIGHT"m $ARG_PREFIX.7z $ARG_PREFIX

    echo "=================================================="

    # ================================================
    # STEP 9: Removing original resource
    # ================================================

    if [[ "$ARG_RM" == "true" ]]; then
        echo "[ INFO ]: Removing original files [ $ARG_PREFIX ] ..."
        echo "=================================================="

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
    
        if [[ "$ARG_RM" == "true" ]]; then
            echo "        :.. Removed local package ..."

            rm -rf $CHUNK_DIR_NAME
        fi

        echo "--------------------------------------------------"
    done

    echo "${ARG_PREFIX}_${CHUNKS_NUM}" >> remove.lock

    echo "[ INFO ]: Processed [ $CHUNKS_NUM ] NPM chunk packages"
    echo "=================================================="

    echo "success"

else

    echo "=================================================="
    echo "[ INFO ]: Preparing to unpublish NPM Packages"
    echo "=================================================="

    if [[ $1 == "-unpush" ]]; then

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

    echo "=================================================="
fi
