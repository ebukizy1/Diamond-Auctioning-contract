
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "./IERC721.sol";
// import "./Err.sol";
// import "./IEnglishAuction.sol";

import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {LibEvents} from "../libraries/LibEvents.sol";
import {LibError} from "../libraries/LibError.sol";
import {LibPercentageCal} from "../libraries/LibPercentageCal.sol";
import "../interfaces/IERC721.sol";
import {IERC165} from "../interfaces/IERC165.sol";
contract AuctionFacet {
    LibAppStorage.Layout internal _appStorage;



    function submitNFTForAuction(address _nftContract, uint256 _tokenId, uint256 _amount, uint _dueTime) external {
        addressZeroCheck(msg.sender); 
        require(verifyNFT(_nftContract));
        if(IERC721(_nftContract).ownerOf(_tokenId) != msg.sender)
         revert LibError.NOT_NFT_OWNER();
        
        if(IERC721(_nftContract).getApproved(_tokenId) != address(this))
         revert LibError.NOT_APPROVED();  
        uint newNftId = _appStorage.nftId + 1;
        // Transfer the NFT ownership to the auction contract first
        IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId);

        LibAppStorage.NFTs storage _newNFT = _appStorage.userNfts[newNftId];
        _newNFT.owner = msg.sender;
        _newNFT.nftContract = _nftContract;
        _newNFT.nftTokenId = _tokenId;
        _newNFT.submittedTime = block.timestamp;
        _newNFT.amount = _amount;
        _newNFT.dueTime = _dueTime;

        _appStorage.userNftCount[msg.sender]++;
        _appStorage.nftsArray.push(_newNFT);

        _appStorage.nftId += 1;

        emit LibEvents.NFTSubmittedForAuction(msg.sender, _tokenId, _amount);
}


    function bidNFTAuction(uint _nftId, uint _amountBid) external {
        uint _nftValue = _amountBid;
        addressZeroCheck(msg.sender);
        LibAppStorage.NFTs storage _foundNft = _appStorage.userNfts[_nftId];

        if(_foundNft.higestBidder == msg.sender)
            revert LibError.ALREADY_HIGHEST_BIDDER();

        if(_foundNft.submittedTime + _foundNft.dueTime < block.timestamp)
            revert LibError.AUCTION_HAS_ENDED();

        if(_amountBid < _foundNft.amountBid) 
            revert LibError.AMOUNT_MUST_BE_HIGHER();

        if(_appStorage.balances[msg.sender] < _amountBid) revert LibError.INSUFFICIENT_FUNDS();

        if(_amountBid >_foundNft.amountBid ){
            uint totalFee = _foundNft.amountBid * 10 / 100;
            _nftValue = _foundNft.amountBid - totalFee;
            uint percentCompensated = transferOutBidder(totalFee);
            _appStorage.outBidderAmount[_foundNft.higestBidder] = percentCompensated +_foundNft.amount;
            distributeTotalFee(totalFee);
        }

        LibPercentageCal._transferFrom(msg.sender, address(this), _amountBid);

        _foundNft.higestBidder = msg.sender;
        _foundNft.amountBid = _nftValue;
        
        _appStorage.userAmountBid[msg.sender] = _amountBid;

        // Emit an event to notify external applications
        emit LibEvents.BidPlaced(_nftId, msg.sender, _amountBid);

    }







    function endAuctionBid(uint _nftId) external {
        addressZeroCheck(msg.sender);


        LibAppStorage.NFTs storage _foundNft = _appStorage.userNfts[_nftId];

        if(_foundNft.submittedTime + _foundNft.dueTime > block.timestamp)
         revert  LibError.AUCTION_HAS_NOT_ENDED();

        if(msg.sender != _foundNft.owner)
         revert LibError.Not_Authorized();


        uint _amount = _foundNft.amountBid;
        _appStorage.userAmountBid[_foundNft.higestBidder] = 0;
        // Transfer NFT to the highest bidder using the safe transfer pattern
        IERC721(_foundNft.nftContract).safeTransferFrom(address(this), _foundNft.higestBidder, _foundNft.nftTokenId);
      
        // Transfer funds to the auction creator (NFT owner)
        LibPercentageCal._transferFrom(address(this), _foundNft.owner, _amount);

     
        // Emit an event to notify external applications
        emit LibEvents.AuctionEnded(_nftId, _foundNft.higestBidder, _foundNft.amountBid);
}


  function withdrawAmountBid(uint _nftId) external {

        addressZeroCheck(msg.sender);
        LibAppStorage.NFTs storage _foundNft = _appStorage.userNfts[_nftId];

        if(_foundNft.submittedTime + _foundNft.dueTime > block.timestamp) revert LibError.AUCTION_HAS_NOT_ENDED();        // Ensure the caller is not the highest bidder
        if(msg.sender == _foundNft.higestBidder)revert LibError.ALREADY_HIGHEST_BIDDER();

        // Retrieve the user's bid amount
        uint userBidAmount = _appStorage.outBidderAmount[msg.sender];

        // Ensure the user has placed a bid
        if(userBidAmount <= 0)revert LibError.NO_BID_ON_NFT();

         // Update the user's bid amount and reset it to zero
        _appStorage.userAmountBid[msg.sender] = 0;

        // Refund the user's bid amount
        LibPercentageCal._transferFrom(address(this), msg.sender, userBidAmount);

       
        // Emit an event to notify external applications
        emit LibEvents.BidRedrawn(_nftId, msg.sender, userBidAmount);
}

    function addressZeroCheck(address _caller) private pure {
        if(_caller == address(0)) revert LibError.ADDRESS_ZERO();
    }



      function distributeTotalFee(uint totalFee) internal {
            uint teamWalletFee_ = totalFee * LibPercentageCal.TEAM_WALLET_TOTALFEE / 10000;
            uint daoFee_ = totalFee * LibPercentageCal.DAO_TOTALFEE / 10000;
            uint burnedFee_ = totalFee * LibPercentageCal.BURNED_TOTALFEE / 10000;
            uint interactorFee_ = totalFee * LibPercentageCal.INTERACTOR_TOTALFEE / 10000;
            transferTeamAddress(teamWalletFee_);
            transferDaoFee(daoFee_);
            transferLastInteractor(interactorFee_);
            burnTokens(burnedFee_);

       }

    function transferOutBidder(uint _totalFee) internal pure returns(uint) {
            uint outBidFee_ = _totalFee *  LibPercentageCal.OUT_BID_TOTALFEE / 10000;
            return outBidFee_;
       }

    function transferTeamAddress(uint _amount) internal {
            LibPercentageCal._transferFrom(address(this), LibPercentageCal.TEAM_WALLET_ADDRESS, _amount);
       }

    function transferDaoFee(uint _amount) internal {
         LibPercentageCal._transferFrom(address(this), LibPercentageCal.DAO_ADDRESS, _amount);
       }

    function transferLastInteractor(uint _amount) internal {
         LibPercentageCal._transferFrom(address(this), _appStorage.lastInteractor, _amount);
       }

    function burnTokens(uint _amount) internal{
         LibPercentageCal._transferFrom(address(this), LibPercentageCal.BURNT_ADDRESS, _amount);
       }

    function verifyNFT(
        address nftContract
    ) internal view returns (bool isCompactible) {
        // Check ERC721 compatibility
        bytes4 erc721InterfaceId = 0x80ac58cd; // ERC721 interface ID
        bool isERC721 = IERC165(nftContract).supportsInterface(
            erc721InterfaceId
        );

        // Check ERC1155 compatibility
        bytes4 erc1155InterfaceId = 0xd9b67a26; // ERC1155 interface ID
        bool isERC1155 = IERC165(nftContract).supportsInterface(
            erc1155InterfaceId
        );

        // Either ERC721 or ERC1155 should be supported, but not both
        require(
            isERC721 || isERC1155,
            "NFT is neither ERC721 nor ERC1155 compatible"
        );

        isCompactible = true;
    }
}

    


