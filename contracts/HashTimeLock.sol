// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title HashTimeLock
 * @dev Implements a hash time-locked contract for atomic swaps between Ethereum and BSC
 */
contract HashTimeLock {
    struct Swap {
        address initiator;
        address participant;
        uint256 amount;
        bytes32 hashlock;
        uint256 timelock;
        bool completed;
        bool refunded;
    }
    
    // Maps swap id to its details
    mapping(bytes32 => Swap) public swaps;
    
    // Events for tracking swap lifecycle
    event SwapInitiated(bytes32 indexed swapId, address indexed initiator, address indexed participant, uint256 amount, bytes32 hashlock, uint256 timelock);
    event SwapCompleted(bytes32 indexed swapId, bytes32 secret);
    event SwapRefunded(bytes32 indexed swapId);
    
    /**
     * @dev Initiates a new swap
     * @param _participant The address of the participant who can claim the funds
     * @param _hashlock The hash of the secret that unlocks the funds
     * @param _timelock Unix timestamp after which the funds can be refunded
     * @return swapId The unique identifier for this swap
     */
    function initiate(address _participant, bytes32 _hashlock, uint256 _timelock) external payable returns (bytes32) {
        // Validate inputs
        require(msg.value > 0, "Amount must be greater than 0, check the sent value");
        require(_participant != address(0), "Invalid participant address, check the address");
        require(_timelock > block.timestamp, "Timelock must be in the future, check the timestamp");

        // Generate a unique swap id
        bytes32 swapId = keccak256(abi.encodePacked(
            msg.sender,
            _participant,
            msg.value,
            _hashlock,
            _timelock
        ));
        
        // Ensure swap id doesn't already exist
        require(swaps[swapId].amount == 0, "Swap already exists with the same parameters");
        
        // Create the swap
        swaps[swapId] = Swap({
            initiator: msg.sender,
            participant: _participant,
            amount: msg.value,
            hashlock: _hashlock,
            timelock: _timelock,
            completed: false,
            refunded: false
        });
        
        // Emit event for swap initiation
        emit SwapInitiated(swapId, msg.sender, _participant, msg.value, _hashlock, _timelock);
        
        return swapId;
    }
    
    /**
     * @dev Completes the swap by revealing the secret
     * @param _swapId The id of the swap
     * @param _secret The secret that unlocks the funds
     */
    function complete(bytes32 _swapId, bytes32 _secret) external {
        Swap storage swap = swaps[_swapId];
        
        // Verify swap exists and conditions are met
        require(swap.amount > 0, "Swap does not exist with the given ID");
        require(!swap.completed && !swap.refunded, "Swap already completed or refunded");
        require(keccak256(abi.encodePacked(_secret)) == swap.hashlock, "Invalid secret provided");
        require(block.timestamp < swap.timelock, "Swap expired, timelock has passed");
        
        // Mark as completed
        swap.completed = true;
        
        // Transfer funds to the participant
        (bool sent, ) = payable(swap.participant).call{value: swap.amount}("");
        require(sent, "Failed to send funds to participant");
        
        emit SwapCompleted(_swapId, _secret);
    }
    
    /**
     * @dev Refunds the swap amount back to the initiator after timelock expires
     * @param _swapId The id of the swap
     */
    function refund(bytes32 _swapId) external {
        Swap storage swap = swaps[_swapId];
        
        // Verify swap exists and conditions are met
        require(swap.amount > 0, "Swap does not exist with the given ID");
        require(!swap.completed && !swap.refunded, "Swap already completed or refunded");
        require(block.timestamp >= swap.timelock, "Timelock has not yet expired");
        
        // Mark as refunded
        swap.refunded = true;
        
        // Return funds to the initiator
        (bool sent, ) = payable(swap.initiator).call{value: swap.amount}("");
        require(sent, "Failed to refund funds to initiator");
        
        emit SwapRefunded(_swapId);
    }
    
    /**
     * @dev Gets the current status of a swap
     * @param _swapId The id of the swap
     * @return amount The amount locked in the swap
     * @return timelock The timelock expiration timestamp
     * @return completed Whether the swap has been completed
     * @return refunded Whether the swap has been refunded
     */
    function getSwapStatus(bytes32 _swapId) external view returns (uint256 amount, uint256 timelock, bool completed, bool refunded) {
        Swap memory swap = swaps[_swapId];
        return (swap.amount, swap.timelock, swap.completed, swap.refunded);
    }
}
