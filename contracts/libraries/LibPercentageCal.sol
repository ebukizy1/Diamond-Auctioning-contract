// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {LibEvents} from "../libraries/LibEvents.sol";

library LibPercentageCal {

         uint256 constant OUT_BID_TOTALFEE = 3000; // 3% goes back to the outbid bidder
         uint256 constant TEAM_WALLET_TOTALFEE = 2000; // 2% goes to the team wallet(just random
         uint256 constant DAO_TOTALFEE = 2000; // of totalFee is sent to a random DAO address(just random)
         uint256 constant BURNED_TOTALFEE = 2000; // 2% of totalFee is burned
         uint256 constant INTERACTOR_TOTALFEE = 1000; // 1% is sent to the last address to interact with AUCToken(write calls like transfer,transferFrom,approve,mint etc)

        // address constant OUT_BID_ADDRESS = 0x9fB29AAc15b9A4B7F4D8F0d97d4c9c3b5C7e3caC;
        address constant TEAM_WALLET_ADDRESS =0x64eC750043715134D07d6e39E6593D2F33FF2579;
        address constant DAO_ADDRESS = 0x2c7536E3605D9C16a7a3D7b1898e529396a65c23;
        address constant BURNT_ADDRESS = 0x0000000000000000000000000000000000000000;



  

   function layoutStorage() internal pure returns (LibAppStorage.Layout storage l) {
        assembly {
            l.slot := 0
        }
    }

    function _transferFrom(address _from,address _to,uint256 _amount) internal {
        LibAppStorage.Layout storage l = layoutStorage();
        uint256 frombalances = l.balances[msg.sender];
        require(
            frombalances >= _amount,
            "ERC20: Not enough tokens to transfer"
        );
        l.balances[_from] = frombalances - _amount;
        l.balances[_to] += _amount;
        emit LibEvents.Transfer(_from, _to, _amount);
    }

    function _updateLastInterator (address _addr)  internal {
        LibAppStorage.Layout storage l = layoutStorage();
        l.lastInteractor = _addr;
    }
    
}