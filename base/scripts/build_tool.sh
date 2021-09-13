#!/usr/bin/env bash
#
# build    ... builds a local version
# run      ... runs the locally built version
# run-prod ... downloads the version from docker registry and runs it
# publish  ... publishes the locally built version

set -o errexit; set -o pipefail; set -o nounset

readonly RE_DOCKER_REGISTRY
readonly RE_DOCKER_PASSWORD
readonly RE_DOCKER_USERNAME

readonly _BT_MICROSERVICE_NAME="pb-base"

readonly _BT_MICROSERVICE_VERSION="1.0"
readonly _BT_DOCKER_REPOSITORY="planbeamer-01/${_BT_MICROSERVICE_NAME}"
readonly _BT_DOCKER_TAG="${_BT_DOCKER_REPOSITORY}:${_BT_MICROSERVICE_VERSION}"
readonly _BT_DOCKER_TAG_FULL="${_BT_DOCKER_REPOSITORY}:${_BT_MICROSERVICE_VERSION}-full"
readonly _BT_DOCKER_REGISTRY_REPOSITORY="${RE_DOCKER_REGISTRY:-}/${_BT_DOCKER_REPOSITORY}"
readonly _BT_DOCKER_REGISTRY_TAG="${_BT_DOCKER_REGISTRY_REPOSITORY}:${_BT_MICROSERVICE_VERSION}"

declare DOCKER_HOST

# Reserve half of the available processors for compilation (used in Dockerfile)
readonly NPROC=$(expr `nproc` / 2)

_docker_login() {
    echo ${RE_DOCKER_PASSWORD:?} | docker login -u ${RE_DOCKER_USERNAME:?} --password-stdin ${RE_DOCKER_REGISTRY:?}
}

_build_production_image() {
    _docker_login
    docker build --pull --tag "${_BT_DOCKER_TAG}" \
        --build-arg NPROC=$NPROC \
        --label "org.label-schema.build-date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --label "org.label-schema.version=${_BT_MICROSERVICE_VERSION}" \
        --label "org.label-schema.vcs-ref=${_BT_MICROSERVICE_VERSION}" \
        .
}

case "${1:-}" in
    build)
        _build_production_image
        ;;
    run)
        shift # remove first argument

        # run production image
        docker run --rm --tty --interactive \
            ${_BT_DOCKER_TAG} "$@"
        ;;
    run-prod)
        _docker_login
        shift # remove first argument

        # run production image
        docker run --rm --tty --interactive \
            --user "$(id -u):$(id -g)" \
            ${_BT_DOCKER_REGISTRY_TAG} "$@"
        ;;
    publish)
        _docker_login
        # tag image for push
        docker tag ${_BT_DOCKER_TAG} ${_BT_DOCKER_REGISTRY_TAG}
        # push image
        docker push ${_BT_DOCKER_REGISTRY_TAG}
        ;;
    version-info)
        echo "{\"microserviceName\":\"${_BT_MICROSERVICE_NAME}\", \"microserviceVersion\":\"${_BT_MICROSERVICE_VERSION}\"}"
        ;;
    *)
        echo "Usage: ${0} {build|run|run-prod|publish|version-info}"
        exit 1
esac
