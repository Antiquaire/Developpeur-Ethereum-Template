// SPDX-License-Identifier: GPL-3.0

//This contract only implement what was in the instructions.
//The second contract adds equality gestion, reseting of the voting session and a corruption function to add votes.
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
contract Voting is Ownable{
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    
    mapping(address => Voter) public voters;
    Proposal[] public proposals;
    WorkflowStatus public workflowStatus; //default = RegisteringVoters
    uint winningProposalId;

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    modifier onlyRegistered {
        require(voters[msg.sender].isRegistered == true, "You are not registered.");
        _;
    }

    //only admin can change the workflowStatus
    //note: the last increment to VotesTallied can only be done in the function calculateWinner, once the winner has been found
    function incrementWorkflowStatus() external onlyOwner {
        require (uint(workflowStatus) < 4, "Cannot increment more." );
        workflowStatus = WorkflowStatus (uint (workflowStatus) + 1 );
        emit WorkflowStatusChange(WorkflowStatus (uint (workflowStatus) - 1), workflowStatus);
    }

    //admin register voters
    function registerVoter(address _addr) external onlyOwner {
        require(workflowStatus==WorkflowStatus.RegisteringVoters, "The session workflow status should be in registering voters to proceed.");
        require(_addr == address(_addr), "Invalid address."); //maybe not necessary EVM already check that
        require(voters[_addr].isRegistered == false, "Voter already registered.");
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }


    //voters add proposals
    function addProposal(string calldata _proposal) external onlyRegistered {
        require(workflowStatus==WorkflowStatus.ProposalsRegistrationStarted, "The session workflow status should be set to ProposalsRegistrationStarted to proceed.");
        require(!stringsEquals(_proposal,""), "You cannot send an empty proposal.");
        uint proposalId = proposals.length;
        for(uint i = 0; i<proposalId; ++i) {
            require(!stringsEquals(_proposal, proposals[i].description), "This proposal has already been submitted.");
        }
        proposals.push(Proposal(_proposal,0));
        emit ProposalRegistered(proposalId);
    }

    //Voters can vote for one proposal
    function vote(uint _proposalId) external onlyRegistered {
        require(workflowStatus==WorkflowStatus.VotingSessionStarted, "The session workflow status should be set to VotingSessionStarted to proceed.");
        require(_proposalId < proposals.length, "Invalid proposal Id.");
        require(voters[msg.sender].hasVoted == false, "You have already voted.");
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        proposals[_proposalId].voteCount++;
        emit Voted (msg.sender, _proposalId);
    }

    //Admin can count the vote and declare the winner
    function calculateWinner() external onlyOwner {
        require(workflowStatus==WorkflowStatus.VotingSessionEnded, "The session workflow status should be set to VotingSessionEnded to proceed.");
        uint maxCount;
        uint winnerId;
        for(uint i = 0; i<proposals.length; ++i) {
            if(proposals[i].voteCount > maxCount){
                maxCount = proposals[i].voteCount;
                winnerId = i;
            }
        }
        winningProposalId = winnerId;
        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }

    function getWinner() external view returns (uint _winningProposalId ){
        require(workflowStatus==WorkflowStatus.VotesTallied, "The session workflow status should be set to VotesTallied to proceed.");
        return winningProposalId;
    }

    function stringsEquals(string memory _string1, string memory _string2) private pure returns (bool){
        return keccak256( abi.encodePacked(_string1) ) == keccak256( abi.encodePacked(_string2));
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
We want to be able to reset the Voting.
We should be able to set a new voting while preserving the voters => skip registration for voters.
We should be able to set a new voting with only proposals that are tied.
We want to allow voters to add votes in exchange of some ethers.
*/
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract VotingImproved is Ownable{
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    
    mapping(address => Voter) public voters;
    address[] votersAddresses;
    Proposal[] public proposals;
    WorkflowStatus public workflowStatus; //default = RegisteringVoters
    uint winningProposalId;

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    modifier onlyRegistered {
        require(voters[msg.sender].isRegistered == true, "You are not registered.");
        _;
    }

    //only admin can change the workflowStatus
    //note: the last increment to VotesTallied can only be done in the function calculateWinner, once the winner has been found
    function incrementWorkflowStatus() external onlyOwner {
        require (uint(workflowStatus) < 4, "Cannot increment more." );
        workflowStatus = WorkflowStatus (uint (workflowStatus) + 1 );
        emit WorkflowStatusChange(WorkflowStatus (uint (workflowStatus) - 1), workflowStatus);
    }

    //admin register voters
    function registerVoter(address _addr) external onlyOwner {
        require(workflowStatus==WorkflowStatus.RegisteringVoters, "The session workflow status should be in registering voters to proceed.");
        require(_addr == address(_addr), "Invalid address."); //maybe not necessary EVM already check that
        require(voters[_addr].isRegistered == false, "Voter already registered.");
        voters[_addr].isRegistered = true;
        votersAddresses.push(_addr);
        emit VoterRegistered(_addr);
    }


    //voters add proposals
    function addProposal(string calldata _proposal) external onlyRegistered {
        require(workflowStatus==WorkflowStatus.ProposalsRegistrationStarted, "The session workflow status should be set to ProposalsRegistrationStarted to proceed.");
        require(!stringsEquals(_proposal,""), "You cannot send an empty proposal.");
        uint proposalId = proposals.length;
        for(uint i = 0; i<proposalId; ++i) {
            require(!stringsEquals(_proposal, proposals[i].description), "This proposal has already been submitted.");
        }
        proposals.push(Proposal(_proposal,0));
        emit ProposalRegistered(proposalId);
    }

    //Voters can vote for one proposal
    function vote(uint _proposalId) external onlyRegistered {
        require(workflowStatus==WorkflowStatus.VotingSessionStarted, "The session workflow status should be set to VotingSessionStarted to proceed.");
        require(_proposalId < proposals.length, "Invalid proposal Id.");
        require(voters[msg.sender].hasVoted == false, "You have already voted.");
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        proposals[_proposalId].voteCount++;
        emit Voted (msg.sender, _proposalId);
    }

    //Admin can count the vote and declare the winner
    function calculateWinner() external onlyOwner {
        require(workflowStatus==WorkflowStatus.VotingSessionEnded, "The session workflow status should be set to VotingSessionEnded to proceed.");
        uint maxCount;
        uint winnerId;
        uint winnersCount;
        uint proposalLength = proposals.length;

        // I have made the choice to use another 'for' to calculate the new proposals array rather than adding another storage array for proposals that I would have to keep deleting and push new equality proposals found into.
        for(uint i = 0; i<proposalLength; ++i) {
            if(proposals[i].voteCount > maxCount) {
                maxCount = proposals[i].voteCount;
                winnersCount = 1;
                winnerId = i;
            }
            else if (proposals[i].voteCount == maxCount) {
                winnersCount++;
            } 
        }

        //if there is again an equality between the same proposals => rng
        if(winnersCount == proposalLength && winnersCount > 1) {
            winnerId = randomNumber(winnersCount);
        } else if(winnersCount > 1) { // In case of equality we only keep winning proposals and start a new vote session
            for(uint i=proposalLength; i > 0; i--) {
                if(proposals[i-1].voteCount < maxCount) {
                    proposals[i-1] = proposals[proposals.length - 1];
                    proposals.pop();
                } else {
                    proposals[i-1].voteCount = 0;
                }
            }
            resetVoters(true);
            workflowStatus = WorkflowStatus.VotingSessionStarted;
            emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
            return;
        }
        winningProposalId = winnerId;
        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }

    function resetVoting(bool _keepVoters) external onlyOwner {
        require(workflowStatus==WorkflowStatus.VotesTallied, "The session workflow status should be set to VotesTallied to proceed.");
        delete proposals;
        winningProposalId = 0;
        resetVoters(_keepVoters);
        if( _keepVoters ) {
            workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        } else {
            workflowStatus = WorkflowStatus.RegisteringVoters;
        }
        emit WorkflowStatusChange(WorkflowStatus.VotesTallied, WorkflowStatus(workflowStatus));
    }

    function addVotes(uint _nbVotes) external payable onlyRegistered {
        require(workflowStatus==WorkflowStatus.VotingSessionStarted, "The session workflow status should be set to VotingSessionStarted to proceed.");
        require(voters[msg.sender].hasVoted == true, "You first need to vote a first time to add more votes.");
        require(_nbVotes > 0, "Cannot add 0 vote.");
        require(msg.value/(1 ether * _nbVotes) >= _nbVotes, "Not enough ETH send for number of votes given (1 ether = 1 vote).");

        //refund excess
         (bool sent, ) = address(msg.sender).call{value: (msg.value - (1 ether*_nbVotes))}("");
        require(sent==true, "Transaction failed.");

        uint proposalId = voters[msg.sender].votedProposalId;
        proposals[proposalId].voteCount = proposals[proposalId].voteCount + _nbVotes;
        emit Voted (msg.sender, proposalId);
    }

    function getWinner() external view returns (uint _winningProposalId ){
        require(workflowStatus==WorkflowStatus.VotesTallied, "The session workflow status should be set to VotesTallied to proceed.");
        return winningProposalId;
    }

    function resetVoters(bool _keepRegistered) private onlyOwner {
        for (uint i = 0; i < votersAddresses.length; ++i){
            voters[votersAddresses[i]] = Voter(_keepRegistered, false, 0);
        }
        if (_keepRegistered == false) {
            delete votersAddresses;
        }
    }

    //simple random
    //TODO: use oracle
    function randomNumber(uint _mod) private view returns(uint _res){
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % _mod;
    }

    function stringsEquals(string memory _string1, string memory _string2) private pure returns (bool){
        return keccak256( abi.encodePacked(_string1) ) == keccak256( abi.encodePacked(_string2));
    }
}
