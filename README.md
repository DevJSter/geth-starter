# Building a Private Ethereum PoA Network with Geth 1.13.14

This guide walks you through setting up a private Ethereum network using Proof of Authority (PoA) consensus with Go Ethereum (Geth) 1.13.14. Perfect for developers looking to experiment with blockchain technology or create a controlled environment for testing smart contracts.

## Prerequisites

- Go Language (v1.22.0 or later)
- Go Ethereum (Geth v1.13.14-stable)
- Your preferred code editor (VSCode recommended)

## Installation

### Installing Go
```bash
# For Ubuntu/Debian
sudo apt-get update
sudo apt-get install golang-go

# Verify installation
go version
```

### Installing Geth
```bash
# For Ubuntu/Debian
sudo add-apt-repository -y ppa:ethereum/ethereum
sudo apt-get update
sudo apt-get install ethereum

# Verify installation
geth version
```

## Setting Up Your Private Network

### 1. Create Project Structure
```bash
# Create main project directory
mkdir ethereum-poa-network
cd ethereum-poa-network

# Create folders for each node and bootnode
mkdir node1 node2 bnode

# Create info file to track account details
touch info.txt
```

### 2. Create Accounts for Your Nodes
```bash
# Navigate to the first node directory
cd node1

# Create new account
geth --datadir "./data" account new
# Save the address and password in info.txt

# Navigate to the second node directory
cd ../node2

# Create new account
geth --datadir "./data" account new
# Save the address and password in info.txt
```

### 3. Create Configuration File
Create a file named `privateblock.json` in the project root with the following content:

```json
{
  "config": {
    "chainId": 1234567,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "berlinBlock": 0,
    "clique": {
      "period": 5,
      "epoch": 30000
    }
  },
  "difficulty": "1",
  "gasLimit": "8000000",
  "extradata": "0x0000000000000000000000000000000000000000000000000000000000000000NODE1_ADDRESS_WITHOUT_0X0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "alloc": {
    "NODE1_ADDRESS_WITHOUT_0X": {
      "balance": "3000000000000000000000000000000000000"
    },
    "NODE2_ADDRESS_WITHOUT_0X": {
      "balance": "3000000000000000000000000000000000000"
    }
  }
}
```

Replace `NODE1_ADDRESS_WITHOUT_0X` and `NODE2_ADDRESS_WITHOUT_0X` with your node account addresses (remove the leading "0x").

### 4. Initialize Nodes with Genesis Block
```bash
# Initialize node1
cd node1
geth --datadir ./data init ../privateblock.json

# Initialize node2
cd ../node2
geth --datadir ./data init ../privateblock.json
```

### 5. Set Up Bootnode
```bash
# Navigate to bootnode directory
cd ../bnode

# Generate bootnode key
bootnode -genkey boot.key

# Start the bootnode
bootnode -nodekey boot.key -verbosity 7 -addr "127.0.0.1:30301"
```

Save the enode URL that appears in the terminal to your `info.txt` file.

### 6. Create Password Files
Create a `password.txt` file in each node directory containing only the password for that node's account.

```bash
# For node1
echo "your_node1_password" > node1/password.txt

# For node2
echo "your_node2_password" > node2/password.txt
```

### 7. Start the Signer Node (Node1)
```bash
cd node1
geth --datadir "./data" --port 30304 --bootnodes "BOOTNODE_ENODE_URL" --authrpc.port 8547 --ipcdisable --allow-insecure-unlock --http --http.corsdomain="https://remix.ethereum.org" --http.api web3,eth,debug,personal,net --networkid 1234567 --unlock "NODE1_ADDRESS" --password password.txt --mine --miner.etherbase="NODE1_ADDRESS"
```

Replace:
- `BOOTNODE_ENODE_URL` with your bootnode's enode URL
- `NODE1_ADDRESS` with your first node's account address (with 0x prefix)

### 8. Start the Second Node (Node2)
Open a new terminal window and run:

```bash
cd node2
geth --datadir "./data" --port 30306 --bootnodes "BOOTNODE_ENODE_URL" --authrpc.port 8546 --ipcdisable --http --http.port 8546 --http.corsdomain="https://remix.ethereum.org" --http.api web3,eth,debug,personal,net --networkid 1234567 --unlock "NODE2_ADDRESS" --password password.txt
```

Replace:
- `BOOTNODE_ENODE_URL` with your bootnode's enode URL
- `NODE2_ADDRESS` with your second node's account address (with 0x prefix)

## Connecting to Your Network

### Using Remix IDE
1. Open [Remix IDE](https://remix.ethereum.org)
2. Go to the "Deploy & Run Transactions" tab
3. In the Environment dropdown, select "Custom - External HTTP Provider"
4. Enter `http://127.0.0.1:8545` (for node1) or `http://127.0.0.1:8546` (for node2)
5. Click "OK"

You can now deploy and interact with smart contracts on your private network.

### Using Web3.js or ethers.js
Connect to your private network using the JSON-RPC endpoint:
- Node1: `http://127.0.0.1:8545`
- Node2: `http://127.0.0.1:8546`

## Troubleshooting

### Port Conflicts
If you see an error like "listen tcp :30304: bind: Only one usage of each socket address is normally permitted", change the port numbers to avoid conflicts.

### Account Unlock Issues
If you encounter "Failed to unlock account" errors, verify:
- The account exists in the keystore directory
- The password in password.txt is correct
- You're using the right account address

### Network Synchronization
If nodes aren't connecting:
- Verify bootnode is running
- Check if the enode URL is correct
- Ensure the chainId/networkid matches between nodes

## Advanced Configuration

### Adding Custom CORS Domains
To allow access from custom domains or local development servers:

```bash
--http.corsdomain="https://remix.ethereum.org,http://127.0.0.1:8000,http://localhost:3000"
```

### Monitoring Your Network
You can attach a JavaScript console to a running node:

```bash
geth attach http://127.0.0.1:8545
```

Inside the console, check peer connections:
```javascript
net.peerCount
admin.peers
```

## Resources

- [Go Ethereum Documentation](https://geth.ethereum.org/docs/)
- [Clique PoA Consensus Explanation](https://github.com/ethereum/EIPs/issues/225)
- [Remix IDE](https://remix.ethereum.org/)