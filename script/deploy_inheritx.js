import { RpcProvider, Account, Contract, json, CallData } from 'starknet';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import 'dotenv/config';

async function main() {
  // 1. --- Connect to Starknet Provider ---
  const provider = new RpcProvider({ nodeUrl: process.env.SEPOLIA_NODE_URL });

  // 2. --- Connect to your Account ---
  const privateKey = process.env.STARKNET_PRIVATE_KEY;
  const accountAddress = process.env.STARKNET_ACCOUNT_ADDRESS;
  const account = new Account(provider, accountAddress, privateKey);
  console.log('Connected to account:', account.address);

  // 3. --- Load Compiled Contract Artifacts ---
  const compiledInheritXSierra = json.parse(
    fs.readFileSync('../target/dev/inheritx_contracts_InheritX.contract_class.json').toString('ascii')
  );
  const compiledInheritXCasm = json.parse(
    fs.readFileSync('../target/dev/inheritx_contracts_InheritX.compiled_contract_class.json').toString('ascii')
  );

  // 4. --- Prepare Constructor Arguments ---
  const admin = process.env.ADMIN_ADDRESS;
  const dex_router = process.env.DEX_ROUTER_ADDRESS;
  const emergency_withdraw_address = process.env.EMERGENCY_WITHDRAW_ADDRESS;
  const strk_token = process.env.STRK_TOKEN_ADDRESS;
  const usdt_token = process.env.USDT_TOKEN_ADDRESS;
  const usdc_token = process.env.USDC_TOKEN_ADDRESS;

  const myCallData = new CallData(compiledInheritXSierra.abi);
  const constructorArgs = myCallData.compile('constructor', {
    admin,
    dex_router,
    emergency_withdraw_address,
    strk_token,
    usdt_token,
    usdc_token,
  });

  console.log('Constructor Arguments:', constructorArgs);

  // 5. --- Declare and Deploy the Contract ---
  console.log('Declaring and deploying InheritX contract...');
  try {
    const deployResponse = await account.declareAndDeploy({
      contract: compiledInheritXSierra,
      casm: compiledInheritXCasm,
      constructorCalldata: constructorArgs,
    });

    console.log('Contract declared with class hash:', deployResponse.declare.class_hash);
    console.log('Contract deployed at address:', deployResponse.deploy.contract_address);

    // 6. --- Connect to the Deployed Contract ---
    const myContract = new Contract(
      compiledInheritXSierra.abi,
      deployResponse.deploy.contract_address,
      provider
    );

    console.log('✅ InheritX contract connected successfully!');

    // 7. --- Write deployment summary ---
    const summary = {
      network: process.env.STARKNET_NETWORK || 'sepolia',
      account: account.address,
      contractName: 'InheritX',
      classHash: deployResponse.declare.class_hash,
      contractAddress: deployResponse.deploy.contract_address,
      tx: {
        declare: deployResponse.declare.transaction_hash,
        deploy: deployResponse.deploy.transaction_hash,
      },
      constructorArgs,
      timestamp: new Date().toISOString(),
    };

    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);
    const outPath = path.join(__dirname, 'deployment.json');
    try {
      fs.writeFileSync(outPath, JSON.stringify(summary, null, 2));
      console.log('Saved deployment summary to', outPath);
    } catch (e) {
      console.warn('Could not write deployment.json:', e);
    }

  } catch (error) {
    console.error('Deployment failed:', error);
  }
}

main().catch(console.error);
