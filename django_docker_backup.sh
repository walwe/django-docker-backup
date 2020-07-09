#!/bin/bash
set -euo pipefail

OPTIND=1  # Reset in case getopts has been used previously in the shell.

function show_help {
  echo "$0 -m <media-volume-name> -c <db-container-name> -d <db-role> -o <output-dir>"
}

MEDIA_VOLUME_NAME=""
DB_CONTAINER_NAME=""
DB_ROLE=postgres

while getopts "h?d:m:c:o:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    m) MEDIA_VOLUME_NAME=${OPTARG}
        ;;
    d) DB_ROLE=${OPTARG}
        ;;
    c) DB_CONTAINER_NAME=${OPTARG}
        ;;
    o) OUTPUT_PATH=${OPTARG}
        ;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

if [ -z "${OUTPUT_PATH}" ] || [[ ( -z "${MEDIA_VOLUME_NAME}" )  &&  ( -z "${DB_CONTAINER_NAME}" ) ]]; then
    show_help
    exit 1
fi

mkdir -p "${OUTPUT_PATH}"
DATE_NOW=$(date -u +"%Y-%m-%dT%H_%M_%S")

if [ -n "${MEDIA_VOLUME_NAME}" ]; then
  MEDIA_VOLUME_PATH=$(docker volume inspect ${MEDIA_VOLUME_NAME} | sed -ne '/"Mountpoint": "/p' | sed 's/.*"\(\/.*\)".*/\1/')
  if [ -n "${MEDIA_VOLUME_PATH}" ]; then
    MEDIA_ARCHIVE="${OUTPUT_PATH}/media_${DATE_NOW}.zip"
    echo "Compressing $MEDIA_VOLUME_PATH into ${MEDIA_ARCHIVE}"
    zip -r "${MEDIA_ARCHIVE}" "${MEDIA_VOLUME_PATH}"
  fi
fi

if [ -n "${DB_CONTAINER_NAME}" ]; then
  SQL_ARCHIVE="${OUTPUT_PATH}/db_dump_${DATE_NOW}.sql.gz"
  echo "Dump SQL DB ${DB_ROLE} in ${DB_CONTAINER_NAME} into ${SQL_ARCHIVE}"
  docker exec "${DB_CONTAINER_NAME}" pg_dump -U "${DB_ROLE}" | gzip > "${SQL_ARCHIVE}"
fi
