#!/bin/bash
# Definition des variables
SOURCE_BASE="/home/rrotter/"
DEST_USER="save"
DEST_HOST="srv-backup"
DEST_BASE="/home/save/vms/"
LOG_FILE="/home/rrotter/logs/backup_dif.log"
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M:%S)
# Fonction de journalisation
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}
# Fonction pour sauvegarde differentielle
differential_backup() {
    local dir=$1
    local SOURCE_DIR="${SOURCE_BASE}${dir}"
    local DEST_DIR="${DEST_BASE}${dir}"
    
    log "Debut de la sauvegarde differentielle pour ${dir}"
    
    # Creation du repertoire de destination si pas existant
    ssh -i /home/rrotter/.ssh/id_rsa "$DEST_USER@$DEST_HOST" "mkdir -p ${DEST_DIR}"
    
    rsync -avvz --stop-at=04:00 --delete --delete-after --bwlimit=20M \
        -e "ssh -i /home/rrotter/.ssh/id_rsa" \
        "${SOURCE_DIR}/" "${DEST_USER}@${DEST_HOST}:${DEST_DIR}/" \
        >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        log "Sauvegarde differentielle de ${dir} terminee avec succes"
    else
        log "Erreur lors de la sauvegarde differentielle de ${dir}"
        return 1
    fi
}
# Liste des repertoires a sauvegarder
directories=("emails" "fichiers" "site" "rh" "tickets")
# Verification de l'heure pour la sauvegarde
if [ "$TIME" \> "00:30:00" ] && [ "$TIME" \< "23:59:00" ]; then
    log "Debut du processus de sauvegarde - dans la plage horaire 01:00-04:00"
    # Sauvegarde differentielle pour chaque repertoire
    for dir in "${directories[@]}"; do
        differential_backup "$dir"
    done
    log "Fin du processus de sauvegarde"
else
    log "Hors plage horaire de sauvegarde (01:00-04:00). Aucune sauvegarde effectuee."
fi