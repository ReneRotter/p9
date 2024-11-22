#!/bin/bash

SOURCE_USER="save"
SOURCE_HOST="srv-backup"
SOURCE_BASE="/home/save"
DEST_BASE="/home/rrotter"
LOG_FILE="/home/rrotter/logs/restore_inc.log"
RETENTION_DAYS=30  # Nombre de jours de retention pour la version n-1

DIRECTORIES=("site" "rh" "tickets" "fichiers" "emails")

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

restore_latest() {
    local dir=$1
    log "Restauration de la derniere version de $dir"
    rsync -avz -e "ssh -i /home/rrotter/.ssh/id_rsa" \
        "${SOURCE_USER}@${SOURCE_HOST}:${SOURCE_BASE}/${dir}/current/" "${DEST_BASE}/${dir}/"
}

restore_previous() {
    local dir=$1
    local previous_backup=$(ssh -i /home/rrotter/.ssh/id_rsa ${SOURCE_USER}@${SOURCE_HOST} "ls -1td ${SOURCE_BASE}/${dir}/incremental/* | head -n 1")
    if [ -n "$previous_backup" ]; then
        local backup_date=$(echo $previous_backup | grep -oP '\d{4}-\d{2}-\d{2}')
        local days_diff=$(( ( $(date +%s) - $(date -d $backup_date +%s) ) / 86400 ))
        if [ $days_diff -le $RETENTION_DAYS ]; then
            log "Restauration de la version precedente de $dir"
            rsync -avz -e "ssh -i /home/rrotter/.ssh/id_rsa" \
                "${SOURCE_USER}@${SOURCE_HOST}:${previous_backup}/" "${DEST_BASE}/${dir}/"
        else
            log "La version precedente de $dir est trop ancienne (plus de $RETENTION_DAYS jours)"
        fi
    else
        log "Aucune version precedente disponible pour $dir"
    fi
}

restore_directory() {
    local dir=$1
    local version=$2
    case $version in
        latest)
            restore_latest $dir
            ;;
        previous)
            restore_previous $dir
            ;;
        *)
            log "Version non valide pour $dir: $version"
            ;;
    esac
}

if [ $# -eq 0 ]; then
    echo "Usage: $0 {directory} {latest|previous}"
    echo "       $0 all {latest|previous}"
    exit 1
fi

if [ "$1" = "all" ]; then
    if [ "$2" = "latest" ] || [ "$2" = "previous" ]; then
        for dir in "${DIRECTORIES[@]}"; do
            restore_directory $dir $2
        done
    else
        echo "Pour restaurer tous les repertoires, specifiez 'latest' ou 'previous'"
        exit 1
    fi
else
    if [[ " ${DIRECTORIES[@]} " =~ " $1 " ]]; then
        if [ "$2" = "latest" ] || [ "$2" = "previous" ]; then
            restore_directory $1 $2
        else
            echo "Specifiez 'latest' ou 'previous' pour la version a restaurer"
            exit 1
        fi
    else
        echo "Repertoire non valide. Choisissez parmi: ${DIRECTORIES[*]}"
        exit 1
    fi
fi

log "Processus de restauration termine"
