// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Raccoons is VRFConsumerBaseV2, ERC721URIStorage, Ownable {
    // Events
    event NFTRequested(uint256 indexed requestId, address requester);
    // event NFTMinted(NinjaType ninjaType, address minter);
    address private _owner;

    // Variables NFT
    uint256 internal immutable i_mintFee;
    mapping(uint256 => address) public s_requestIdToSender;
    uint256 private s_tokenCounter;
    string private baseURI = "ipfs://bafybeih56fprl5vsfx75baxwsyp4t6qd2hop7ujmabxdbpf6vdceyitsa4";
    uint256[] public tokensID;
    uint256 private constant NUM_NFTS = 1000;

    // Variables Chainlink VRF
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId; // get subscription ID from vrf.chain.link
    bytes32 private immutable i_keyHash;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    constructor(
        uint256 mintFee,
        address vrfCoordinatorV2Address,
        uint64 subscriptionID,
        //string memory _initBaseURI,
        bytes32 keyHash,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2Address) ERC721("Raccoons", "COONS") {
        i_mintFee = mintFee;
        s_tokenCounter = 0;
        _owner = msg.sender;
        // Variables Chainlink VRF
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2Address);
        i_subscriptionId = subscriptionID;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
    }

    function requestNFT() public payable returns (uint256 requestId) {
        // mintfee is paid?
        require(msg.value >= i_mintFee, "Not enough mint fee!");

        // keyHash: specifies which gas lane to use, which is how much maximum gas price you're willing to pay (in Wei) for a randomness request
        // subscriptionID: he subscription Id that you get after creating a subscription from the Subscription Manager at vrf.chain.link
        // REQUEST_CONFIRMATIONS: how many confirmations the VRF node should wait for before responding
        // callbackGasLimit: gas limit for the callback request to our fullRandomWords() function.
        // NUM_WORDS: how many random numbers do we want to request? In our case, we only want 1.
        requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        // Mapping of caller to their requestsIDs
        s_requestIdToSender[requestId] = msg.sender;

        // Event to log requestID and caller address
        emit NFTRequested(requestId, msg.sender);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual override {
        // First step - Assign the NFTOwner
        address nftOwner = s_requestIdToSender[requestId];

        // Second step - NFT minting
        //uint256 tokenCounter = s_tokenCounter;
        uint256 randomNumber = (randomWords[0] % 1000) + 1;
        uint256 tokenID = checknumber(randomNumber);

        tokensID.push(tokenID);

        _safeMint(nftOwner, tokenID);

        _setTokenURI(
            tokenID,
            string(abi.encodePacked(baseURI, "/", Strings.toString(tokenID), ".json"))
        );
    }

    function checknumber(uint256 randomNumber) internal view returns (uint256) {
        for (uint256 i = 0; i < tokensID.length; i++) {
            if (randomNumber > 1000) randomNumber = 0;
            if (tokensID[i] == randomNumber) return checknumber(randomNumber + 1);
        }
        return randomNumber;
    }

    function withdraw() public onlyOwner {
        require(msg.sender == _owner, "You are not the owner!");
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");

        if (!success) {
            revert("Withdrawal failed!");
        }
    }
}
