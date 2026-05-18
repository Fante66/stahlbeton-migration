#!/bin/bash
# Bricht das Skript sofort ab, falls ein Befehl nicht funktioniert
set -e

# --- Variablen festlegen ---
KENNUNG="sm0810"
RG_NAME="rg_Steffen_Mueller" # Deine bereits bestehende Sammelmappe
LOCATION="northeurope"
ACR_NAME="acrstahlbeton$KENNUNG"
AKS_NAME="aks-stahlbeton-$KENNUNG"

echo "=== Starte Aufbau der Technik (Plan B - Bestehende Sammelmappe) ==="

# 1. Bilderspeicher (Azure Container Registry) erstellen
# Wir schalten hier den Admin-Zugang ein, um später ohne komplizierte Rollen Bilder abzurufen
echo "1. Erstelle Bilderspeicher mit Admin-Zugang: $ACR_NAME in Sammelmappe $RG_NAME..."
az acr create \
  --resource-group $RG_NAME \
  --name $ACR_NAME \
  --sku Basic \
  --admin-enabled true \
  --location $LOCATION \
  --output table

# 2. Haupt-Computer (AKS-Cluster) erstellen
# Wir aktivieren direkt die Sicherheits-Regeln (Calico), die wir für die Datenbank brauchen
echo "2. Erstelle Haupt-Computer mit Sicherheits-Regelwerk..."
az aks create \
  --resource-group $RG_NAME \
  --name $AKS_NAME \
  --node-count 1 \
  --generate-ssh-keys \
  --network-plugin kubenet \
  --network-policy calico \
  --location $LOCATION \
  --output table

# 3. Günstige Zusatz-Computer (Spot-Instanzen) hinzufügen
echo "3. Füge günstige Zusatz-Computer hinzu..."
az aks nodepool add \
  --resource-group $RG_NAME \
  --cluster-name $AKS_NAME \
  --name spotpool \
  --priority Spot \
  --eviction-policy Delete \
  --spot-max-price -1 \
  --node-count 1 \
  --output table

echo "=== Aufbau erfolgreich abgeschlossen! ==="
echo "Genutzte Sammelmappe: $RG_NAME"
echo "Dein Bilderspeicher: $ACR_NAME"
echo "Deine Computer-Gruppe: $AKS_NAME"
echo "Um dich damit zu verbinden, tippe folgendes ein:"
echo "az aks get-credentials --resource-group $RG_NAME --name $AKS_NAME --overwrite-existing"