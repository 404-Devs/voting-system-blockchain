pragma solidity >=0.4.21 <0.7.0;

// a smart contract for "party block voting", where parties = teams
// seriously needs refactoring
contract Voting {
    uint public electionCount = 0;
    uint public aspirantCount = 0;

    struct Election {
        uint electionId;
        string name;
        address addedBy;
        uint start_timestamp;
        uint end_timestamp;
        uint voteCount;
        uint teamCount;
        uint tokenCount;
        uint addedAt;
        uint updatedAt;
        mapping(uint => Team) teams;
        mapping(string => Ballot) votingTokens;
    }

    struct Aspirant {
        address aspirantId;
        string name;
        address addedBy;
        uint addedAt;
        uint updatedAt;
    }

    struct Team {
        uint teamId;
        string name;
        address chairmanId;
        address secGenId;
        address treasurerId;
        address addedBy;
        uint votes;
        uint addedAt;
        uint updatedAt;
    }

    struct Ballot {
        uint teamId;
        string votingToken;
        bool cast;
        uint addedAt;
        uint updatedAt;
    }

    mapping(uint => Election) public elections;
    mapping(address => Aspirant) public aspirants;

    function setElection(uint _electionId, string memory _name, uint _start_timestamp, uint _end_timestamp) public {
        require(_electionId != 0, "ElectionID should not be equal to zero");
        if (elections[_electionId].electionId == _electionId) {
            require(now < elections[_electionId].start_timestamp, "Election has already started.");
            elections[_electionId].name = _name;
            elections[_electionId].start_timestamp = _start_timestamp;
            elections[_electionId].end_timestamp = _end_timestamp;
            elections[_electionId].updatedAt = now;
        } else {
            elections[_electionId] = Election(_electionId, _name, msg.sender, _start_timestamp, _end_timestamp, 0, 0, 0, now, now);
            electionCount++;
        }
    }


    function setAspirant(address _aspirantAddress, string memory _name) public {
        if (aspirants[_aspirantAddress].aspirantId == _aspirantAddress) {
            aspirants[_aspirantAddress].name = _name;
            aspirants[_aspirantAddress].updatedAt = now;
        } else {
            aspirants[_aspirantAddress] = Aspirant(_aspirantAddress, _name, msg.sender, now, now);
            aspirantCount++;
        }
    }

    function setTeam(uint _electionId, uint _teamId, string memory _name, address _chairmanId, address _secGenId, address _treasurerId) public {
        require(_electionId != 0, "ElectionID should not be equal to zero");
        require(_teamId != 0, "TeamID should not be equal to zero");
        require(elections[_electionId].electionId == _electionId, "Election does not exist.");
        require(now < elections[_electionId].start_timestamp, "Election has already started.");
        require(aspirants[_chairmanId].aspirantId == _chairmanId, "ChairmanID does not exist in our records");
        require(aspirants[_secGenId].aspirantId == _secGenId, "Secretary General ID does not exist in our records");
        require(aspirants[_treasurerId].aspirantId == _treasurerId, "TreasurerID does not exist in our records");
        if (elections[_electionId].teams[_teamId].teamId == _teamId) {
            elections[_electionId].teams[_teamId].name = _name;
            elections[_electionId].teams[_teamId].chairmanId = _chairmanId;
            elections[_electionId].teams[_teamId].secGenId = _secGenId;
            elections[_electionId].teams[_teamId].treasurerId = _treasurerId;
            elections[_electionId].teams[_teamId].updatedAt = now;
        } else {
            elections[_electionId].teams[_teamId] = Team(_teamId, _name, _chairmanId, _secGenId, _treasurerId, msg.sender, 0, now, now);
            elections[_electionId].teamCount++;
        }
    }

    function setVotingToken(uint _electionId, string memory _token) public {
        require(_electionId != 0, "ElectionID should not be equal to zero");
        require(now < elections[_electionId].start_timestamp, "Election has already started.");
        string memory storedToken = elections[_electionId].votingTokens[_token].votingToken;
        require(keccak256(abi.encode(storedToken)) != keccak256(abi.encode(_token)), "Voting token already added.");
        uint tokenCount = elections[_electionId].tokenCount;
        elections[_electionId].votingTokens[_token] = Ballot(tokenCount, _token, false, now, now);
        elections[_electionId].tokenCount++;
        elections[_electionId].updatedAt = now;
    }

    function cast(uint _electionId, uint _teamId, string memory _votingToken) public {
        require(_electionId != 0, "ElectionID should not be equal to zero");
        require(elections[_electionId].electionId == _electionId, "Election does not exist.");
        require(now >= elections[_electionId].start_timestamp && now <= elections[_electionId].end_timestamp, "Not the time to cast votes");
        string memory storedToken = elections[_electionId].votingTokens[_votingToken].votingToken;
        require(keccak256(abi.encode(storedToken)) == keccak256(abi.encode(_votingToken)), "Voting token does not exist.");
        require(!elections[_electionId].votingTokens[_votingToken].cast, "Voter has already cast their vote.");
        require(elections[_electionId].teams[_teamId].teamId == _teamId, "Team does not exist.");

        // register the vote
        elections[_electionId].votingTokens[_votingToken].teamId = _teamId;
        elections[_electionId].votingTokens[_votingToken].cast = true;
        elections[_electionId].votingTokens[_votingToken].updatedAt = now;
        elections[_electionId].teams[_teamId].votes++;
        elections[_electionId].teams[_teamId].updatedAt = now;
        elections[_electionId].voteCount++;
        elections[_electionId].updatedAt = now;
    }

    function getTeam(uint _electionId, uint _teamId) public view returns (uint teamId, string memory name, address chairmanId, address secGenId, 
    address treasurerId, address addedBy, uint votes, uint addedAt, uint updatedAt) {

        Team memory t = elections[_electionId].teams[_teamId];
        return (t.teamId, t.name, t.chairmanId, t.secGenId, t.treasurerId, t.addedBy, t.votes, t.addedAt, t.updatedAt);
    }

    function getBallot(uint _electionId, string memory _token) public view returns (uint teamId, string memory votingToken, bool voted, 
    uint addedAt, uint updatedAt) {
        Ballot memory b = elections[_electionId].votingTokens[_token];
        return (b.teamId, b.votingToken, b.cast, b.addedAt, b.updatedAt);
    }
}
