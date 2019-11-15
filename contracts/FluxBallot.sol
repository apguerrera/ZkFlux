
pragma solidity ^0.5.4;


import "./Dependencies/Members.sol";
import "./Dependencies/VerifierInterface.sol";
import "./Dependencies/MiMCInterface.sol";
import "./Dependencies/MerkleTree.sol";
import "./Shared/Owned.sol";
import "./Shared/Operated.sol";


// ----------------------------------------------------------------------------
// Ballot contract -  Allows for one or many ballots to be run
// ----------------------------------------------------------------------------
contract FluxBallot is Owned {   // should be operated
    using Members for Members.Data;

    MiMCInterface public mimc;             // not public, for testing only
    VerifierInterface public verifier;     // not public
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
