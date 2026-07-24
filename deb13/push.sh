#!/usr/bin/env sh

TAG="$1"

docker build -t kasm-deb13:"${TAG}" .
docker tag kasm-deb13:"${TAG}" registry.home.arpa:5000/kasm/kasm-deb13:"${TAG}"
docker push registry.home.arpa:5000/kasm/kasm-deb13:"${TAG}"
