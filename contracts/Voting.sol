pragma solidity >=0.4.21 <0.7.0;

// a smart contract for "party block voting", where parties = teams
// seriously needs refactoring
contract Voting {
    uint public electionCount = 0;
    uint public aspirantCount = 0;

    struct Election {
        uint electionId;
        string electionName;
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
        string team_name;
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

    function addElection(string memory _name, uint start_timestamp, uint end_timestamp) public {
        elections[electionCount] = Election(electionCount, _name, msg.sender, start_timestamp, end_timestamp, 0, 0, 0, now, now);
        electionCount++;
    }


    function addAspirant(address _aspirantAddress, string memory _name) public {
        aspirants[_aspirantAddress] = Aspirant(_aspirantAddress, _name, msg.sender, now, now);
        aspirantCount++;
    }

    function addTeam(uint _electionId, string memory _name, address chairmanId, address secGenId, address treasurerId) public {
        uint teamCount = elections[_electionId].teamCount;
        elections[_electionId].teams[teamCount] = Team(teamCount, _name, chairmanId, secGenId, treasurerId, msg.sender, 0, now, now);
        elections[_electionId].teamCount++;
    }

    function addVotingToken(uint _electionId, string memory _token) public {
        uint tokenCount = elections[_electionId].tokenCount;
        elections[_electionId].votingTokens[_token] = Ballot(tokenCount, _token, false, now, now);
        elections[_electionId].tokenCount++;
    }

    function vote(uint _electionId, uint _teamId, string memory _votingToken) public {
        // require(elections[_electionId].electionId == _electionId, "Election does not exist.");
        // require(elections[_electionId].votingTokens[_votingToken].votingToken == _votingToken, "Voting token does not exist.");
        // require(!elections[_electionId].votingTokens[_votingToken].cast, "Voter has already cast their vote.");
        // require(!elections[_electionId].teams[_teamId], "Team does not exist.");

        // register the vote
        elections[_electionId].votingTokens[_votingToken].teamId = _teamId;
        elections[_electionId].votingTokens[_votingToken].cast = true;
        elections[_electionId].votingTokens[_votingToken].updatedAt = now;
        elections[_electionId].teams[_teamId].votes++;
        elections[_electionId].voteCount++;
    }

    function getTeam(uint _electionId, uint _teamId) public view returns (uint teamId, string memory team_name, address chairmanId, address secGenId, 
    address treasurerId, address addedBy, uint votes, uint addedAt, uint updatedAt) {

        Team memory t = elections[_electionId].teams[_teamId];
        return (t.teamId, t.team_name, t.chairmanId, t.secGenId, t.treasurerId, t.addedBy, t.votes, t.addedAt, t.updatedAt);
    }

    function getBallot(uint _electionId, string memory _token) public view returns (uint teamId, string memory votingToken, bool cast, 
    uint addedAt, uint updatedAt) {
        Ballot memory b = elections[_electionId].votingTokens[_token];
        return (b.teamId, b.votingToken, b.cast, b.addedAt, b.updatedAt);
    }
}
