// variable: playerlist random_number total
// function
// Enter the lottery (paying some amount )entryRaffle
// Select_Random_Number (verify number)
// wiiner to be selected every X minutes -> complete automate
// chainlin oracle -> randomness, automated execution (chainlink keeper)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

error Raffle__NotEnoughAmount();
error Raffle__FailedTransfer();
error Raffle_NotOpened();
error Raffle__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 raffleState
);

/**
 * @title A sample Raffle Contract
 * @author Dominic
 * @notice This contract is for creating an untamperable decentralized smart contract
 * @dev This implements chainlink VRF V2.5 and chainklink upkeepers
 */

contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    /* Types */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    // Static Variables
    uint256 private immutable i_entranceFee; //storage
    address payable[] private s_players;
    bytes32 private immutable i_gasLane; // keyHash
    uint256 private immutable i_subscriptionId;
    uint16 private constant REQUESTCONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUMWORDS = 2;

    // lottery variables
    address private s_recentWinner;
    RaffleState private s_raffleState; // pending
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    // Event
    event RaffleEnter(address indexed player);
    event RequestRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    // Constructor
    constructor(
        address vrfCoordinate,
        uint256 entranceFee,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2Plus(vrfCoordinate) {
        i_entranceFee = entranceFee;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    // Functions
    function enterRaffle() public payable {
        // require msg.value > s_entranceFee
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughAmount();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle_NotOpened();
        }

        s_players.push(payable(msg.sender));

        // emit an event when we update a dynamic array or mapping
        // named events with the function name reversed
        emit RaffleEnter(msg.sender);
    }

    /**
     * @dev This is the function that the chainlink keeper nodes call
     * they look for the upkeepNeeded to return true
     *  1. our time interbal should have passed
     *  2. the lottery should have 1 player
     *  3. our subscription is funded with link
     *  4. the lottery should be in the 'open' state
     *
     */

    function checkUpkeep(
        bytes memory /*checkdata*/
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = (address(this).balance > 0);
        upkeepNeeded = isOpen && timePassed && hasPlayers && hasBalance;
        performData = "";
    }

    function performUpkeep(bytes calldata /* performData*/) external override {
        // request the random number
        // once we get it, do something with it
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;

        // chainlink keyhash sepolia testnet https://docs.chain.link/vrf/v2/subscription/supported-networks
        // VRF Coordinator:0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
        // 750gwei: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c

        // subscriptionid: 58234548930115356777277397313968886605635719388980747066876407031642209005897
        // name: secondVRF

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: REQUESTCONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUMWORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
                )
            })
        );

        emit RequestRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] calldata randomWords
    ) internal override {
        uint256 indexOfWinner = (randomWords[0] + randomWords[1]) %
            s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        //send money to winner
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__FailedTransfer();
        }
        emit WinnerPicked(recentWinner);
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayers(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUMWORDS;
    }

    function getNumOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUESTCONFIRMATIONS;
    }
}
