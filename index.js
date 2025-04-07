const express = require('express');
const { Web3 } = require('web3');
const { HttpProvider } = require('web3-providers-http');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const app = express();
app.use(express.json());

// Setup Web3 provider
const provider = new HttpProvider(process.env.PROVIDER_URL);
const web3 = new Web3(provider);

// Setup account
const account = web3.eth.accounts.privateKeyToAccount(process.env.PRIVATE_KEY);
web3.eth.accounts.wallet.add(account);
web3.eth.defaultAccount = account.address;

// Load contract ABI
const contractPath = path.join(__dirname, 'contracts', 'HashTimeLock.json');
const abi = JSON.parse(fs.readFileSync(contractPath)).abi;

// Instantiate contract
const contract = new web3.eth.Contract(abi, process.env.CONTRACT_ADDRESS);

// Initiate Swap API
app.post('/api/swap/initiate', async (req, res) => {
  try {
    const { participant, hashlock, timelock, amountEth } = req.body;

    const amountWei = web3.utils.toWei(amountEth.toString(), 'ether');

    const tx = await contract.methods.initiate(participant, hashlock, timelock)
      .send({
        from: account.address,
        value: amountWei,
        gas: 300000
      });

    const swapId = tx.events?.SwapInitiated?.returnValues?.swapId;

    res.json({ success: true, swapId, txHash: tx.transactionHash });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Swap API running at http://localhost:${PORT}`);
});
