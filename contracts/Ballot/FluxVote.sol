pragma solidity ^0.5.4;


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;
    bool private initialised;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function initOwned(address _owner) internal {
        require(!initialised);
        owner = _owner;
        initialised = true;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    function transferOwnershipImmediately(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

// ----------------------------------------------------------------------------
// Maintain a list of operators that are permissioned to execute certain
// functions
// ----------------------------------------------------------------------------
contract Operated is Owned {
    mapping(address => bool) public operators;

    event OperatorAdded(address _operator);
    event OperatorRemoved(address _operator);

    modifier onlyOperator() {
        require(operators[msg.sender] || owner == msg.sender);
        _;
    }

    function initOperated(address _owner) internal {
        initOwned(_owner);
    }
    function addOperator(address _operator) public onlyOwner {
        require(!operators[_operator]);
        operators[_operator] = true;
        emit OperatorAdded(_operator);
    }
    function removeOperator(address _operator) public onlyOwner {
        require(operators[_operator]);
        delete operators[_operator];
        emit OperatorRemoved(_operator);
    }
}


contract MiMC{
    function MiMCpe7(uint256,uint256,uint256,uint256) public pure returns (uint256) {}
}
contract Verifier {
    function verifyProof(
          uint[2] memory a,
          uint[2][2] memory b,
          uint[2] memory c,
          uint[1] memory input
    ) view public returns (bool) {}
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
    function add(Data storage self, address _address, string _name) public {
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
    function setName(Data storage self, address memberAddress, string _name) public {
        Member storage member = self.entries[memberAddress];
        require(member.exists);
        emit MemberNameUpdated(memberAddress, member.name, _name);
        member.name = _name;
    }
    function length(Data storage self) public view returns (uint) {
        return self.index.length;
    }
}


contract FluxVote is Owned {   // should be operated
    using Members for Members.Data;

    MiMC public mimc;             // not public
    Verifier public verifier;     // not public
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
      mimc = MiMC(_mimc);
    }
    function setVerifier(address _verifier) public onlyOwner {
      verifier = Verifier(_verifier);
    }

    // Member functions
    function addMember(address _address, string _name) public onlyOwner {
        members.add(_address, _name);
    }
    function removeMember(address _address) public onlyOwner  {
        members.remove(_address);
    }
    function setMemberName(string memberName) public {
        members.setName(msg.sender, memberName);
    }
    function numberOfMembers() public view returns (uint) {
        return members.length();
    }
    function getMembers() public view returns (address[]) {
        return members.index;
    }
    function getMemberData(address _address) public view returns (bool _exists, uint _index, string _name) {
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
    function verifyVote ( string zkproof, bytes32 key) public {
    }
    function submitResults ( string zkproof ,/* uint256 ballotId,*/ bool result) public onlyOwner  {  // should be operators
    }

 }
