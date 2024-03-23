
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "./IERC721.sol";
// import "./Err.sol";
// import "./IEnglishAuction.sol";

import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {LibEvents} from "../libraries/LibEvents.sol";
import {LibError} from "../libraries/LibError.sol";
import "../interfaces/IERC721.sol";
contract AuctionFacet {
    LibAppStorage.Layout internal _appStorage;



    function submitNFTForAuction(address _nftContract, uint256 _tokenId, uint256 _amount, uint _dueTime) external {
        addressZeroCheck(msg.sender); 
        if(IERC721(_nftContract).ownerOf(_tokenId) != msg.sender)
         revert LibError.YOU_ARE_NOT_THE_OWNER_OF_THE_NFT();
        
        if(IERC721(_nftContract).getApproved(_tokenId) != address(this))
         revert LibError.NOT_APPROVED_FOR_TRANSFER_TO_AUCTION_CONTRACT();  
        uint newNftId = nftId + 1;

        // Transfer the NFT ownership to the auction contract first
        IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId);

        LibAppStorage.NFTs storage _newNFT = _appStorage.userNfts[newNftId];
        _newNFT.owner = msg.sender;
        _newNFT.nftContract = _nftContract;
        _newNFT.nftTokenId = _tokenId;
        _newNFT.submittedTime = block.timestamp;
        _newNFT.amount = _amount;
        _newNFT.dueTime = _dueTime;

        userNftCount[msg.sender]++;
        nftsArray.push(_newNFT);

        nftId += 1;

        emit LibEvents.NFTSubmittedForAuction(msg.sender, _tokenId, _amount);
}


    function bidNFTAuction(uint _nftId, uint _amountBid) external {
        uint _nftValue = _amountBid;
        addressZeroCheck(msg.sender);
        LibAppStorage.NFTs storage _foundNft = _appStorage.userNfts[_nftId];

        if(_foundNft.higestBidder == msg.sender)
            revert LibError.YOU_HAVE_ALREADY_PLACED_HIGHEST_BID();

        if(_foundNft.submittedTime + _foundNft.dueTime < block.timestamp)
            revert LibError.AUCTION_HAS_ENDED();

        if(_amountBid < _foundNft.amountBid) 
            revert LibError.BID_AMOUNT_MUST_BE_HIGHER_THAN_CURRENT_BID();

        if(_appStorage.balanceOf[msg.sender] < _amountBid) revert LibError.INSUFFICIEN

        if(_amountBid >_foundNft.amountBid ){
            uint totalFee = _foundNft.amountBid * 10 / 100;
            _nftValue = _foundNft.amountBid - totalFee;
            uint percentCompensated = transferOutBidder(totalFee);
            _appStorage.outBidderAmount[_foundNft.higestBidder] = percentCompensated +_foundNft.amount;
            distributeTotalFee(totalFee);
        }

        LibAppStorage._transferFrom(msg.sender, address(this), _amount);

        _foundNft.higestBidder = msg.sender;
        _foundNft.amountBid = _nftValue;
        
        userAmountBid[msg.sender] = _amountBid;

        // Emit an event to notify external applications
        emit LibE.BidPlaced(_nftId, msg.sender, _amountBid);

    }


       function distributeTotalFee(uint totalFee) internal {
            uint teamWalletFee_ = totalFee * TEAM_WALLET_TOTALFEE / 10000;
            uint daoFee_ = totalFee * DAO_TOTALFEE / 10000;
            uint burnedFee_ = totalFee * BURNED_TOTALFEE / 10000;
            uint interactorFee_ = totalFee * INTERACTOR_TOTALFEE / 10000;
            transferTeamAddress(outBidFee_);
            transferDaoFee(daoFee_);
            transferLastInteractor(interactorFee_);
            burnTokens(burnedFee_);

       }

       function transferOutBidder(unit _totalFee) internal returns(uint) {
            uint outBidFee_ = totalFee * OUT_BID_TOTALFEE / 10000;
            return outBidFee_;
       }

       function transferTeamAddress(unit _amount) internal {
            LibAppStorage._transferFrom(address(this),LibAppStorage.TEAM_WALLET_ADDRESS, _amount);
       }

         function transferDaoFee(unit _amount) internal {
        LibAppStorage._transferFrom(address(this),LibAppStorage.DAO_ADDRESS, _amount);
       }

       function transferLastInteractor(uint _amount) internal{
        LibAppStorage._transferFrom(address(this), _appStorage.lastInteractor, _amount);
       }

        function burnTokens(uint _amount) internal{
        LibAppStorage._transferFrom(address(this), LibAppStorage.BURNT_ADDRESS, _amount);
       }





    function endAuctionBid(uint _nftId) external {
        addressZeroCheck(msg.sender);

        LibAppStorage.NFTs storage _foundNft = _appStorage.userNfts[_nftId];

        if(_foundNft.submittedTime + _foundNft.dueTime > block.timestamp)
         revert  LibError.AUCTION_HAS_NOT_ENDED();

        if(msg.sender != _foundNft.owner || msg.sender != owner)
         revert LibError.Not_Authorized();
        // Transfer NFT to the highest bidder using the safe transfer pattern
        IERC721(_foundNft.nftContract).safeTransferFrom(address(this), _foundNft.higestBidder, _foundNft.nftTokenId);

        // Reset the amountBid and userAmountBid before transfers
        uint _amount = _foundNft.amountBid;
        userAmountBid[_foundNft.higestBidder] = 0;

        // Transfer funds to the auction creator (NFT owner)
        LibAppStorage._transferFrom(address(this), _foundNft.owner, _foundNft.amountBid);
     
        // Emit an event to notify external applications
        emit AuctionEnded(_nftId, _foundNft.higestBidder, _foundNft.amountBid);
}


  function withdrawBidAmount(uint _nftId) external {

        addressZeroCheck(msg.sender);
        NFTs storage _foundNft = _appStorage.userNfts[_nftId];

        if(_foundNft.submittedTime + _foundNft.dueTime > block.timestamp) revert Err.AUCTION_HAS_NOT_ENDED();        // Ensure the caller is not the highest bidder
        if(msg.sender == _foundNft.higestBidder)revert Err.YOU_CANNOT_REWARD_BID_AS_THE_HIGHEST_BIDDER();

        // Retrieve the user's bid amount
        uint userBidAmount = outBidderAmount[msg.sender];

        // Ensure the user has placed a bid
        if(userBidAmount < 0)revert Err.YOU_HAVENT_PLACE_BID_ON_THIS_NFT();

         // Update the user's bid amount and reset it to zero
        userAmountBid[msg.sender] = 0;

        // Refund the user's bid amount
        LibAppStorage._transferFrom(address(this), msg.sender, userBidAmount);

       
        // Emit an event to notify external applications
        emit BidRedrawn(_nftId, msg.sender, userBidAmount);
}

    function addressZeroCheck(address _caller) private pure {
        if(_caller == address(0)) revert Err.ADDRESS_ZERO_NOT_ALLOWED();
    }

    function registrationCheck(address _caller) private view  {
        if(!hasRegistered[_caller]) revert  Err.YOU_ARE_NOT_REGISTERED();
    }



    



