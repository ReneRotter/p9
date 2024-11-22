#!/bin/bash
# Definition des variables
SOURCE_DIR="/home/rrotter/emails/"
DEST_USER="save"
DEST_HOST="srv-backup"
DEST_DIR_CUR="/home/save/emails/current"
DEST_DIR_INC="/home/save/emails/incremental"
LOG_FILE="/home/rrotter/logs/backup_inc.log"
DATE=$(date +%Y-%m-%d_%H:%M:%S)
RETENTION_DAYS=30  # Nombre de jours de retention pour les anciennes sauvegardes
# Fonction de journalisation
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}
# Sauvegarde incrementale
log "Debut de la sauvegarde incrementale des emails"
rsync -avvz --delete --backup --backup-dir="$DEST_DIR_INC/$DATE" \
    -e "ssh -i /home/rrotter/.ssh/id_rsa" \
    "$SOURCE_DIR" "$DEST_USER@$DEST_HOST:$DEST_DIR_CUR/" \
    >> "$LOG_FILE" 2>&1
# Verification du statut de rsync
if [ $? -eq 0 ]; then
    log "Sauvegarde incrementale terminee avec succes"
else
    log "Erreur lors de la sauvegarde incrementale"
    exit 1
fi
# Suppression des anciennes sauvegardes
log "Suppression des sauvegardes de plus de $RETENTION_DAYS jours"
ssh -i /home/rrotter/.ssh/id_rsa "$DEST_USER@$DEST_HOST" \
    "find $DEST_DIR_INC/ -type d -name '*' -mtime +$RETENTION_DAYS -exec rm -rf {} +" \
    >> "$LOG_FILE" 2>&1
log "Processus de sauvegarde termine"

