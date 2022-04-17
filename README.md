# 🏗 scaffold-ETH - Multisig Wallet Factory

> Create multiple Multisig Wallets from a simple interface + Debug Interface with Multisig Wallet Factory & selected Wallet instance! 🚀

![image](https://user-images.githubusercontent.com/5996795/163723941-a867afd4-c405-492f-91b3-488045eba7f2.png)

# 🏄‍♂️ Quick Start

Prerequisites: [Node (v16 LTS)](https://nodejs.org/en/download/) plus [Yarn](https://classic.yarnpkg.com/en/docs/install/) and [Git](https://git-scm.com/downloads)

> clone/fork 🏗 scaffold-eth: Multisig Wallet Factory

```bash
git clone https://github.com/ldsanchez/multisig-wallet.git
```

> install and start your 👷‍ Hardhat chain:

```bash
cd multisig-wallet
yarn install
yarn chain
```

> in a second terminal window, start your 📱 frontend:

```bash
cd multisig-wallet
yarn start
```

> in a third terminal window, 🛰 deploy your contract:

```bash
cd multisig-wallet
yarn deploy
```

> in a fourth terminal window, 🛰 run your backend:

```bash
cd multisig-wallet
yarn backend
```

🔏 Edit your smart contract `MultisigWalletFactory.sol` & `MultisigWallet.sol` in `packages/hardhat/contracts`

📝 Edit your frontend `App.jsx` & `Home.jsx` in `packages/react-app/src`

💼 Edit your deployment scripts in `packages/hardhat/deploy`

📱 Open http://localhost:3000 to see the app

# Deploy it! 🛰

📡 Edit the defaultNetwork in packages/hardhat/hardhat.config.js, as well as targetNetwork in packages/react-app/src/App.jsx, to your choice of public EVM networks

👩‍🚀 You will want to run yarn account to see if you have a deployer address.

🔐 If you don't have one, run yarn generate to create a mnemonic and save it locally for deploying.

🛰 Use a faucet like faucet.paradigm.xyz to fund your deployer address (run yarn account again to view balances)

🚀 Run yarn deploy to deploy to your public network of choice (😅 wherever you can get ⛽️ gas)

🔬 Inspect the block explorer for the network you deployed to... make sure your contract is there.

# 🚢 Ship it! 🚁

✏️ Edit your frontend App.jsx in packages/react-app/src to change the targetNetwork to wherever you deployed your contract, and also change the BACKEND_URL constant to your deployed backend.

📦 Run yarn build to package up your frontend.

💽 Upload your app to surge with yarn surge (you could also yarn s3 or maybe even yarn ipfs?)

😬 Windows users beware! You may have to change the surge code in packages/react-app/package.json to just "surge": "surge ./build",

⚙ If you get a permissions error yarn surge again until you get a unique URL, or customize it in the command line.

🚔 Traffic to your url might break the Infura rate limit, edit your key: constants.js in packages/ract-app/src.

# 📜 Contract Verification

Update the api-key in packages/hardhat/package.json. You can get your key here.

Now you are ready to run the yarn verify --network your_network command to verify your contracts on etherscan 🛰

# 💌 P.S.

📣 You can use `yarn export-non-deployed` to create the Wallet instance ABI.

🌍 You need an RPC key for testnets and production deployments, create an [Alchemy](https://www.alchemy.com/) account and replace the value of `ALCHEMY_KEY = xxx` in `packages/react-app/src/constants.js` with your new key.

📣 Make sure you update the `InfuraID` before you go to production. Huge thanks to [Infura](https://infura.io/) for our special account that fields 7m req/day!

# Thanks 👏🏻

To https://github.com/dec3ntraliz3d and https://github.com/stevenpslade for their builds.

# 🏃💨 Speedrun Ethereum

Register as a builder [here](https://speedrunethereum.com) and start on some of the challenges and build a portfolio.

# 💬 Support Chat

Join the telegram [support chat 💬](https://t.me/joinchat/KByvmRe5wkR-8F_zz6AjpA) to ask questions and find others building with 🏗 scaffold-eth!

---

🙏 Please check out our [Gitcoin grant](https://gitcoin.co/grants/2851/scaffold-eth) too!

### Automated with Gitpod

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#github.com/scaffold-eth/scaffold-eth)
