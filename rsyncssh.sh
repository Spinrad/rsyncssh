#!/bin/bash
#
# Script de backup incrémental avec rsync
# Dépendances : rsync, ssh, mail
#
# Configuration
PREFIX="HostSource"
NAS="HostDest"
DEST="/home/user/mybackup"
SOURCE="user@server:/folder_to_backup/"
DATE="$(date '+%F_%H-%M')"
MAIL="user@mail.org"

# Vérification des dépendances
for cmd in rsync mail ssh; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "$PREFIX Erreur: $cmd n'est pas installé. Abandon."
        exit 1
    fi
done

# Vérification de la connexion SSH
if ! ssh -q -o BatchMode=yes -o ConnectTimeout=5 "$SOURCE" exit; then
    echo "$PREFIX Erreur: Impossible de se connecter à $SOURCE."
    exit 1
fi

# Vérification du dossier de destination
if [ ! -d "$DEST" ]; then
    echo "$PREFIX Erreur: Dossier de destination "$DEST" introuvable. Abandon."
    exit 1
fi

cd "$DEST" || exit 1

# Rotation des sauvegardes
echo "$PREFIX Rotation des anciennes sauvegardes..."
rm -rf backup.5
for i in {4..1}; do
    if [ -d "backup.$i" ]; then
        mv "backup.$i" "backup.$((i+1))"
    fi
done
mv backup current 2>/dev/null

echo "$PREFIX Début du backup..."

# Exécution de rsync avec gestion des erreurs
if rsync -v -a --delete --log-file="$DEST/$PREFIX-$DATE.log" --link-dest="../backup/" "$SOURCE" "$DEST/current"; then
    echo "$PREFIX Backup terminé avec succès."
    STATUS="OK"
else
    echo "$PREFIX Erreur: échec du backup."
    STATUS="ÉCHEC"
fi

# Envoi d'une notification par mail
if echo "$DATE - Backup rsync $PREFIX $SOURCE vers $NAS@$DEST : $STATUS" | mail -s "Daily backup rsync $PREFIX vers $NAS : $STATUS" "$MAIL"; then
    echo "$PREFIX Notification envoyée."
else
    echo "$PREFIX Erreur: Impossible d'envoyer le mail."
fi
