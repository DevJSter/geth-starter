# Running a Private Ethereum Network with Kurtosis on Windows

This guide explains how to set up a private Ethereum Proof-of-Stake network on Windows using Kurtosis.

## Prerequisites

- Windows 10/11
- Administrator access
- At least 8GB RAM (16GB recommended)
- 50GB free disk space

## Installation Steps

### 1. Install Docker Desktop

1. Download [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
2. Run the installer
3. Ensure WSL 2 is enabled during installation
4. Start Docker Desktop after installation
5. Verify Docker is running:
   ```powershell
   docker --version
   ```

### 2. Install Kurtosis

1. Open PowerShell as Administrator
2. Run:
   ```powershell
   iwr https://raw.githubusercontent.com/kurtosis-tech/kurtosis/main/install.ps1 -useb | iex
   ```
3. Verify installation:
   ```powershell
   kurtosis --version
   ```

### 3. Create Network Configuration

1. Create a project directory:
   ```powershell
   mkdir eth-private
   cd eth-private
   ```

2. Create a file named `network_params.yaml` with the following content:
   ```yaml
   participants:
     - el_type: geth
       cl_type: lighthouse
       count: 2
     - el_type: geth
       cl_type: teku
   network_params:
     network_id: "585858"
   additional_services:
     - dora
   ```

## Running the Network

1. Ensure Docker Desktop is running
2. Open PowerShell and navigate to your project directory:
   ```powershell
   cd eth-private
   ```
3. Launch the network:
   ```powershell
   kurtosis run github.com/ethpandaops/ethereum-package --args-file ./network_params.yaml --image-download always
   ```
4. Wait for setup to complete (5-15 minutes on first run)
5. Note the enclave name in the output (e.g., "dusty-soil")

## Interacting with Your Network

### Access Block Explorer

1. Find the Dora service port in the Kurtosis output:
   ```
   dora    http: 8080/tcp -> http://127.0.0.1:[PORT]    RUNNING
   ```
2. Open your browser and navigate to `http://127.0.0.1:[PORT]`

### Using JSON-RPC

Find the RPC port for a Geth node in the output:
```
el-1-geth-lighthouse    rpc: 8545/tcp -> http://127.0.0.1:[PORT]    RUNNING
```

Test with a query:
```powershell
Invoke-RestMethod -Method Post -ContentType "application/json" -Body '{"method":"eth_blockNumber","params":[],"id":1,"jsonrpc":"2.0"}' -Uri "http://127.0.0.1:[PORT]"
```

### Access Geth Console

```powershell
kurtosis service shell [ENCLAVE-NAME] el-1-geth-lighthouse
```

Then inside the container:
```bash
geth --datadir /data/geth/execution-data/ attach
```

### View Logs

```powershell
kurtosis service logs [ENCLAVE-NAME] el-1-geth-lighthouse
```

## Common JavaScript Console Commands

Once in the Geth JavaScript console, use these commands:

```javascript
// Get current block number
eth.blockNumber

// Get network ID
net.version

// Check peer count
net.peerCount

// List accounts
eth.accounts

// Get account balance (in wei)
eth.getBalance("0xYourAccountAddress")

// Get account balance (in ether)
web3.fromWei(eth.getBalance("0xYourAccountAddress"), "ether")

// Exit the console
exit
```

## Stopping the Network

When finished, clean up:
```powershell
kurtosis enclave rm [ENCLAVE-NAME]
```

## Troubleshooting

### Docker Issues
- If Docker fails to start, try restarting your computer
- Check Windows Services to ensure Docker services are running
- In Docker Desktop Settings, ensure WSL 2 is selected

### Network Issues
- If network creation fails, try increasing Docker's memory allocation
- Check Docker Desktop Settings → Resources → Memory (allocate at least 4GB)
- Ensure ports are not already in use by other applications

### Container Access Issues
- If you can't connect to services, check Windows Firewall settings
- Ensure Docker Desktop has permission to create and manage containers

## Advanced Configuration

For more advanced configurations and options, see:
- [Kurtosis Ethereum Package Documentation](https://github.com/ethpandaops/ethereum-package)
- [Kurtosis Documentation](https://docs.kurtosis.com/)