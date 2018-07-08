#!/bin/bash
#
# Copyright 2018 Yulio Aleman Jimenez (@yulioaj290)
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
# This script split a file into chunks, create a NPM package with each one, and finally upload each package to https://npmjs.com
#

echo "--------------------------------------------------"
echo "|                                                |"
echo "|                  NPM UPLOADER                  |"
echo "|                                                |"
echo "--------------------------------------------------"
echo "|             Yulio Aleman Jimenez               |"
echo "|                  @yulioaj290                   |"
echo "--------------------------------------------------"


if [[ ! -e "remove.lock" ]]; then

    FILE_NAME=$1
    PREFIX_PKG=$2
    SPLIT_WEIGHT=$3

    NPM_INIT_START='{
      "name": "'
    NPM_INIT_END='",
      "version": "1.0.0",
      "description": "",
      "main": "index.js",
      "author": "",
      "license": "ISC"
    }
    '

    if [[ $FILE_NAME = '' ]]; then
        echo "[ ERROR ]: You must to provide the 'NAME' of the file or directory."
        echo "  --> SYNTAX EXAMPLE: bash NPM_UPLOADER.sh video.mp4 video-clip 30"
        exit 128
    else
        if [[ ! -e "$FILE_NAME" ]]; then
            echo "[ ERROR ]: The file or directory $FILE_NAME doesn't exist."
            echo "  --> SYNTAX EXAMPLE: bash NPM_UPLOADER.sh video.mp4 video-clip 30"
            exit 128
        fi
    fi

    if [[ $PREFIX_PKG = '' ]]; then
        echo "[ ERROR ]: You must to provide the 'PREFIX' of NPM Packages."
        echo "  --> SYNTAX EXAMPLE: bash NPM_UPLOADER.sh video.mp4 video-clip 30"
        exit 128
    fi

    if [[ $SPLIT_WEIGHT = '' ]]; then
        SPLIT_WEIGHT=50
    fi

    echo "--------------------------------------------------"
    echo "[ File Name ]: $FILE_NAME"
    echo "[ Package Prefix ]: $PREFIX_PKG"
    echo "[ Weight of Chunks ]: $SPLIT_WEIGHT"" MB"

    FILE_WEIGHT="$(echo `du $FILE_NAME` | cut -d' ' -f1)"

    WEIGHT_IN_MB="$(( ($FILE_WEIGHT + (1024 - 1) ) / 1024 ))"

    echo "[ File Weight ]: $WEIGHT_IN_MB"" MB"
    echo "--------------------------------------------------"

    CHUNKS_NUM="$(( ($WEIGHT_IN_MB + ( $SPLIT_WEIGHT - 1) ) / $SPLIT_WEIGHT ))"

    echo "Splitting file into $CHUNKS_NUM chunks ..."
    echo "--------------------------------------------------"

    7za a -t7z -m0=lzma -mx=9 -ms=on -v"$SPLIT_WEIGHT"m $PREFIX_PKG.7z $FILE_NAME

    echo "--------------------------------------------------"
    echo "Removing original file ..."
    echo "--------------------------------------------------"

    rm -rf $FILE_NAME

    for (( i=1 ; i <= $CHUNKS_NUM ; i++ ))
    do

        if [[ $i -lt 10 ]]; then
            CHUNK_ITEM_NUM="00$i"
        elif [[ $i -ge 10 ]] && [[ $i -lt 100 ]]; then
            CHUNK_ITEM_NUM="0$i"
        else
            CHUNK_ITEM_NUM="$i"
        fi

        CHUNK_DIR_NAME="$PREFIX_PKG""_""$CHUNK_ITEM_NUM"

        mkdir $CHUNK_DIR_NAME

        mv $PREFIX_PKG.7z.$CHUNK_ITEM_NUM $CHUNK_DIR_NAME/
        
        cd $CHUNK_DIR_NAME

        echo "$NPM_INIT_START""$CHUNK_DIR_NAME""$NPM_INIT_END" >> package.json

        npm publish

        echo "  --> Uploaded Package No. $i: $CHUNK_DIR_NAME"

        cd ../

        echo $CHUNK_DIR_NAME >> remove.lock

        rm -rf $CHUNK_DIR_NAME

        echo "  --> Removed Package No. $i"
        echo "--------------------------------------------------"
    done

    echo "[ INFO ]: File uploaded to npmjs.com successfully!!!"
    echo "--------------------------------------------------"

else

    echo "--------------------------------------------------"
    echo "[ INFO ]: Preparing to unpublish NPM Packages"
    echo "--------------------------------------------------"

    for PACKAGE in $(cat remove.lock);
    do
        npm unpublish --force $PACKAGE

        echo "  --> Unpublided Package No. $i: $PACKAGE"
    done

    rm -rf remove.lock

    echo "--------------------------------------------------"

fi