echo "deploy begin....."

TF_CMD=node_modules/.bin/truffle-flattener

echo "" >  ./deployments/MerkleDistributor.full.sol
cat  ./scripts/head.sol >  ./deployments/MerkleDistributor.full.sol
$TF_CMD ./contracts/MerkleDistributor.sol >>  ./deployments/MerkleDistributor.full.sol 

echo "" >  ./deployments/DegoTokenV2.full.sol
cat  ./scripts/head.sol >  ./deployments/DegoTokenV2.full.sol
$TF_CMD ./contracts/dego/DegoTokenV2.sol >>  ./deployments/DegoTokenV2.full.sol 

echo "deploy end....."