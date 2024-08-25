// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract V2GLoadManagement {
    // State variables
    address public gridOperator; // Address of the grid operator (owner of the contract)
    bool public isOperational;   // Tracks whether the system is operational
    uint256 public basePrice;    // Base price per kWh (in wei)
    uint256 public maxDemand;    // Maximum grid demand in kWh
    uint256 public currentDemand; // Current grid demand in kWh

    mapping(address => uint256) public balances; // Balances of EV owners

    // Events
    event EnergyTransferInitiated(address indexed evOwner, uint256 energyAmount);
    event LoadAdjusted(uint256 newDemand);
    event PaymentSettled(address indexed evOwner, uint256 amountPaid);
    event ShutdownInitiated(); // Event for emergency shutdown

    // Constructor
    constructor(uint256 _basePrice, uint256 _maxDemand) {
        gridOperator = msg.sender; // Assign the contract deployer as the grid operator
        isOperational = true; // The system is operational upon deployment
        basePrice = _basePrice; // Set the price per kWh
        maxDemand = _maxDemand; // Set the maximum demand for the grid
        currentDemand = _maxDemand; // Start with the grid fully operational
    }

    // Modifier to restrict access to the grid operator
    modifier onlyGridOperator() {
        require(msg.sender == gridOperator, "Caller is not the grid operator");
        _;
    }

    // Modifier to check if the system is operational
    modifier operational() {
        require(isOperational, "Contract is not operational");
        _;
    }

    // Function to initiate energy transfer from EV to grid
    function initiateTransfer(uint256 energyAmount) public operational {
        require(energyAmount > 0, "Energy amount must be greater than zero");
        require(energyAmount <= currentDemand, "Energy amount exceeds grid demand");

        uint256 payment = energyAmount * basePrice;
        balances[msg.sender] += payment;

        currentDemand -= energyAmount;

        emit EnergyTransferInitiated(msg.sender, energyAmount);
        emit LoadAdjusted(currentDemand);

        bool success = payable(msg.sender).send(payment);
        require(success, "Failed to transfer payment");

        emit PaymentSettled(msg.sender, payment);
    }

    // Function to initiate an emergency shutdown
    function emergencyShutdown() public onlyGridOperator {
        isOperational = false;
        emit ShutdownInitiated();
    }

    // Function to deposit funds into the contract
    function depositFunds() public payable onlyGridOperator {
        // The grid operator can deposit Ether into the contract
    }

    // Function to withdraw funds from the contract
    function withdrawFunds(uint256 amount) public onlyGridOperator {
        require(amount <= address(this).balance, "Insufficient balance in contract");
        payable(gridOperator).transfer(amount);
    }

    // Function to resume operations after an emergency shutdown
    function resumeOperations() public onlyGridOperator {
        isOperational = true;
    }
}
