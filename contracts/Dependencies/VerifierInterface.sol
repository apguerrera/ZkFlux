pragma solidity ^0.5.4;

interface VerifierInterface {
  function verifyProof(uint[2] calldata, uint[2][2] calldata, uint[2] calldata, uint[12] calldata) external view returns (bool);
}
