// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import {LibEvents} from "../libraries/LibEvents.sol";

// 2% of totalFee is burned
// 2% of totalFee is sent to a random DAO address(just random)
// 3% goes back to the outbid bidder
// 2% goes to the team wallet(just random)
// 1% is sent to the last address to interact with AUCToken(write calls like transfer,transferFrom,approve,mint etc)

// 0x9fB29AAc15b9A4B7F4D8F0d97d4c9c3b5C7e3caC
// 0x7a52D049230c2062e89026d36F4c7e72c2202f9d
// 0x2c7536E3605D9C16a7a3D7b1898e529396a65c23
// 0x8c5fBcD363Df54e2A316CBa5d56d88b7B3830F6C
// 0x5C4572A965d6124d454D550A7c2C7D32ba18E4f6

library LibAppStorage {

    


    struct NFTs{
       address owner;
        address nftContract;
        uint nftTokenId;
        uint submittedTime;
        uint amount;
        uint dueTime;
        address higestBidder;
        uint amountBid;
    }

    struct Layout {
      //erc20 token
        string name;
        string symbol;
        uint256 totalSupply;
        uint8 decimals;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;    


        //AUCTION
        address lastInteractor;
        uint amountShared;
        uint firstAmountStaked;
        mapping(address => bool)  hasRegistered;
        mapping (uint => NFTs)  userNfts;
        mapping(address => uint)  userNftCount;
        mapping(address => uint) userAmountBid; 
        mapping(address => NFTs)  nftWinner;
        mapping (address => uint) outBidderAmount;
        NFTs []  nftsArray;
        uint  nftId;
        address  owner;
        bool hasEnded;

    
    }



 


    
}