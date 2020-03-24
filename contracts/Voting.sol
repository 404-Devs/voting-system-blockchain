pragma solidity >=0.4.21 <0.7.0;

contract Voting {
    address public creator;
    uint public electionCount = 0;
    uint public aspirantCount = 0;

    struct Election {
        uint electionId;
        string name;
        uint start_timestamp;
        uint end_timestamp;
        uint voteCount;
        uint teamCount;
        uint tokenCount;
        bool ended;
        uint addedAt;
        uint updatedAt;
        uint[] teamIds; // apparently, you can't loop over mappings or their keys
        mapping(uint => Team) teams;
        mapping(bytes32 => Ballot) votingTokens;
    }

    struct Aspirant {
        address aspirantId;
        string name;
        uint addedAt;
        uint updatedAt;
    }

    struct Team {
        uint teamId;
        string name;
        address chairmanId;
        address secGenId;
        address treasurerId;
        uint votes;
        uint addedAt;
        uint updatedAt;
    }

    struct Ballot {
        uint teamId;
        bytes32 votingToken;
        bool cast;
        uint addedAt;
        uint updatedAt;
    }

    mapping(uint => Election) public elections;
    mapping(address => Aspirant) public aspirants;

    event Cast(uint _electionId, uint _teamId, uint teamCount, uint totalCount, uint castAt);
    event ElectionEnded(uint _electionId, uint _winningTeamId);

    modifier onlyCreator() {
        require(msg.sender == creator, "Only the Creator can call this.");
        _;
    }

    modifier notZero(uint _n) {
        require(_n != 0, "IDs should not equal zero.");
        _;
    }

    modifier electionExists(uint _electionId) {
        require(elections[_electionId].electionId == _electionId, "Election does not exist.");
        _;
    }


    constructor() public {
        creator = msg.sender;
    }

    function setElection(uint _electionId, string memory _name, uint _start_timestamp, uint _end_timestamp)
    public
    notZero(_electionId)
    onlyCreator()
    {
        uint time = now;
        if (elections[_electionId].electionId == _electionId) {
            require(time < elections[_electionId].start_timestamp, "Election has either started or ended.");
            elections[_electionId].name = _name;
            elections[_electionId].start_timestamp = _start_timestamp;
            elections[_electionId].end_timestamp = _end_timestamp;
            elections[_electionId].updatedAt = time;
        } else {
            uint[] memory teamIds;
            elections[_electionId] = Election(_electionId, _name, _start_timestamp, _end_timestamp, 0, 0, 0, false, time, time, teamIds);
            electionCount++;
        }
    }


    function setAspirant(address _aspirantAddress, string memory _name)
    public
    onlyCreator()
    {
        uint time = now;
        if (aspirants[_aspirantAddress].aspirantId == _aspirantAddress) {
            aspirants[_aspirantAddress].name = _name;
            aspirants[_aspirantAddress].updatedAt = time;
        } else {
            aspirants[_aspirantAddress] = Aspirant(_aspirantAddress, _name, time, time);
            aspirantCount++;
        }
    }

    function setTeam(uint _electionId, uint _teamId, string memory _name, address _chairmanId, address _secGenId, address _treasurerId)
    public
    onlyCreator()
    notZero(_electionId)
    electionExists(_electionId)
    notZero(_teamId)
    {
        uint time = now;
        require(time < elections[_electionId].start_timestamp, "Election has either started or ended.");
        require(aspirants[_chairmanId].aspirantId == _chairmanId, "ChairmanID does not exist in our records");
        require(aspirants[_secGenId].aspirantId == _secGenId, "Secretary General ID does not exist in our records");
        require(aspirants[_treasurerId].aspirantId == _treasurerId, "TreasurerID does not exist in our records");
        if (elections[_electionId].teams[_teamId].teamId == _teamId) {
            elections[_electionId].teams[_teamId].name = _name;
            elections[_electionId].teams[_teamId].chairmanId = _chairmanId;
            elections[_electionId].teams[_teamId].secGenId = _secGenId;
            elections[_electionId].teams[_teamId].treasurerId = _treasurerId;
            elections[_electionId].teams[_teamId].updatedAt = time;
        } else {
            elections[_electionId].teamIds.push(_teamId);
            elections[_electionId].teams[_teamId] = Team(_teamId, _name, _chairmanId, _secGenId, _treasurerId, 0, time, time);
            elections[_electionId].teamCount++;
        }
    }

    function setVotingToken(uint _electionId, string memory _token)
    public
    onlyCreator()
    notZero(_electionId)
    {
        uint time = now;
        require(time < elections[_electionId].start_timestamp, "Election has either started or ended.");
        bytes32 _hashedToken = keccak256(abi.encode(_token));
        require(elections[_electionId].votingTokens[_hashedToken].votingToken != _hashedToken, "Voting token already added.");
        uint tokenCount = elections[_electionId].tokenCount;
        elections[_electionId].votingTokens[_hashedToken] = Ballot(tokenCount, _hashedToken, false, time, time);
        elections[_electionId].tokenCount++;
        elections[_electionId].updatedAt = time;
    }

    function cast(uint _electionId, uint _teamId, string memory _votingToken)
    public
    notZero(_electionId)
    notZero(_teamId)
    electionExists(_electionId)
    {
        uint time = now;
        require(time >= elections[_electionId].start_timestamp && time <= elections[_electionId].end_timestamp, "Not the time to cast votes");
        bytes32 _hashedToken = keccak256(abi.encode(_votingToken));
        require(elections[_electionId].votingTokens[_hashedToken].votingToken == _hashedToken, "Voting token does not exist.");
        require(!elections[_electionId].votingTokens[_hashedToken].cast, "Voter has already cast their vote.");
        require(elections[_electionId].teams[_teamId].teamId == _teamId, "Team does not exist.");

        // register the vote
        elections[_electionId].votingTokens[_hashedToken].teamId = _teamId;
        elections[_electionId].votingTokens[_hashedToken].cast = true;
        elections[_electionId].votingTokens[_hashedToken].updatedAt = time;
        elections[_electionId].teams[_teamId].votes++;
        elections[_electionId].teams[_teamId].updatedAt = time;
        elections[_electionId].voteCount++;
        elections[_electionId].updatedAt = time;
        emit Cast(_electionId, _teamId, elections[_electionId].teams[_teamId].votes,  elections[_electionId].voteCount, time);
    }

    function winner(uint _electionId)
    public
    notZero(_electionId)
    electionExists(_electionId)
    view returns (uint _winningTeamId)
    {
        require(elections[_electionId].ended, "Election not over.");
        uint winningVoteCount = 0;
        for (uint _teamId = 0; _teamId < elections[_electionId].teamIds.length; _teamId++) {
            if (elections[_electionId].teams[_teamId].votes > winningVoteCount) {
                winningVoteCount = elections[_electionId].teams[_teamId].votes;
                _winningTeamId = _teamId;
            }
        }
    }

    function endElection(uint _electionId)
    public
    onlyCreator()
    notZero(_electionId)
    electionExists(_electionId)
    {
        require(now > elections[_electionId].end_timestamp, "Election not over.");
        require(!elections[_electionId].ended, "endElection has already been called.");
        elections[_electionId].ended = true;
        emit ElectionEnded(_electionId, winner(_electionId));
    }

    function getTeam(uint _electionId, uint _teamId)
    public
    view returns (uint teamId, string memory name, address chairmanId, address secGenId, address treasurerId, uint votes, uint addedAt, uint updatedAt)
    {
        Team memory t = elections[_electionId].teams[_teamId];
        return (t.teamId, t.name, t.chairmanId, t.secGenId, t.treasurerId, t.votes, t.addedAt, t.updatedAt);
    }

    function getBallot(uint _electionId, string memory _token)
    public
    view returns (uint teamId, bytes32 votingToken, bool voted, uint addedAt, uint updatedAt)
    {
        Ballot memory b = elections[_electionId].votingTokens[keccak256(abi.encode(_token))];
        return (b.teamId, b.votingToken, b.cast, b.addedAt, b.updatedAt);
    }
}
