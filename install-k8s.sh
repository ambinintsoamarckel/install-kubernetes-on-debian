#!/bin/bash

LOGFILE="installation.log"

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

# Arrêter le script en cas d'erreur et enregistrer dans le log
set -e
trap "log 'Une erreur s'est produite. Arrêt du script.'; exit 1" ERR

# Vérification de la connexion Internet
log "Vérification de la connexion Internet"
if ! ping -c 1 google.com &> /dev/null; then
  log "ERREUR : Pas de connexion Internet. Arrêt du script."
  exit 1
fi

log "Mise à jour des paquets"
sudo apt-get update

log "Installation des certificats et de curl"
sudo apt-get install -y ca-certificates curl

log "Création du répertoire /etc/apt/keyrings s'il n'existe pas"
if [ ! -d /etc/apt/keyrings ]; then
  sudo install -m 0755 -d /etc/apt/keyrings
else
  log "Le répertoire /etc/apt/keyrings existe déjà"
fi

log "Téléchargement de la clé GPG officielle de Docker"
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

log "Ajout du dépôt Docker aux sources APT"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

log "Mise à jour des paquets après ajout du dépôt Docker"
sudo apt-get update

log "Installation des paquets Docker"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

log "Téléchargement de CRI-Docker"
curl -LO https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.15/cri-dockerd_0.3.15.3-0.debian-bookworm_amd64.deb

log "Installation de CRI-Docker"
sudo apt install -y ./cri-dockerd_0.3.15.3-0.debian-bookworm_amd64.deb

log "Suppression du fichier téléchargé CRI-Docker"
rm -f cri-dockerd_0.3.15.3-0.debian-bookworm_amd64.deb

log "Désactivation de l'échange de mémoire (swap)"
sudo swapoff -a

log "Installation des paquets nécessaires pour Kubernetes"
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

log "Création du répertoire /etc/apt/keyrings pour Kubernetes s'il n'existe pas"
if [ ! -d /etc/apt/keyrings ]; then
  sudo mkdir -p -m 755 /etc/apt/keyrings
else
  log "Le répertoire /etc/apt/keyrings existe déjà pour Kubernetes"
fi

log "Téléchargement de la clé GPG de Kubernetes"
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

log "Ajout du dépôt Kubernetes aux sources APT"
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

log "Mise à jour des paquets après ajout du dépôt Kubernetes"
sudo apt-get update

log "Installation de kubelet, kubeadm, et kubectl"
sudo apt-get install -y kubelet kubeadm kubectl

log "Marquage des paquets Kubernetes comme étant bloqués (pour éviter les mises à jour automatiques)"
sudo apt-mark hold kubelet kubeadm kubectl

log "Activation de kubelet"
sudo systemctl enable --now kubelet

log "Initialisation du cluster Kubernetes"
if ! kubeadm init --pod-network-cidr=172.168.0.0/16 --cri-socket=unix:///var/run/cri-dockerd.sock; then
  log "ERREUR : L'initialisation de kubeadm a échoué. Vérifiez la configuration."
  exit 1
fi

log "Configuration de l'accès à Kubernetes pour l'utilisateur"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

log "Installation de Calico"
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/tigera-operator.yaml

log "Attente de 10 secondes pour l'installation de Calico..."
sleep 10

log "Installation des ressources personnalisées de Calico"
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/custom-resources.yaml

log "Vous pouvez surveiller les pods avec : watch kubectl get pods -n calico-system"

log "Suppression des taints sur les nœuds master"
kubectl taint nodes --all node-role.kubernetes.io/control-plane- node-role.kubernetes.io/master-

log "Installation terminée avec succès"
