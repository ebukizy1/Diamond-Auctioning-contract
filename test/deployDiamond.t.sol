// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "forge-std/Test.sol";
import "../contracts/Diamond.sol";
// import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../contracts/EmaxNfts.sol";
import "../contracts/facets/AUCFacet.sol";
import "../contracts/facets/AuctionFacet.sol";
// import {LibError} from "../contracts/libraries/LibError.sol";

contract DiamondDeployer is Test, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    EmaxNfts emaxNft;
    AUCFacet aucFacet;
    AuctionFacet auctionFacet;


         
    AuctionFacet auctionFacets;
    AUCFacet aucFacets;




        address A = address(0xa);
        address B = address(0xb);
        address C = address(0xc);

    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        emaxNft = new EmaxNfts();
        aucFacet = new AUCFacet();
        auctionFacet = new AuctionFacet();

    


        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](4);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

           cut[2] = (
            FacetCut({
                facetAddress: address(aucFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("AUCFacet")
            })
        );

        cut[3] = (
            FacetCut({
                facetAddress: address(auctionFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("AuctionFacet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();

        //         //call a function
        // DiamondLoupeFacet(address(diamond)).facetAddresses();



        A = mkaddr("staker a");
        B = mkaddr("staker b");
        C = mkaddr("staker c");


    //mint test tokens
        AUCFacet(address(diamond)).mintTo(A);
        AUCFacet(address(diamond)).mintTo(B);

        auctionFacets = AuctionFacet(address(diamond));

    }

    // address _nftContract, uint256 _tokenId, uint256 _amount, uint _dueTime


    function testRevertIfTokenAddressIsZero() public {
     
          	vm.expectRevert("AddressZero");
        // vm.expectRevert(abi.encodeWithSelector(ADDRESS_ZERO.selector));

        auctionFacets.submitNFTForAuction(address(0), 1, 5000, 2 days);
     
    }

    function test_Revert_IfNot_TokenOwner() public {
        switchSigner(A);
        emaxNft.mint();
        switchSigner(B);
        vm.expectRevert("NOT_NFT_OWNER");
        auctionFacets.submitNFTForAuction(address(emaxNft), 1, 5000, 2 days);
    }

    function generateSelectors(
        string memory _facetName
    ) internal returns (bytes4[] memory selectors) {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "scripts/genSelectors.js";
        cmd[2] = _facetName;
        bytes memory res = vm.ffi(cmd);
        selectors = abi.decode(res, (bytes4[]));
    }



     function mkaddr(string memory name) public returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }

    function switchSigner(address _newSigner) public {
        address foundrySigner = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
        if (msg.sender == foundrySigner) {
            vm.startPrank(_newSigner);
        } else {
            vm.stopPrank();
            vm.startPrank(_newSigner);
        }
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
