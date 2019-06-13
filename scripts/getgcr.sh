#!/bin/env bash
# 
# lework
# Download Google container image from proxy point.


######################################################################################################
# environment configuration
######################################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
GREEN_PS3=$'\e[0;32m'
ORANGE_PS3=$'\e[0;33m'
WHITE='\033[0;37m'

proxy=("gcr.azk8s.cn/google_containers" "gcrxio")

######################################################################################################
# function
######################################################################################################

function check() {
  docker info >/dev/null 2>1
  if [ "$?" != "0" ]; then
    echo -e "${RED}Please check if the docker service is started or installed."
    tput sgr0
    exit 1
  fi
}

function pull() {
  echo -e "${ORANGE}Proxy: $proxy_url"
  tput sgr0
  docker pull $proxy_url$image
  if [ "$?" == "0" ]; then
    docker tag $proxy_url$image $image_url
    echo -e "${ORANGE}Delete Proxy image."
    tput sgr0
    docker rmi $proxy_url$image
    echo -e "${GREEN}Pull image success."
    tput sgr0
    exit 0 
  else
    echo -e "${RED}Pull image failed."
    tput sgr0
  fi
}

function usage {
    echo
    echo "Usage: $0 [[[-p proxy] [-i image]] | [-h]]"
    echo "  -p,--proxy      proxy url, exp: gcr.azk8s.cn gcrxio"
    echo "  -i,--image      images url, exp: k8s.gcr.io/pause-amd64:3.0"
    echo
    echo
    echo "Example:"
    echo "  $0 gcr.io/google_containers/pause-amd64:3.0"
    echo "  $0 -i k8s.gcr.io/pause-amd64:3.0"
    echo "  $0 -p 127.0.0.1:5000 -i k8s.gcr.io/pause-amd64:3.0"
    echo
    exit 1
}


######################################################################################################
# main 
######################################################################################################

check
[ "$#" == "0" ] && usage

while [ "$1" != "" ]; do
    case $1 in
        -p | --proxy )          shift
                                unset proxy
                                proxy=$1
                                ;;
        -i | --image )          shift
				image_url=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        *\.* | *\/*)            image_url=$1
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done
echo $proxy
for proxy_url in ${proxy[@]}; do
   [ "${proxy_url:0-1}" != "/" ] && proxy_url=$proxy_url/
   image=${image_url##*/}
   pull
done
