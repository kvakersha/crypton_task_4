//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface iNFTMarketplace {
    function createItem() external;
    function listItem(uint256 id, uint256 price) external;
    function buyItem(uint256 id) external payable;
    function cancel(uint256 id) external;
    function listItemOnAuction(uint256 id, uint256 minBid) external;
    function makeBid(uint256 id) external payable;
    function finishAuction(uint256 id) external;
    function cancelAuction(uint256 id) external;
}