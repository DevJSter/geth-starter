geth --datadir "./data" account new

geth --datadir "./data" init genesis.json

# Bnode
bootnode -nodekey boot.key -verbosity 7 -addr "127.0.0.1:30301"

# node1 

geth --datadir "./data" init genesis.json

geth --datadir "./data" --port 30304 --bootnodes "enode://7c8ae5080a4e655b82868853abf24164dc62a13f16118ae0e9a6d6446fa5013e7e7809912474057836628804837380549d680b29f26b350c1350dad385e2b538@127.0.0.1:0?discport=30301" --authrpc.port 8547 --ipcdisable --allow-insecure-unlock --http --http.addr "0.0.0.0" --http.port 8545 --http.corsdomain "https://remix.ethereum.org" --http.api "eth,net,web3,personal,debug,txpool,miner" --networkid 93233 --unlock 0x593A224868c34a1Ea6D7723875C8a9d6B890cA16 --password password.txt --mine --miner.etherbase=0x593A224868c34a1Ea6D7723875C8a9d6B890cA16


# For node2

geth --datadir "./data" init genesis.json    

geth --datadir "./data" --port 30305 --bootnodes "enode://7c8ae5080a4e655b82868853abf24164dc62a13f16118ae0e9a6d6446fa5013e7e7809912474057836628804837380549d680b29f26b350c1350dad385e2b538@127.0.0.1:0?discport=30301" --authrpc.port 8548 --ipcdisable --allow-insecure-unlock --http --http.addr "0.0.0.0" --http.port 8546 --http.corsdomain "https://remix.ethereum.org" --http.api "eth,net,web3,personal,debug,txpool,miner" --networkid 93233 --unlock 0xA84844AAb3839e61E732fE409462cf24a8B9D9ac --password password.txt --mine --miner.etherbase=0xA84844AAb3839e61E732fE409462cf24a8B9D9ac