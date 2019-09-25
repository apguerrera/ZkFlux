
pragma solidity ^0.5.4;


import "./Dependencies/Verifier.sol";
import "./Dependencies/MerkleTree.sol";
import "./Shared/Owned.sol";
import "./Shared/Operated.sol";

// Sample interfaces
contract MiMC{
    function MiMCpe7(uint256,uint256,uint256,uint256) public pure returns (uint256) {}
}
contract Verifier {
  function verifyProof(
          uint[2] memory a,
          uint[2][2] memory b,
          uint[2] memory c,
          uint[12] memory input
      ) public view returns (bool) {}
}


// ----------------------------------------------------------------------------
// Membership Data Structure
// ----------------------------------------------------------------------------
library Members {
    struct Member {
        bool exists;
        uint index;
        string name;
    }
    struct Data {
        bool initialised;
        mapping(address => Member) entries;
        address[] index;
    }

    event MemberAdded(address indexed memberAddress, string name, uint totalAfter);
    event MemberRemoved(address indexed memberAddress, string name, uint totalAfter);
    event MemberNameUpdated(address indexed memberAddress, string oldName, string newName);

    function init(Data storage self) public {
        require(!self.initialised);
        self.initialised = true;
    }
    function isMember(Data storage self, address _address) public view returns (bool) {
        return self.entries[_address].exists;
    }
    function add(Data storage self, address _address, string memory _name) public {
        require(!self.entries[_address].exists);
        self.index.push(_address);
        self.entries[_address] = Member(true, self.index.length - 1, _name);
        emit MemberAdded(_address, _name, self.index.length);
    }
    function remove(Data storage self, address _address) public {
        require(self.entries[_address].exists);
        uint removeIndex = self.entries[_address].index;
        emit MemberRemoved(_address, self.entries[_address].name, self.index.length - 1);
        uint lastIndex = self.index.length - 1;
        address lastIndexAddress = self.index[lastIndex];
        self.index[removeIndex] = lastIndexAddress;
        self.entries[lastIndexAddress].index = removeIndex;
        delete self.entries[_address];
        if (self.index.length > 0) {
            self.index.length--;
        }
    }
    function setName(Data storage self, address memberAddress, string memory _name) public {
        Member storage member = self.entries[memberAddress];
        require(member.exists);
        emit MemberNameUpdated(memberAddress, member.name, _name);
        member.name = _name;
    }
    function length(Data storage self) public view returns (uint) {
        return self.index.length;
    }
}

// ----------------------------------------------------------------------------
// Ballot contract -  Allows for one or many ballots to be run
// ----------------------------------------------------------------------------
contract FluxBallot is Owned {   // should be operated
    using Members for Members.Data;

    MiMC public mimc;             // not public, for testing only
    Verifier public verifier;     // not public
    Members.Data public members;  // not public

    struct Vote {
        bytes message;
        uint256 timestamp;
    }

    struct Ballot {
        string description;
        // uint256 startDate;  // optional
        // uint256 endDate;
        mapping(bytes32 => Vote) votes;
        bytes32[] votesIndex;
        bool open;
        uint initiated;
        uint closed;  // should be enddate only??
        // what else would a round of votes have??
    }
    Ballot[] public ballots;

    event Voted(uint256 ballotId, bytes32 key);
    event NewBallot(uint indexed ballotId, address indexed proposer);
    event MemberAdded(address indexed memberAddress, string name, uint totalAfter);
    event MemberRemoved(address indexed memberAddress, string name, uint totalAfter);
    event MemberNameUpdated(address indexed memberAddress, string oldName, string newName);

    constructor () public {
      initOwned(msg.sender);
      members.init();
    }

    // Owner functions
    function setMiMC(address _mimc) public onlyOwner {
      mimc = MiMC(_mimc);
    }
    function setVerifier(address _verifier) public onlyOwner {
      verifier = Verifier(_verifier);
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

    // Ballot functions
    function newBallot (string memory _description) public onlyOwner returns (uint256 ballotId) {  // should be operators
        bytes32[] memory votesIndex;
        Ballot memory ballot = Ballot({
              // proposer: msg.sender,
              description: _description,
              votesIndex: votesIndex,
              // executor: address(0),
              open: true,
              initiated: now,
              closed: 0
          });
      ballots.push(ballot);
      emit NewBallot(ballots.length - 1, msg.sender);
      return ballots.length - 1;
    }

    function ballotsIndexLength() public view returns (uint) {
        return ballots.length;
    }

    // Voting functions
    function vote ( uint256 ballotId,  bytes memory message) public {  // Should be internal and called by a valid signal
      Ballot storage ballot = ballots[ballotId];
      require(ballot.open);
      // add message to registry
      bytes32 key = voteHash(message);
      ballot.votes[key] = Vote(message, now);
      ballot.votesIndex.push(key);  // not sure if this is correct
      emit Voted(ballotId, key);
    }

    // Helper functions
    function voteHash(bytes memory _message) internal pure returns (bytes32) {
        // return sha256( _message);    // salted?
        return keccak256(abi.encodePacked( _message));   // changed to MiMC?
    }
    function votesIndexLength(uint256 ballotId) public view returns (uint) {
        return ballots[ballotId].votesIndex.length;
    }

    // is this just the same as voting? or a change identity commitment?
    function changeKey ( uint256 ballotId, bytes memory message) public {
      Ballot storage ballot = ballots[ballotId];
      require(ballot.open);
    }

    // Once the ballot has ended, the results counted and the result published
    function submitResults ( string memory zkproof , uint256 ballotId, bool result) public onlyOwner  {  // should be changed to operators
    }

    // Once the votes have been counted, can we verify that a key voted?
    function verifyVote ( string memory zkproof, bytes32 key) public {
    }

 }
