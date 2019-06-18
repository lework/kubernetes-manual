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

proxy=(
  "gcr.azk8s.cn/google_containers"
  "registry.aliyuncs.com/google_containers"
  "gcrxio"
)
images=(
  "k8s.gcr.io/kube-apiserver:"
  "k8s.gcr.io/kube-controller-manager:"
  "k8s.gcr.io/kube-scheduler:"
  "k8s.gcr.io/kube-proxy:"
  "k8s.gcr.io/pause-amd64:3.1"
)

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
  local image_url=$1
  local image=${image_url##*/}

  for proxy_url in ${proxy[*]}; do
    [ "${proxy_url:0-1}" != "/" ] && proxy_url=$proxy_url/
    echo -e "${ORANGE}[Proxy:] $proxy_url"
    echo -e "[Image:] $image_url"
    tput sgr0
    docker pull $proxy_url$image
    if [ "$?" == "0" ]; then
      docker tag $proxy_url$image $image_url
      docker images ${image_url}
      echo -e "${ORANGE}[Delete:] Delete Proxy image."
      tput sgr0
      docker rmi $proxy_url$image
      echo -e "${GREEN}[Result:] Pull image success."
      tput sgr0
      echo
      break
    else
      echo -e "${RED}[Result:] Pull image failed."
      tput sgr0
      echo
    fi
  done 
}

function usage {
    echo "Download the Google docker image through the proxy node"
    echo
    echo "Usage: $0 [[[-p proxy] [-i image] | [-t tag] | [-f file]] | [-h]]"
    echo "  -p,--proxy      Specify proxy node url"
    echo "  -i,--image      Specify the image name"
    echo "  -t,--tag        Specify the image tag and download the k8s family bucket."
    echo "  -f,--file       Specify a file path containing the name"
    echo "  -h,--help       View help"
    echo
    echo
    echo "Example:"
    echo "  $0 gcr.io/google_containers/pause-amd64:3.1"
    echo "  $0 \"k8s.gcr.io/kube-{apiserver,controller-manager,proxy,scheduler}:v1.14.3\""
    echo "  $0 -i k8s.gcr.io/pause-amd64:3.1"
    echo "  $0 -p registry.aliyuncs.com/google_containers -i k8s.gcr.io/pause-amd64:3.1"
    echo "  $0 -t v1.14.3"
    echo "  $0 -f ./images.txt"
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
        -t | --tag )            shift
				tag=$1
                                ;;
        -f | --file )           shift
				file=$1
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

if echo "$image_url" | grep -q "{"; then
  prefix_image=$(echo $image_url | cut -d '{' -f 1)
  tag_image=$(echo $image_url | cut -d ':' -f 2)
  muti_image=$(echo $image_url | cut -d '{' -f 2 | cut -d '}' -f 1)
  for i in $(echo $muti_image | tr "," "\n")
  do
    pull $prefix_image$i:$tag_image
  done
  exit 0
fi

if [ "$tag" != "" ]; then
  for image in ${images[*]}
  do
    [ "${image:0-1}" == ":" ] && pull $image$tag || pull $image
  done
  exit 0
fi

if [ "$file" != "" ]; then
  while IFS= read line
  do
    pull $line
  done <"$file"
  exit 0
fi

pull $image_url
