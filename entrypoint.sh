#!/bin/bash
set -ueo pipefail

DEST_BUCKET_URL="${1:-NONE}"

AWS_REGION="${AWS_REGION:-eu-west-1}"
AWS_INSTANCE_ID=$(
    curl --connect-timeout 3 -s http://169.254.169.254/latest/meta-data/instance-id || \
        echo -n 'UNKNOWN_INSTANCE'
)

declare child_awscli
declare child_inotify
declare child_subshell

function log() {
    echo "[entrypoint.sh] ${@}" >&2
}

function _term() {
    log "Caught SIGTERM/SIGINT"

    # Terminate the subshell which is piping from inotifywait
    [[ "${child_subshell:+x}" == "x" ]] && {
        log "Terminating subshell ${child_subshell}"
        kill -SIGTERM "${child_subshell}"
    }

    # Terminate the inotify process if it is still running
    [[ "${child_inotify:+x}" == "x" ]] && {
        log "Terminating inotify watcher (PID ${child_inotify})"
        kill -SIGTERM "${child_inotify}"
        wait "${child_inotify}"  || true
    }

    [[ "${child_subshell:+x}" == "x" ]] && {
        log "Waiting for subshell to exit..."
        wait "${child_subshell}" || true
    }

    log "Done."
    exit 0
}

function _term_subshell() {
    log "Subshell caught SIGTERM/SIGINT"
    # Wait for any S3 uploads to complete before exiting
    if [[ "${child_awscli:+x}" == "x" ]]; then
        log "Waiting for S3 upload (pid ${child_awscli}) to exit..."
        wait "${child_awscli}"
    fi
    log "Subshell exiting"
    exit 0
}

function _err() {
    # Trap unhandled errors and log before exit
    log "ERR: ${2} exited ${1} on line $(caller)"
    exit ${1}
}

function inotify_watch() {
    unset child_inotify
    unset child_subshell
    # Using a subshell here ensures that $! contains the pid of inotifywait
    inotifywait -m /watch -e close_write | (
        set -eu
        trap _term_subshell INT TERM
        while read path action file; do
            src="${path}${file}"
            dst="${DEST_BUCKET_URL%/}/${AWS_INSTANCE_ID}/"
            s3upload "${src}" "${dst}" || { log "Failed to upload"; }
            log "Uploaded from src:${src} to dest:${dst}"
        done
    ) &
    child_subshell="$!"
    child_inotify=$(jobs -p)
    wait "${child_inotify}"
    # unset if command completes normally so we don't try to kill in trap
    unset child_inotify
    unset child_subshell
}

function s3upload() {
    src=${1}
    dst=${2}
    log "Uploading ${src} to ${dst}"
    aws s3 cp --sse AES256 --region="${AWS_REGION}" "${src}" "${dst}" &
    child_awscli=$!
    wait "${child_awscli}"
    rc=$?
    [ "$rc" -ne "0" ] && return $rc
    # unset if command completes normally so we don't try to kill in trap
    unset child_awscli
    rm -v "${src}"
}

trap _term TERM INT  # Normal exit signals
trap '_err ${?} ${BASH_COMMAND}' ERR  # Unhandled errors

[[ "${DEST_BUCKET_URL}" == "NONE" ]] && {
    log "Destination S3 bucket URL must be specified as first argument";
    exit 2;
}

log "Destination Bucket URL: ${DEST_BUCKET_URL}"

log "AWS Instance: ${AWS_INSTANCE_ID}"

while true ; do
    log "Watching /watch for CLOSE_WRITE events"
    inotify_watch
done
