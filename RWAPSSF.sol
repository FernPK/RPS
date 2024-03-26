// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import './CommitReveal.sol';

contract RWAPSSF is CommitReveal{
    struct Player {
        bytes32 choiceHash; // zero - undefined, not zero - defined
        address addr;
    }
    uint public numPlayer = 0;
    uint public reward = 0;
    mapping (uint => Player) public player;
    uint public numInput = 0;
    uint private p0Choice = 7;
    uint private p1Choice = 7;
    uint private p2Choice = 7;
    uint public winner = 6; // 0 - p0 win, 1 - p1 win , 2 - p2 win
    uint public tsAddP0 = 0;
    uint public tsAddP1 = 0;
    uint public tsAddP2 = 0;
    uint public tsInputP0 = 0;
    uint public tsInputP1 = 0;
    uint public tsInputP2 = 0;
    uint public tsResult = 0;

    function addPlayer() public payable {
        require(numPlayer < 3);
        require(msg.value == 1 ether);
        reward += msg.value;
        player[numPlayer].addr = msg.sender;
        player[numPlayer].choiceHash = 0;
        if (numPlayer==0) {
            tsAddP0 = block.timestamp;
        }
        else if (numPlayer==1){
            tsAddP1 = block.timestamp;
        }
        else if (numPlayer==2){
            tsAddP2 = block.timestamp;
        }
        numPlayer++;
    }

    function input(bytes32 choiceHash, uint idx) public  {
        // choice 0 - rock, 1 - water, 2 - air, 3 - paper, 4 - sponge, 5 - scissors, 6 - fire
        require(numPlayer == 3);
        require(msg.sender == player[idx].addr);
        require(idx==0 || idx==1 || idx==2);
        // require(choice < 7);
        require(block.timestamp <= tsAddP2 + 1 hours);
        if (idx==0) {
            // p0Choice = choice;
            tsInputP0 = block.timestamp;
        }
        else if (idx==1){
            // p1Choice = choice;
            tsInputP1 = block.timestamp;
        }
        else if (idx==2){
            tsInputP2 = block.timestamp;
        }
        player[idx].choiceHash = choiceHash;
        commit(player[idx].choiceHash);
        numInput++;
    }

    function checkWinner() public {
        require(commits[player[0].addr].revealed == true && commits[player[1].addr].revealed && commits[player[2].addr].revealed);
        if ((p0Choice + 1) % 7 == p1Choice || (p0Choice + 2) % 7 == p1Choice || (p0Choice + 3) % 7 == p1Choice) { //p0 lose, p1 win
            if ((p2Choice + 1) % 7 == p1Choice || (p2Choice + 2) % 7 == p1Choice || (p2Choice + 3) % 7 == p1Choice){ //p2 lose, p1 win
                winner = 1;
            }
            else if ((p1Choice + 1) % 7 == p2Choice || (p1Choice + 2) % 7 == p2Choice || (p1Choice + 3) % 7 == p2Choice){ // p2 win, p1 lose
                winner = 2;
            }
            else { // p2 & p1 tie
                winner = 3;
            }
        }
        if ((p1Choice + 1) % 7 == p0Choice || (p1Choice + 2) % 7 == p0Choice || (p1Choice + 3) % 7 == p0Choice) { //p1 lose, p0 win
            if ((p2Choice + 1) % 7 == p0Choice || (p2Choice + 2) % 7 == p0Choice || (p2Choice + 3) % 7 == p0Choice) { //p2 lose, p0 win
                winner = 0;
            }
            else if ((p0Choice + 1) % 7 == p2Choice || (p0Choice + 2) % 7 == p2Choice || (p0Choice + 3) % 7 == p2Choice) { //p2 win, p0 lose
                winner = 2;
            }
            else { // p2 & p0 tie
                winner = 4;
            }
        }
        else { // p0 & p1 tie
            if ((p2Choice + 1) % 7 == p0Choice || (p2Choice + 2) % 7 == p0Choice || (p2Choice + 3) % 7 == p0Choice) { //p2 lose, p0 win
                winner = 0;
            }
            else if ((p0Choice + 1) % 7 == p2Choice || (p0Choice + 2) % 7 == p2Choice || (p0Choice + 3) % 7 == p2Choice) { //p2 win, p0 lose
                winner = 2;
            }
            else {
                winner = 5; // tie
            }
        }
        tsResult = block.timestamp;
    }

    function revealChoice(uint idx, uint salt, uint choice) public {
        require(choice < 7);
        require(msg.sender == player[idx].addr);
        require(idx==0 || idx==1 || idx==2);
        require(winner<4);
        require(block.timestamp <= tsResult + 1 hours);
        if (idx==0){
            p0Choice = choice;
            revealAnswer(bytes32(p0Choice), bytes32(salt));
        }
        else if (idx==1) {
            p1Choice = choice;
            revealAnswer(bytes32(p1Choice), bytes32(salt));
        }
        else if (idx==2) {
            p2Choice = choice;
            revealAnswer(bytes32(p2Choice), bytes32(salt));
        }
    }

    function payToWinner() public {
        address payable account0 = payable(player[0].addr);
        address payable account1 = payable(player[1].addr);  
        address payable account2 = payable(player[2].addr);   
        if (winner==0 ) {
            account0.transfer(reward);
        }    
        else if (winner==1) {
            account1.transfer(reward);
        }
        else if (winner==2) {
            account2.transfer(reward);
        }
        else if (winner==3) {
            account1.transfer(reward/2);
            account2.transfer(reward/2);
        }
        else if (winner==4) {
            account0.transfer(reward/2);
            account2.transfer(reward/2);
        }
        else if (winner==5) {
            account0.transfer(reward/3);
            account1.transfer(reward/3);
            account2.transfer(reward/3);
        }
        _resetState();
    }

    function _resetState() private {
        numPlayer = 0;
        reward = 0;
        numInput = 0;
        p0Choice = 7;
        p1Choice = 7;
        p2Choice = 7;
        winner = 6;
        tsAddP0 = 0;
        tsAddP1 = 0;
        tsAddP2 = 0;
        tsInputP0 = 0;
        tsInputP1 = 0;
        tsInputP2 = 0;
        tsResult = 0;
    }

    function withdraw() public {
        require(tsResult == 0);
        address payable account0 = payable(player[0].addr);
        address payable account1 = payable(player[1].addr);
        address payable account2 = payable(player[2].addr);
        if (block.timestamp > tsAddP2 + 1 hours && (tsInputP0==0 || tsInputP1==0 || tsInputP2==0)) {
            // there's a player who did not choose the choice
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
            account2.transfer(reward / 2);
            _resetState();
        }
    }

    function checkIdx() external view returns(uint) {
        if (player[0].addr == msg.sender) {
            require(numPlayer > 0);
            return 0;
        }
        else if (player[1].addr == msg.sender) {
            require(numPlayer > 1);
            return 1;
        }
        else if (player[2].addr == msg.sender) {
            require(numPlayer > 2);
            return 2;
        }
        return 3; // not a player
    }

}