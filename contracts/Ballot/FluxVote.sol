pragma solidity ^0.5.4;

import "../Dependencies/Members.sol";
import "../Dependencies/VerifierInterface.sol";
import "../Dependencies/MiMCInterface.sol";
import "../Shared/Owned.sol";
import "../Shared/Operated.sol";



contract FluxVote is Owned {   // should be operated
    using Members for Members.Data;

    MiMCInterface public mimc;             // not public
    VerifierInterface public verifier;     // not public
    Members.Data public members;  // not public

    struct Vote {
        bytes message;
        uint256 timestamp;
    }
    mapping(bytes32 => Vote) public votes;
    bytes32[] public votesIndex;

    string description;
    // uint256 startDate;
    // uint256 endDate;

    bool public open;
    uint public initiated;
    uint public closed;  // should be end??

    event Voted(bytes32 key);
    // Must be copied here to be added to the ABI
    event MemberAdded(address indexed memberAddress, string name, uint totalAfter);
    event MemberRemoved(address indexed memberAddress, string name, uint totalAfter);
    event MemberNameUpdated(address indexed memberAddress, string oldName, string newName);

    constructor () public {
      initOwned(msg.sender);
      members.init();
      open = true;
      initiated = now;
      closed = 0;
    }

    // Owner functions
    function setMiMC(address _mimc) public onlyOwner {
      mimc = MiMCInterface(_mimc);
    }
    function setVerifier(address _verifier) public onlyOwner {
      verifier = VerifierInterface(_verifier);
    }

    // Member functions
    function addMember(address _address, string memory _name) public onlyOwner {
        members.add(_address, _name);
    }
    function removeMember(address _address) public onlyOwner  {
        members.remove(_address);
    }
    function setMemberName(string memory memberName) public {
        members.setName(msg.sender, memberName);
    }
    function numberOfMembers() public view returns (uint) {
        return members.length();
    }
    function getMembers() public view returns (address[] memory) {
        return members.index;
    }
    function getMemberData(address _address) public view returns (bool _exists, uint _index, string memory _name) {
        Members.Member memory member = members.entries[_address];
        return (member.exists, member.index, member.name);
    }
    function getMemberByIndex(uint _index) public view returns (address _member) {
        return members.index[_index];
    }

    // Voting functions
    function voteKey(bytes memory _message) internal pure returns (bytes32) {
        // return sha256( _message);    // salted?
        return keccak256(abi.encodePacked( _message));   // changed to MiMC?
    }
    function vote (/* uint256 ballotId,*/  bytes memory message) public {
      require(open);
      // add message to registry
      bytes32 key = voteKey(message);
      votes[key] = Vote(message, now);
      votesIndex.push(key);  // not sure if this is correct
      emit Voted(key);
    }
    function votesIndexLength() public view returns (uint) {
        return votesIndex.length;
    }

    // is this just the same as voting? should be for greater annomity
    function changeKey (/* uint256 ballotId,*/ bytes memory message) public {
    }
    function verifyVote (string memory zkproof, bytes32 key) public {
    }
    function submitResults (string memory zkproof ,/* uint256 ballotId,*/ bool result) public onlyOwner  {  // should be operators
    }

 }
