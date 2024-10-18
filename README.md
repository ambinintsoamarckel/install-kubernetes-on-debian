# 🚀 Installing Kubernetes on Debian with CRI-Docker

Installing Kubernetes on Debian can be challenging, especially due to issues with `containerd`. This guide provides a simple way to install it using **CRI-Docker**. 🐳✨

## 📜 Overview

To simplify the installation process, you can execute a provided Bash script that automates the setup of Kubernetes on your Debian system.

### ⚙️ Automated Installation Script

Run the following command to execute the installation script:

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/install-kubernetes-script/main/install-k8s.sh | bash
Note: This script is based on the tutorial from StackThrow and incorporates documentation from Kubernetes and Docker.

# 📋 Prerequisites
Before executing the script, ensure you have the following:

A Debian-based system (Debian 10 or 11 recommended)
Root or sudo access
# 🎉 Completion
After the script completes, you should have a fully functional Kubernetes installation on your Debian system! To verify that your nodes are ready, run:

bash
Copier le code
kubectl get nodes
If everything is set up correctly, your nodes should show as Ready! 🌟

# 📚 Additional Resources
Kubernetes Documentation
Docker Documentation
Happy Kubernetes-ing! If you have any questions, feel free to ask! 🐳✨
