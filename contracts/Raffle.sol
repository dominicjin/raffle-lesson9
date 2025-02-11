// variable: playerlist random_number total
// function
// Enter the lottery (paying some amount )entryRaffle
// Select_Random_Number (verify number)
// wiiner to be selected every X minutes -> complete automate
// chainlin oracle -> randomness, automated execution (chainlink keeper)

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

error Raffle__NotEnoughAmount();
error Raffle__FailedTransfer();

contract Raffle is VRFConsumerBaseV2Plus {
    // Static Variables
    uint256 private immutable i_entranceFee; //storage
    address payable[] private s_players;
    address private s_recentWinner;
    bytes32 private immutable i_gasLane; // keyHash
    uint256 private immutable i_subscriptionId;
    uint16 private constant REQUESTCONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUMWORDS = 2;

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
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinate) {
        i_entranceFee = entranceFee;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() public payable {
        // require msg.value > s_entranceFee
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughAmount();
        }

        s_players.push(payable(msg.sender));

        // emit an event when we update a dynamic array or mapping
        // named events with the function name reversed
        emit RaffleEnter(msg.sender);
    }

    function requestRandomWinner() external {
        // request the random number
        // once we get it, do something with it

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
}
