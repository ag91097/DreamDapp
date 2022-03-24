// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 < 0.9.0;

import "hardhat/console.sol";


contract DreamDapp {
    struct Player{
        string name;
        uint rating;
    }

    struct Participant {
        string name;
        uint[] players;
    }

    struct Contest {
        uint numParticipantsRequired;
        uint participationFee;
        uint winningPrice;
        uint numParticipantsRegistered;
        address payable winner;
        address payable[] contestParticipants;
        mapping (address => uint) score;
        bool isValid;
        bool hasEnded;
    }

    Player[] public players;
    mapping (address => Participant) public participants;
    Contest public contests;

    uint public etherValue = 1 ether;
    uint public numPlayersRequired;
    uint public numPlayersTobeSelected;
    address public owner;
    uint public numContest;

    constructor() {
        owner = msg.sender;
        numPlayersRequired = 6;
        numPlayersTobeSelected = numPlayersRequired/2;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier notOwner(){
        require(msg.sender != owner, "Owner not allowed");
        _;
    }

    modifier onlyParticipant(){
        string memory empty = "";
        require( keccak256(abi.encodePacked(participants[msg.sender].name)) != keccak256(abi.encodePacked(empty)), "Not a Participant");
        _;
    }

    // Owner can add players using this
    function addPlayer(string memory _name) public onlyOwner{
        require(players.length < numPlayersRequired, "Could not add more players");
        players.push(Player(_name,0));
    }

    // Anyone can see players present
    function getAllPlayers() public view returns (Player[] memory){
        return players;
    }

    // User creating team to become a prticipant of contest. 
    function createTeam(string memory _name,uint[] memory _input) public notOwner{
        string memory empty = "";
        require( keccak256(abi.encodePacked(participants[msg.sender].name)) == keccak256(abi.encodePacked(empty)), "Cannot change team");
        require(numPlayersRequired == players.length, "All players not added yet");
        require(_input.length == numPlayersTobeSelected, "Select correct number of players");
        Participant memory newParticipant;
        newParticipant.name = _name;
        newParticipant.players = _input;
        participants[msg.sender] = newParticipant;
    }

    // Function for participants to see their selected team
    function getTeam() public view returns (Player[] memory){
        string memory empty = "";
        require( keccak256(abi.encodePacked(participants[msg.sender].name)) != keccak256(abi.encodePacked(empty)), "Create Team");       
        Player[] memory output = new Player[](numPlayersTobeSelected);
        uint[] memory playerList = participants[msg.sender].players;
        for(uint i=0;i<playerList.length;i++) {
            output[i] = (players[playerList[i]]);
        }
        return output;
    }

    // Owner creating contest for participant to participate 
    function createContest(uint _numParticipantsRequired, uint _participationFee) public onlyOwner {
        require(numPlayersRequired == players.length, "Add more players");
        contests.numParticipantsRequired = _numParticipantsRequired;
        contests.participationFee = _participationFee * etherValue;
        contests.winningPrice = _numParticipantsRequired*_participationFee * etherValue;
        contests.hasEnded = false;
        contests.isValid = false;
        numContest++;
    }

    // Paying fee to participate in contest.
    function selectContest() public notOwner payable onlyParticipant{
        require(numContest > 0, "No contest created");
        require(contests.hasEnded == false, "Contest Ended");
        require(contests.numParticipantsRegistered < contests.numParticipantsRequired, "No more participants allowed");
        require(contests.score[msg.sender] == 0, "Already registered for contest");
        require(contests.participationFee == msg.value, "Pay exact participation fee");
        contests.contestParticipants.push(payable(msg.sender));
        contests.score[msg.sender] = 1;
        contests.numParticipantsRegistered++;
        if(contests.numParticipantsRegistered == contests.numParticipantsRequired) {
            contests.isValid = true;
        }
    }

    // Contract Balance 
    function getBalance() public view returns (uint){
        return address(this).balance;
    }

    // function to generate contest result
    function generateResult() public onlyOwner {
        require(contests.isValid == true, "Result could not be generated yet");
        // random rating generated for players
        generateRating();
        // finding winner
        findWinner();
        // transfer winning price
        contests.winner.transfer(getBalance());
        // to stop generating result again
        contests.isValid = false;
        contests.hasEnded = true;
    }

    // Random rating givren to players. 
    function generateRating() internal {
        for(uint i=0 ;i < players.length ;i++){
            players[i].rating = uint(keccak256(abi.encodePacked(block.timestamp,i, msg.sender))) % 11;
        }
    }

    // Calculation of score of each participant
    // And finding the winner
    function findWinner() internal {
        uint max = 0;
        address payable win;
        for(uint i=0 ; i< contests.contestParticipants.length;i++){
            uint totalScore = calculateScore(contests.contestParticipants[i]);
            contests.score[contests.contestParticipants[i]] = totalScore;
            if(totalScore > max) {
                max = totalScore;
                win = contests.contestParticipants[i];
            }
        }
        contests.winner = win;
    }

    function calculateScore(address _input) internal view returns (uint){
        uint[] memory playerList = participants[_input].players;
        uint sum = 0;
        for(uint i=0;i<playerList.length;i++) {
            sum += (players[playerList[i]]).rating;
        }
        return sum;
    }

    // Reset for new contest to start 
    function reset() public onlyOwner{
        // Contest storage newContest;
        // contests.score = newContest.score;
        // mapping (address => uint) memory newScore;
        // contests = newContest; 
        delete players;
        delete contests;
    }
}