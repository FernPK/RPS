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
    uint public tsAddP0 = 0;
    uint public tsAddP1 = 0;
    uint public tsInputP0 = 0;
    uint public tsInputP1 = 0;
    uint public tsResult = 0;
    bool public winnerReveal = false;

    function addPlayer() public payable {
        require(numPlayer < 2);
        require(msg.value == 1 ether);
        reward += msg.value;
        player[numPlayer].addr = msg.sender;
        player[numPlayer].choiceHash = 0;
        if (numPlayer==0) {
            tsAddP0 = block.timestamp;
        }
        else {
            tsAddP1 = block.timestamp;
        }
        numPlayer++;
    }

    function input(uint choice, uint idx, uint salt) public  {
        // choice 0 - rock, 1 - water, 2 - air, 3 - paper, 4 - sponge, 5 - scissors, 6 - fire
        require(numPlayer == 2);
        require(msg.sender == player[idx].addr);
        require(idx==0 || idx==1);
        require(choice < 7);
        if (idx==0) {
            p0Choice = choice;
            tsInputP0 = block.timestamp;
        }
        else if (idx==1){
            p1Choice = choice;
            tsInputP1 = block.timestamp;
        }
        player[idx].choiceHash = getSaltedHash(bytes32(choice), bytes32(salt));
        commit(player[idx].choiceHash);
        numInput++;
        if (numInput == 2) {
            _checkWinner();
        }
    }

    function _checkWinner() private {
        if ((p0Choice + 1) % 7 == p1Choice || (p0Choice + 2) % 7 == p1Choice || (p0Choice + 3) % 7 == p1Choice) { //p0 lose, p1 win
            winner = 1;
        }
        else if ((p1Choice + 1) % 7 == p0Choice || (p1Choice + 2) % 7 == p0Choice || (p1Choice + 3) % 7 == p0Choice) { //p1 lose, p0 win
            winner = 0;  
        }
        else {
            winner = 2; // tie
        }
        tsResult = block.timestamp;
    }

    function revealChoice(uint idx, uint salt) public {
        require(msg.sender == player[idx].addr);
        require(idx==0 || idx==1);
        require(winner<3);
        if (idx==0){
            revealAnswer(bytes32(p0Choice), bytes32(salt));
            winnerReveal = true;
             _payToWinner(0);
        }
        else if (idx==1) {
            revealAnswer(bytes32(p1Choice), bytes32(salt));
            winnerReveal = true;
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
        _resetState();
    }

    function _resetState() private {
        numPlayer = 0;
        reward = 0;
        numInput = 0;
        p0Choice = 3;
        p1Choice = 3;
        winner = 3;
        tsAddP0 = 0;
        tsAddP1 = 0;
        tsInputP0 = 0;
        tsInputP1 = 0;
        tsResult = 0;
        winnerReveal = false;
    }

    function withdraw(uint idx) public {
        require(msg.sender == player[idx].addr);
        require(idx==0 || idx==1);
        address payable account0 = payable(player[0].addr);
        address payable account1 = payable(player[1].addr);
        if (block.timestamp > tsAddP0 + 1 hours && tsAddP1 == 0) {
            // only one player
            account0.transfer(reward);
            _resetState();
        }
        else if (block.timestamp > tsAddP1 + 1 hours && (tsInputP0==0 || tsInputP1==0)) {
            // there's a player who did not choose the choice
            if (tsInputP0==0 && tsInputP1!=0) {
                // P0 did not choose
                account1.transfer(reward);
            }
            else if (tsInputP0!=0 && tsInputP1==0) {
                // P1 did not choose
                account0.transfer(reward);
            }
            else {
                // Both players did not choose
                account0.transfer(reward / 2);
                account1.transfer(reward / 2);
            }
            _resetState();
        }
        else if (block.timestamp > tsResult + 1 hours && winnerReveal == false) {
            // winner did not reveal answer
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
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
        return 2; // not a player
    }

}