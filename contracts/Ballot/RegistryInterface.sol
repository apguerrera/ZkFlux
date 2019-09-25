pragma solidity ^0.5.4;

// ----------------------------------------------------------------------------
// Bonus List interface
// ----------------------------------------------------------------------------
contract RegistryInterface {
    function isInRegistry(address account) public view returns (bool);
}
