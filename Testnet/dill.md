# launch-dill-node-test #

# Dill Public Testnet (Andes Testnet) Information
| Network Name     | Dill Testnet Andes |
| ------------- | ---------------- |
Rpc URL | https://rpc-andes.dill.xyz/
Chain ID | 558329
Currency Symbol | DILL
Explorer URL | https://andes.dill.xyz/

# Hardware Requirements
| Hardware | Requirement |
| ------------- | ---------------- |
Cpu | 2 Cores
Architecture | x86-64 (x64, x86_64, AMD64, ve Intel 64)
Memory | 2 GB
Operating System | Ubuntu 20.04+ / MacOS
Storage | 20 GB
Network Bandwidth | 1MB/s 

# Instructions

## Run a light validator
Light validator is a type of node that performs availability validation solely through data sampling without participating in data sharding synchronization. It is also part of a consensus network. These nodes can participate in voting but will not act as proposers to generate new blocks. You can follow the steps below to start a light validator:


**Download and run the setup script:**

Open your terminal and execute the following command to download and run the script:

   ```sh
   curl -sO https://raw.githubusercontent.com/DillLabs/launch-dill-node/main/launch_dill_node.sh  && chmod +x launch_dill_node.sh && ./launch_dill_node.sh
   ```

If the dill node launched successfully, you will get an output similar to this:

```
node running, congratulations 😄
validator pubkey: xxxxxx
Please backup $YOUR_SCRIPT_PATH/dill/validator_keys/mnemonic-$TIMESTAMP.txt. Required for recovery and migration. Important ！！！
```
------

## Staking
- First, get faucet into your wallet from the Andes channel. Use a different wallet than the one you created in Node and remember that you can only receive faucet once ($request xxxxx)

- visit https://staking.dill.xyz/

![image](/pics/dill/staking_upload.png)

- Here you will upload your file with deposit_data-xxxx.json extension. If you want, you can create this file yourself. To do this, you can create and upload a file named deposit_data-xxxx.json with the output you receive using this code.
```
cat ./dill/validator_keys/deposit_data-xxxx.json
```

- After uploading the deposit_data-xxxx.json file to the site, click Connect to MetaMask, make sure you have enough funds (>2500 DILL)

![image](/pics/dill/staking_connect_wallet.png)

- Send deposit, using MetaMask to send a deposit transaction

![image](/pics/dill/staking_transaction.png)

- Yes, that's all. After these operations, you can check it with your public key in the validators section in Explorer https://andes.dill.xyz/validators. It may take 0.5~1 hour to appear.
![image](/pics/dill/validator_search.png)

------

# Acknowledgements
>- [dill-light-validator-setup](https://github.com/99kartlos/dill-light-validator-setup):  The writing style and script implementation in this repository inspired me a lot
>
