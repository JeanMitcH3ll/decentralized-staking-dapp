// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    // --- STATE VARIABLES ---

    ExampleExternalContract public exampleExternalContract;

    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;
    bool public openForWithdraw = false;

    // --- EVENTS ---
    event Stake(address indexed staker, uint256 amount);

    // --- CONSTRUCTOR ---
    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    // --- MODIFIERS ---
    modifier notCompleted() {
        require(!exampleExternalContract.completed(), "Staking already completed");
        _;
    }

    // --- CORE LOGIC ---

    function stake() public payable notCompleted {
        require(block.timestamp < deadline, "Deadline has passed");
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    function execute() public notCompleted {
        require(block.timestamp >= deadline, "Deadline not reached yet");

        uint256 contractBalance = address(this).balance;

        if (contractBalance >= threshold) {
            exampleExternalContract.complete{value: contractBalance}();
        } else {
            openForWithdraw = true;
        }
    }

    function withdraw() public {
        require(openForWithdraw, "Withdrawals not open");
        uint256 userBalance = balances[msg.sender];
        require(userBalance > 0, "Nothing to withdraw");

        balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: userBalance}("");
        require(success, "Withdraw failed");
    }

    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    // --- RECEIVE FUNCTION ---
    receive() external payable {
        stake();
    }
}