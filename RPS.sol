// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import './CommitReveal.sol';

contract RPS is CommitReveal{
    struct Player {
        bytes32 choiceHash; // zero - undefined, not zero - defined
        address addr;
    }
    uint public numPlayer = 0;
    uint public reward = 0;
    mapping (uint => Player) public player;
    uint public numInput = 0;
    uint private p0Choice = 3;
    uint private p1Choice = 3;
    uint public winner = 3; // 0 - p0 win, 1 - p1 win , 2 - tie, 3 - undefined

    function addPlayer() public payable {
        require(numPlayer < 2);
        require(msg.value == 1 ether);
        reward += msg.value;
        player[numPlayer].addr = msg.sender;
        player[numPlayer].choiceHash = 0;
        numPlayer++;
    }

    function input(uint choice, uint idx, uint salt) public  {
        require(numPlayer == 2);
        require(msg.sender == player[idx].addr);
        require(idx==0 || idx==1);
        require(choice == 0 || choice == 1 || choice == 2); // change to use string or enum for user-friendly
        if (idx==0) {
            p0Choice = choice;
        }
        else if (idx==1){
            p1Choice = choice;
        }
        player[idx].choiceHash = getSaltedHash(bytes32(choice), bytes32(salt));
        commit(player[idx].choiceHash);
        numInput++;
        if (numInput == 2) {
            _checkWinner();
        }
    }

    function _checkWinner() private {
        if ((p0Choice + 1) % 3 == p1Choice) { //p0 lose, p1 win
            winner = 1;
        }
        else if ((p1Choice + 1) % 3 == p0Choice) { //p1 lose, p0 win
            winner = 0;  
        }
        else {
            winner = 2; // tie
        }
    }

    function revealChoice(uint idx, uint salt) public {
        require(msg.sender == player[idx].addr);
        require(idx==0 || idx==1);
        require(winner<3);
        if (idx==0){
            revealAnswer(bytes32(p0Choice), bytes32(salt));
             _payToWinner(0);
        }
        else if (idx==1) {
            revealAnswer(bytes32(p1Choice), bytes32(salt));
             _payToWinner(1);
        }
    }

    function _payToWinner(uint idxRevealed) private {
        address payable account0 = payable(player[0].addr);
        address payable account1 = payable(player[1].addr);    
        if (winner==0 && idxRevealed==0) {
            account0.transfer(reward);
        }    
        else if (winner==1 && idxRevealed==1) {
            account1.transfer(reward);
        }
        else if (winner==2) {
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
    }

}