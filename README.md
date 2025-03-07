# 🌐 Intellix Network Configuration

Welcome to the **Intellix Network Configuration Repository**. This repository serves as a centralized hub for managing all configuration parameters essential for the Intellix network.

## 📂 Directory Structure

### 🗂️ Node Configuration Files

This directory contains the core configuration files required for setting up and operating an Intellix node:

- **`app.toml`** - Application-specific settings for node operation.  
- **`client.toml`** - Client-side configuration parameters.  
- **`config.toml`** - Core node settings, including consensus and networking options.  
- **`genesis.json`** - The network genesis file, defining initial state and parameters.  

### 🌐 Network Services

Configuration files related to various network services:

- **`rpc_node`** - Public RPC node details, including:  
  - Available endpoints  
  - Rate limits  
  - Supported APIs  

- **`state_sync_node`** - Public State Sync node details, covering:  
  - Snapshot intervals  
  - Retention policies  
  - Connection configurations  

### 📄 Contract Information

Contains key details related to system contracts on Intellix:

- **`system_contract`** - Information about system contracts, including:  
  - Contract addresses  
  - ABI (Application Binary Interface) specifications  
  - Deployment metadata  

## 🔧 Usage

To apply these configurations to your node, follow these steps:

1. **Clone** this repository:  
```sh
git clone https://github.com/your-org/intellix-network-config.git
```

2. Copy the necessary configuration files to your node’s configuration directory.

3. Modify the relevant parameters according to your node type and network role.

4. Restart your node to apply the changes.