#!/usr/bin/env sh

TAG="$1"

docker build -t kasm-deb12:"${TAG}" .
docker tag kasm-deb12:"${TAG}" registry.home.arpa:5000/kasm/kasm-deb12:"${TAG}"
docker push registry.home.arpa:5000/kasm/kasm-deb12:"${TAG}"
