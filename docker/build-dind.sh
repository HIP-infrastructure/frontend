#! /bin/bash


cd "${0%/*}"

# docker buildx create --driver-opt image=moby/buildkit:master  \
#                      --use --name insecure-builder \
#                      --buildkitd-flags '--allow-insecure-entitlement security.insecure'
# docker buildx create --use --name insecure-builder \
#                      --buildkitd-flags '--allow-insecure-entitlement security.insecure' || true
# docker buildx use insecure-builder

# docker buildx build --allow security.insecure --build-context local/dip-docker-front-v2-stage1=docker-image://local/dip-docker-front-v2-stage1 -f Dockerfile -t local/dip-docker-front-v2 ..

# docker buildx rm insecure-builder

docker run -ti --entrypoint ./install.sh --privileged local/dip-docker-front-v2-stage1-dind 
export CONTAINER_ID=`docker ps -lq`
docker commit $CONTAINER_ID local/dip-docker-front-v2-dind