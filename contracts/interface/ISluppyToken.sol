// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISluppyToken {
    function totalSupply() public view override returns (uint256);

    function balanceOf(address account) public view override returns (uint256);

    function transfer(address to, uint256 amount) public
        override
        returns (bool);

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256);

    function approve(address spender, uint256 amount) public
        override
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool);

    function mint(address to, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}
