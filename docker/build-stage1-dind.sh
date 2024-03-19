#! /bin/bash


cd "${0%/*}"

# docker buildx create --driver-opt image=moby/buildkit:master  \
#                      --use --name insecure-builder \
#                      --buildkitd-flags '--allow-insecure-entitlement security.insecure'
# docker buildx create --use --name insecure-builder \
#                      --buildkitd-flags '--allow-insecure-entitlement security.insecure' || true
# docker buildx use insecure-builder

# docker buildx build --allow security.insecure -f Dockerfile.stage1 -t local/dip-docker-front-v2-stage1 ..

# docker buildx rm insecure-builder

docker build -f Dockerfile.stage1-dind -t local/dip-docker-front-v2-stage1-dind ..