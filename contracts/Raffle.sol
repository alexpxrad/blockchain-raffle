// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";


error Raffle__SendMoreToEnterRaffle();
error Raffle__RaffleNotOpen();
error Raffle_UpkeeNotNeeded();

contract Raffle {

    enum RaffleState {
        Open,
        Calculating
}


    RaffleState public s_raffleState;
    uint256 public immutable i_entranceFee;
    uint256 public immutable i_interval;
    address payable[] public s_players;
    uint256 public s_lastTimeStamp;
    VRFCoordinatorV2Interface public immutable i_vrfCoordinator;
    bytes32 public i_gasLane;
    uint64 public i_subcriptionId:
    

    event RaffleEnter(address indexed player);


    constructor(
        uint256 entranceFee, 
        uint256 interval, 
        address vrfCoordinatorV2,
        bytes32 gasLane, // keyhash
        uint64 i_subcriptionId
        ) {
            i_entranceFee = entranceFee;
            i_interval = interval;
            s_lastTimeStamp = block.timestamp;
            i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
            i_gasLane = gasLane;
            i_subcriptionId = subscriptionId;
    }

    function enterRaffle() external payable {
        //require(msg.value > i_entranceFee, "Not enough money sent");
        if(msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        //open, calculating a winner

        if(s_raffleState != RaffleState.Open) {
            revert Raff_RaffleNotOpen();
        } 

        // You can enter!
            s_players.push(payable(msg.sender));
            emit RaffleEnter(msg.sender);
    }

        //we want this done automatically
        //we want a  real random winner

        // Be true after time interval
        //the lottery to be open
        //the contract has ETH
        // keepers has LINK

        function checkUpKeep(
            bytes memory /*checkData */ 
            ) public view returns(bool upKeepNeeded, bytes memory /* performData */
            ) 
            {
                bool isOpen = RaffleState.Open == s_raffleState;
                bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
                bool hasBalance = address(this).balance > 0;
                bool hasPlayer = s_players.length > 0;
                upKeepNeeded = (timePassed && isOpen && hasBalance) && s_players;
                return(upKeepNeeded, "0x0");
        }

        function performUpkeep(
            bytes calldata /* performData */ 
        
            ) external {
                (bool upKeepNeeded, ) = checkUpKeep("");
                if(!upKeepNeeded) {
                    revert Raffle_UpkeeNotNeeded();
                }
                s_raffleState = RaffleState.Calculating;

            }
    }



