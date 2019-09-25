
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
contract ZkFluxBallot is Owned {   // should be operated
    using Members for Members.Data;

    MiMC public mimc;             // not public, for testing only
    Verifier public verifier;     // not public
    Members.Data public members;  // not public

    struct Vote {
        bytes message;
        uint256 timestamp;
    }

    struct Ballot {
        // address proposer;  // not included
        string description;
        Vote[] votes;
        bool open;
        uint256 initiated;
        uint256 closed;  // timestamp closed, could be based on enddate only??
        // uint256 startDate;  // optional
        // uint256 endDate;
        // what else would a round of votes have??
    }
    Ballot[] public ballots;

    // The external_nullifier helps to prevent double-signalling by the same
    // user.
    uint256 public externalNullifier;

    // Whether broadcastSignal() can only be called by the owner of this
    // contract. This is the case as a safe default.
    bool public isBroadcastPermissioned = true;

    // Whether the contract has already seen a particular nullifier hash
    mapping (uint => bool) nullifierHashHistory;

    event Voted(uint256 ballotId, bytes signal, uint256 nullifiers_hash, uint256 externalNullifier);

    event NewBallot(uint indexed ballotId, address indexed proposer);
    event MemberAdded(address indexed memberAddress, string name, uint totalAfter);
    event MemberRemoved(address indexed memberAddress, string name, uint totalAfter);
    event MemberNameUpdated(address indexed memberAddress, string oldName, string newName);

    constructor (uint256 _externalNullifier) public {
      initOwned(msg.sender);
      members.init();
      externalNullifier = _externalNullifier;
    }

    // Owner functions
    function setMiMC(address _mimc) public onlyOwner {
      mimc = MiMC(_mimc);
    }
    function setVerifier(address _verifier) public onlyOwner {
      verifier = Verifier(_verifier);
    }

    /*
     * Sets a new external nullifier for the contract. Only the owner can do this.
     * @param new_external_nullifier The new external nullifier to set
     */
    function setExternalNullifier(uint256 _externalNullifier) public onlyOwner {
      externalNullifier = _externalNullifier;
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
        Vote[] memory _votes;

        Ballot memory ballot = Ballot({
              // proposer: msg.sender,
              description: _description,
              votes: _votes,
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

    /*
     * A modifier which ensures that the signal and proof are valid.
     * @param signal The signal to broadcast
     * @param a The corresponding `a` parameter to verifier.sol's verifyProof()
     * @param b The corresponding `b` parameter to verifier.sol's verifyProof()
     * @param c The corresponding `c` parameter to verifier.sol's verifyProof()
     * @param input The public inputs to the zk-SNARK
     */
    modifier isValidSignalAndProof (
        bytes memory signal,
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[12] memory input
    ) {
        // Hash the signal
        uint256 signal_hash = uint256(keccak256(signal)) >> 8;

        require(hasNullifier(input[1]) == false, "Semaphore: nullifier already seen");
        require(signal_hash == input[2], "Semaphore: signal hash mismatch");
        require(externalNullifier == input[3], "Semaphore: external nullifier mismatch");
        // require(isInRootHistory(input[0]), "Semaphore: root not seen");
        require(verifier.verifyProof(a, b, c, input), "Semaphore: invalid proof");
        _;
    }

    /*
     * If broadcastSignal is permissioned, check if msg.sender is the contract owner
     */
    modifier onlyOwnerIfPermissioned() {
        require(!isBroadcastPermissioned || msg.sender == owner, "MACI: broadcast permission denied");
        _;
    }

    /*
     * Broadcast the signal.
     * @param signal The signal to broadcast
     * @param a The corresponding `a` parameter to verifier.sol's verifyProof()
     * @param b The corresponding `b` parameter to verifier.sol's verifyProof()
     * @param c The corresponding `c` parameter to verifier.sol's verifyProof()
     * @param input The public inputs to the zk-SNARK
     */
    function broadcastVote(
        uint256 ballotId,
        bytes memory signal,
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[12] memory input // (root, nullifiers_hash, signal_hash, external_nullifier)
    ) public
    onlyOwnerIfPermissioned
    isValidSignalAndProof(signal, a, b, c, input)
    {
        uint nullifiers_hash = input[1];
        vote(ballotId,nullifiers_hash, signal);
        nullifierHashHistory[nullifiers_hash] = true;
    }

    // Voting functions
    function vote ( uint256 ballotId, uint256 nullifiers_hash,  bytes memory signal) internal {  // Should be internal and called by a valid signal
      Ballot storage ballot = ballots[ballotId];
      require(ballot.open);
      // add message to registry
      ballot.votes[votesIndexLength(ballotId)] = Vote(signal, now);
      emit Voted(ballotId, signal, nullifiers_hash, externalNullifier);
    }

    // Helper functions
    function votesIndexLength(uint256 ballotId) public view returns (uint) {
        return ballots[ballotId].votes.length;
    }

    // is this just the same as voting? or a change identity commitment?
    function insertIdentity ( uint256 ballotId, bytes memory message) public {
      Ballot storage ballot = ballots[ballotId];
      require(ballot.open);
      // insert(identity_commitment);
    }
    // is this just the same as voting? or a change identity commitment?
    function updateIdentity ( uint256 ballotId, bytes memory message) public {
      Ballot storage ballot = ballots[ballotId];
      require(ballot.open);
      // insert(identity_commitment);
    }

    /*
     * @param n The nulllifier hash to check
     * @return True if the nullifier hash has previously been stored in the
     *         contract
     */
    function hasNullifier(uint n) public view returns (bool) {
        return nullifierHashHistory[n];
    }



    // Once the ballot has ended, the results counted and the result published
    function submitResults ( string memory zkproof , uint256 ballotId, bool result) public onlyOwner  {  // should be changed to operators
    }

    // Once the votes have been counted, can we verify that a key voted?
    function verifyVote ( string memory zkproof, bytes32 key) public {
    }

 }
