#!/bin/bash
set -e

OPTIND=1  # Reset in case getopts has been used previously in the shell.

function show_help {
  echo "$0 -m <media-volume-name> -c <db-container-name> -d <db-role> -o <output-dir>"
}

MEDIA_VOLUME_ROLE=""
DB_CONTAINER_ROLE=""
DB_ROLE=postgres

while getopts "h?d:m:c:o:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    m) MEDIA_VOLUME_ROLE=${OPTARG}
        ;;
    d) DB_ROLE=${OPTARG}
        ;;
    c) DB_CONTAINER_ROLE=${OPTARG}
        ;;
    o) OUTPUT_PATH=${OPTARG}
        ;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

if [ -z "${MEDIA_VOLUME_ROLE}" ] || [ -z "${DB_CONTAINER_ROLE}" ] || [ -z "${OUTPUT_PATH}" ]; then
    show_help
    exit 1
fi


DATE_NOW=$(date -u +"%Y-%m-%dT%H_%M_%S")
MEDIA_ARCHIVE="${OUTPUT_PATH}/media_${DATE_NOW}.zip"
SQL_ARCHIVE="${OUTPUT_PATH}/db_dump_${DATE_NOW}.sql.gz"

MEDIA_VOLUME_PATH=$(docker volume inspect ${MEDIA_VOLUME_ROLE} | sed -ne '/"Mountpoint": "/p' | sed 's/.*"\(\/.*\)".*/\1/')
mkdir -p ${OUTPUT_PATH}
echo "Compressing $MEDIA_VOLUME_PATH into ${MEDIA_ARCHIVE}"
zip -r "${MEDIA_ARCHIVE}" "${MEDIA_VOLUME_PATH}"
echo "Dump SQL DB ${DB_ROLE} in ${DB_CONTAINER_ROLE} into ${SQL_ARCHIVE}"
docker exec "${DB_CONTAINER_ROLE}" pg_dump -U "${DB_ROLE}" | gzip > "${SQL_ARCHIVE}"
