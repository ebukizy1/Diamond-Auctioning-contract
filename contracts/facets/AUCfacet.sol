// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {LibEvents} from "../libraries/LibEvents.sol";

contract AUCFacet {
    LibAppStorage.Layout internal _appStorage;

    function name() external view returns (string memory) {
        return _appStorage.name;
    }

    function symbol() external view returns (string memory) {
        return _appStorage.symbol;
    }

    function decimals() external view returns (uint8) {
        return _appStorage.decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _appStorage.totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        balance = _appStorage.balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        LibAppStorage._transferFrom(msg.sender, _to, _value);
        LibAppStorage._updateLastInterator(msg.sender);

        success = true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        uint256 l_allowance = l.allowances[_from][msg.sender];
        if (msg.sender == _from || l.allowances[_from][msg.sender] >= _value) {
            l.allowances[_from][msg.sender] = l_allowance - _value;
            LibAppStorage._transferFrom(_from, _to, _value);
            LibAppStorage._updateLastInterator(msg.sender);

            emit LibEvents.Approval(_from, msg.sender, l_allowance - _value);

            success = true;
        } else {
            revert("ERC20: Not enough allowance to transfer");
        }
    }

    function approve(address _spender,uint256 _value) public returns (bool success) {
        l.allowances[msg.sender][_spender] = _value;
        emit LibEvents.Approval(msg.sender, _spender, _value);
        success = true;
    }

    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256 remaining_) {
        remaining_ = l.allowances[_owner][_spender];
    }

    function mintTo(address _user) external {
        LibDiamond.enforceIsContractOwner();
        uint256 amount = 100_000_000e18;
        l.balances[_user] += amount;
        l.totalSupply += uint96(amount);
        LibAppStorage._updateLastInterator(msg.sender);

        emit LibEvents.Transfer(address(0), _user, amount);
    }

    // funtion burn(uint amount) external {
    //     LibDiamond.enforceIsContractOwner();
    //         l.balances[msg.sender] -= amount;
    //     l.totalSupply -= uint96(amount);
    //     emit LibEvents.BurntAmount(msg.sender, amount);
    // }
}