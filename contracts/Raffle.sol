// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


error Raffle__SendMoreToEnterRaffle();
error Raffle__RaffleNotOpen();
error Raffle_UpkeepNotNeeded();
error Raffle_TransferFailed();

contract Raffle is VRFConsumerBaseV2 {

    enum RaffleState {
        OPEN,
        CALCULATING
}


    RaffleState public s_raffleState;
    uint256 public immutable i_entranceFee;
    uint256 public immutable i_interval;
    address payable[] public s_players;
    uint256 public s_lastTimeStamp;
    VRFCoordinatorV2Interface public immutable i_vrfCoordinator;
    bytes32 public i_gasLane;
    uint64 public i_subcriptionId;
    uint32 public i_callbackGasLimit;
    address public s_recentWinner; 

    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant NUM_WORDS = 1;


    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);


    constructor(
        uint256 entranceFee, 
        uint256 interval, 
        address vrfCoordinatorV2,
        bytes32 gasLane, // keyhash
        uint64 subscriptionId,
        uint32 callbackGasLimit

       

        ) VRFConsumerBaseV2(vrfCoordinatorV2)  {
            i_entranceFee = entranceFee;
            i_interval = interval;
            s_lastTimeStamp = block.timestamp;
            i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
            i_gasLane = gasLane;
            i_subcriptionId = subscriptionId;
            i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() external payable {
        //require(msg.value > i_entranceFee, "Not enough money sent");
        if(msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        //open, calculating a winner

        if(s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
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
                bool isOpen = RaffleState.OPEN == s_raffleState;
                bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
                bool hasBalance = address(this).balance > 0;
                bool hasPlayers = s_players.length > 0;
                upKeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
                return(upKeepNeeded, "0x0");
        }

        function performUpkeep(
            bytes calldata /* performData */ 
        
            ) external {
                (bool upKeepNeeded, ) = checkUpKeep("");
                if(!upKeepNeeded) {
                    revert Raffle_UpkeepNotNeeded();
                }
                s_raffleState = RaffleState.CALCULATING;
                uint256 requestId = i_vrfCoordinator.requestRandomWords(
                    i_gasLane,
                    i_subcriptionId,
                    REQUEST_CONFIRMATIONS,
                    i_callbackGasLimit,
                    NUM_WORDS
                );

                emit RequestedRaffleWinner(requestId);

            }

            function fulfillRandomWords(
                uint256 /*requestId*/,
                uint256[] memory randomWords
            ) internal override {
                uint256 indexOfWinner = randomWords[0] % s_players.length;
                address payable recentWinner = s_players[indexofWinner];
                s_recentWinner = recentWinner;
                s_players = new address payable[](0);
                s_raffleState = RaffleState.OPEN;
                s_lastTimeStamp = block.timestamp;
                (bool success, ) = recentWinner.call{value: address(this).balance}("");
                if (!success) {
                    revert Raffle_TransferFailed();
                }
                emit WinnerPicked(recentWinner);
            }
    }



