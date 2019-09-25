pragma solidity ^0.5.4;

// ----------------------------------------------------------------------------
// Dream Frames White List
//
// Deployed to:
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd for GazeCoin 2018. The MIT Licence.
// (c) Adrian Guerrera / Deepyr Pty Ltd for Dream Frames 2019. The MIT Licence.
// ----------------------------------------------------------------------------

import "./RegistryInterface.sol";


// ----------------------------------------------------------------------------
// White List - on list or not
// ----------------------------------------------------------------------------
contract VoterRegistry is RegistryInterface {
    mapping(address => bool) public registry;

    event AccountListed(address indexed account, bool status);

    function isInRegistry(address account) public view returns (bool) {
        return registry[account];
    }

    function add(address[] memory accounts) public  {
        require(accounts.length != 0);
        for (uint i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0));
            if (!registry[accounts[i]]) {
                registry[accounts[i]] = true;
                emit AccountListed(accounts[i], true);
            }
        }
    }
    function remove(address[] memory accounts) public  {
        require(accounts.length != 0);
        for (uint i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0));
            if (registry[accounts[i]]) {
                delete registry[accounts[i]];
                emit AccountListed(accounts[i], false);
            }
        }
    }
}
