import { RpcProvider, Account, Contract, json, CallData } from 'starknet';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import 'dotenv/config';

async function main() {
  // 1. --- Connect to Starknet Provider ---
  const provider = new RpcProvider({ nodeUrl: 'https://starknet-sepolia.public.blastapi.io/rpc/v0_8' });

  // 2. --- Connect to your Account ---
  const privateKey = process.env.STARKNET_PRIVATE_KEY;
  const accountAddress = process.env.STARKNET_ACCOUNT_ADDRESS;
  const account = new Account(provider, accountAddress, privateKey);
  console.log('Connected to account:', account.address);

  // 3. --- Load Compiled Contract Artifacts ---
  const compiledSierra = json.parse(
    fs.readFileSync('../target/dev/inheritx_contracts_InheritXOperations.contract_class.json').toString('ascii')
  );
  const compiledCasm = json.parse(
    fs.readFileSync('../target/dev/inheritx_contracts_InheritXOperations.compiled_contract_class.json').toString('ascii')
  );

  // 4. --- Prepare Constructor Arguments ---
  const admin = process.env.ADMIN_ADDRESS;
  const dexRouter = process.env.DEX_ROUTER_ADDRESS || "0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
  const emergencyWithdrawAddress = process.env.EMERGENCY_WITHDRAW_ADDRESS || admin;
  const strkToken = "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d";
  const usdtToken = "0x056789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123";
  const usdcToken = "0x0789abcdef0123456789abcdef0123456789abcdef0123456789abcdef012345";

  // Read Core Plans contract address from deployment file
  let corePlansAddress = "0x0"; // Default fallback
  try {
    const corePlansDeployment = JSON.parse(fs.readFileSync('core_plans_deployment.json', 'utf8'));
    corePlansAddress = corePlansDeployment.contractAddress;
    console.log('Using Core Plans address:', corePlansAddress);
  } catch (error) {
    console.warn('Could not read Core Plans deployment file, using default address');
  }

  const myCallData = new CallData(compiledSierra.abi);
  const constructorArgs = myCallData.compile('constructor', {
    admin,
    dex_router: dexRouter,
    emergency_withdraw_address: emergencyWithdrawAddress,
    core_contract: corePlansAddress,
    strk_token: strkToken,
    usdt_token: usdtToken,
    usdc_token: usdcToken
  });

  console.log('Constructor Arguments:', constructorArgs);

  // 5. --- Declare and Deploy the Contract ---
  console.log('Declaring and deploying InheritXOperations contract...');
  try {
    const deployResponse = await account.declareAndDeploy({
      contract: compiledSierra,
      casm: compiledCasm,
      constructorCalldata: constructorArgs,
    });

    console.log('Contract declared with class hash:', deployResponse.declare.class_hash);
    console.log('Contract deployed at address:', deployResponse.deploy.contract_address);

    // 6. --- Connect to the Deployed Contract ---
    const myContract = new Contract(
      compiledSierra.abi,
      deployResponse.deploy.contract_address,
      provider
    );

    console.log('✅ InheritXOperations contract connected successfully!');

    // 7. --- Write deployment summary ---
    const summary = {
      network: process.env.STARKNET_NETWORK || 'sepolia',
      account: account.address,
      contractName: 'InheritXOperations',
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
    const outPath = path.join(__dirname, 'core_operations_deployment.json');
    try {
      fs.writeFileSync(outPath, JSON.stringify(summary, null, 2));
      console.log('Saved deployment summary to', outPath);
    } catch (e) {
      console.warn('Could not write core_operations_deployment.json:', e);
    }

    // 8. --- Test basic functionality ---
    console.log('\n--- Testing Operations Contract ---');
    try {
      // Test admin getter if available
      if (myContract.get_admin) {
        const adminResult = await myContract.get_admin();
        console.log('Admin address:', adminResult.toString());
        
        // Test if admin matches expected
        if (adminResult.toString() === admin) {
          console.log('✅ Admin address correctly set');
        } else {
          console.log('❌ Admin address mismatch');
        }
      } else {
        console.log('ℹ️  Admin getter not available in contract interface');
      }
      
    } catch (error) {
      console.log('⚠️  Could not test contract functionality:', error.message);
    }

  } catch (error) {
    console.error('Deployment failed:', error);
    process.exit(1);
  }
}

main().catch(console.error);