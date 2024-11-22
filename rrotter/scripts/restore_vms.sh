#!/bin/bash

SOURCE_USER="save"
SOURCE_HOST="srv-backup"
SOURCE_BASE="/home/save/vms"
DEST_BASE="/home/rrotter"
LOG_FILE="/home/rrotter/logs/restore_dif.log"

DIRECTORIES=("emails" "tickets" "site" "rh" "fichiers")

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

check_backup_validity() {
    local dir=$1
    local SOURCE_DIR="${SOURCE_BASE}/${dir}"
    
    # Verifier l'existence de la sauvegarde
    if ! ssh -i /home/rrotter/.ssh/id_rsa ${SOURCE_USER}@${SOURCE_HOST} "[ -d ${SOURCE_DIR} ]"; then
        log "Aucune sauvegarde trouvee pour ${dir}" >> "$LOG_FILE" 2&>1
        return 1
    fi
    
    # Verifier la date de la derniere sauvegarde
    local last_backup_date=$(ssh -i /home/rrotter/.ssh/id_rsa ${SOURCE_USER}@${SOURCE_HOST} "stat -c %Y ${SOURCE_DIR}")
    local current_time=$(date +%s)
    local time_diff=$((current_time - last_backup_date))
    
    if [ $time_diff -gt 86400 ]; then  # 86400 secondes = 24 heures
        log "La derniere sauvegarde de ${dir} date de plus de 24 heures" >> "$LOG_FILE" 2&>1
        return 1
    fi
    
    return 0
}

restore_directory_differential() {
    local dir=$1
    local SOURCE_DIR="${SOURCE_BASE}/${dir}"
    local DEST_DIR="${DEST_BASE}/${dir}"

    log "Debut de la restauration differentielle du repertoire ${dir}" >> "$LOG_FILE" 2&>1
    
    if check_backup_validity "$dir"; then
        rsync -avvz --delete \
            -e "ssh -i /home/rrotter/.ssh/id_rsa" \
            "${SOURCE_USER}@${SOURCE_HOST}:${SOURCE_DIR}/" "${DEST_DIR}/"
        
        if [ $? -eq 0 ]; then
            log "Restauration differentielle de ${dir} terminee avec succes" >> "$LOG_FILE" 2&>1
        else
            log "Erreur lors de la restauration differentielle de ${dir}" >> "$LOG_FILE" 2&>1
        fi
    else
        log "Impossible de restaurer ${dir} - sauvegarde invalide ou trop ancienne" >> "$LOG_FILE" 2&>1
    fi
}

if [ $# -eq 1 ] && [[ " ${DIRECTORIES[@]} " =~ " $1 " ]]; then
    restore_directory_differential "$1"
else
    for dir in "${DIRECTORIES[@]}"; do
        restore_directory_differential "$dir"
    done
    log "Restauration differentielle de tous les repertoires terminee" >> "$LOG_FILE" 2&>1
fi
