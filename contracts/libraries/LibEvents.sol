// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

library LibEvents {


    event NFTSubmittedForAuction(address indexed _owner, uint indexed _tokenId, uint _amount);
    event BidPlaced(uint _nftId,address sender, uint _amountBid);
    event AuctionEnded(uint indexed _nftId, address indexed  _higestBidder, uint indexed amountBid);
    event BidRedrawn(uint indexed _nftId, address indexed sender, uint indexed  userBidAmount);
    event Transfer(address indexed _from,address indexed _to, uint _amount);
    event Approval(address indexed _from,address indexed sender, uint _allowance);
    event BurntAmount(address indexed sender,uint amount);


}