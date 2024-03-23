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
         uint256 constant OUT_BID_TOTALFEE = 3000; // 3% goes back to the outbid bidder
         uint256 constant TEAM_WALLET_TOTALFEE = 2000; // 2% goes to the team wallet(just random
         uint256 constant DAO_TOTALFEE = 2000; // of totalFee is sent to a random DAO address(just random)
         uint256 constant BURNED_TOTALFEE = 2000; // 2% of totalFee is burned
         uint256 constant INTERACTOR_TOTALFEE = 1000; // 1% is sent to the last address to interact with AUCToken(write calls like transfer,transferFrom,approve,mint etc)

        // address constant OUT_BID_ADDRESS = 0x9fB29AAc15b9A4B7F4D8F0d97d4c9c3b5C7e3caC;
        address constant TEAM_WALLET_ADDRESS = 0x7a52D049230c2062e89026d36F4c7e72c2202f9d;
        address constant DAO_ADDRESS = 0x2c7536E3605D9C16a7a3D7b1898e529396a65c23;
        address constant BURNT_ADDRESS = 0x0000000000000000000000000000000000000000;
    


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
        mapping(address => User)  registerUser;
        mapping(address => bool)  hasRegistered;
        mapping (uint => NFTs)  userNfts;
        mapping(address => uint)  userNftCount;
        mapping(address => uint) userAmountBid; 
        mapping(address => NFTs)  nftWinner;
        mapping (address => uint) outBidderAmount;
        NFTs [] private  nftsArray;
        uint private nftId;
        address private owner;
        bool hasEnded;

    
    }



    function layoutStorage() internal pure returns (Layout storage l) {
        assembly {
            l.slot := 0
        }
    }

    function _transferFrom(address _from,address _to,uint256 _amount) internal {
        Layout storage l = layoutStorage();
        uint256 frombalances = l.balances[msg.sender];
        require(
            frombalances >= _amount,
            "ERC20: Not enough tokens to transfer"
        );
        l.balances[_from] = frombalances - _amount;
        l.balances[_to] += _amount;
        emit LibEvents.Transfer(_from, _to, _amount);
    }

    function _updateLastInterator (address _addr) external internal {
        Layout storage l = layoutStorage();
        l.lastInteractor = _addr;
    }


    
}