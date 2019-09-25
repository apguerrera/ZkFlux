#!/bin/sh

cd circuits

circom circuit.circom -o circuit.json
snarkjs setup --protocol groth
#snarkjs setup -c circuit.json --pk proving_key.json --vk verification_key.json --protocol groth
snarkjs calculatewitness
#snarkjs calculatewitness -c circuit.json  -i input.json -w witness.json
snarkjs proof
#snarkjs proof -w witness.json --pk proving_key.json --pub public.json --proof=proof.json
snarkjs verify
#snarkjs verify --vk verification_key.json --proof proof.json --pub public.json
snarkjs generateverifier
#snarkjs generateverifier --vk verification_key.json --verifier verifier.sol
snarkjs generatecall > generate_call.txt
# snarkjs generatecall --proof proof.json --pub pub.json
mv verifier.sol ../contracts/Dependencies/.
