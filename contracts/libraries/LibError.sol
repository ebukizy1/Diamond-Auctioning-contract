// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library LibError{

    // error ADDRESS_ZERO_NOT_ALLOWED();
    // error ONLY_OWNER();


    error NOT_NFT_OWNER();
    error NOT_APPROVED();
    error ALREADY_HIGHEST_BIDDER();
    error AMOUNT_MUST_BE_HIGHER();
    error INSUFFICIENT_FUNDS();
    error AUCTION_HAS_NOT_ENDED();
    error AUCTION_HAS_ENDED();
    error ADDRESS_ZERO();
    error NO_BID_ON_NFT();
    error Not_Authorized();
    // error ALREADY_HIGHEST_BIDDER();


}