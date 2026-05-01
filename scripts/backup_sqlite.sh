#!/usr/bin/env bash

set -e

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DB_FILE="$APP_DIR/db/fluxo_clinicas.sqlite3"
BACKUP_DIR="$APP_DIR/backups"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="$BACKUP_DIR/fluxo_clinicas-$TIMESTAMP.sqlite3"

mkdir -p "$BACKUP_DIR"

if [ ! -f "$DB_FILE" ]; then
  echo "Banco SQLite não encontrado em: $DB_FILE"
  exit 1
fi

cp "$DB_FILE" "$BACKUP_FILE"

echo "Backup criado com sucesso:"
echo "$BACKUP_FILE"
