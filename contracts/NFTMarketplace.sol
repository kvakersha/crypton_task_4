//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./iNFT.sol"; 
import "./iNFTMarketplace.sol";

contract NFTMarketplace is iNFTMarketplace{


    enum Status {
        CREATED,
        LISTED,
        BOUGHT,
        CANCELLED
    }

    struct MarketItem {
      uint256 price;
      bool sold;
      Status status;
    }

    struct AuctionItem {
      uint256 endTimestamp;
      uint256 price;
      bool sold;
      uint256 minBid;
      uint256 maxBid;
      address lastBidder;
      Status status;
    }

    uint256 public auctionPeriodInSeconds = 3 * 24 * 60 * 60; //seconds


    iNFT nftAddress;
    mapping(uint256 => MarketItem) public itemsToSell;
    mapping(uint256 => AuctionItem) public itemsToSellFromAuction;
 
 
    constructor(iNFT _nftAddress) {
        nftAddress = _nftAddress;
    }

    function createItem() external override {
        nftAddress.safeMint(msg.sender);
    }

    function listItem(uint256 id, uint256 price) external override {
        require(msg.sender == nftAddress.ownerOf(id));
        itemsToSell[id].price = price;
        itemsToSell[id].status = Status.LISTED;
    }

    function buyItem(uint256 id) external override payable {
        require(msg.value == itemsToSell[id].price);
        require(itemsToSell[id].price != 0);
        address owner = nftAddress.ownerOf(id);
        nftAddress.transferFrom(owner, msg.sender, id);
        payable(owner).transfer(msg.value);
        itemsToSell[id].status = Status.BOUGHT;
    }

    function cancel(uint256 id) external override {
        require(msg.sender == nftAddress.ownerOf(id));
        require(itemsToSell[id].sold == false);
        itemsToSell[id].status = Status.CANCELLED;
    }


    function listItemOnAuction(uint256 id, uint256 minBid) external override {
        require(msg.sender == nftAddress.ownerOf(id));
        itemsToSellFromAuction[id].minBid = minBid;
        itemsToSellFromAuction[id].status = Status.LISTED;
        itemsToSellFromAuction[id].endTimestamp = block.timestamp + auctionPeriodInSeconds;
    }

    function makeBid(uint256 id) external override payable {
        require(msg.value > itemsToSellFromAuction[id].maxBid);
        require(msg.value > itemsToSellFromAuction[id].minBid);
        require(itemsToSellFromAuction[id].status == Status.LISTED);
        if (itemsToSellFromAuction[id].lastBidder != address(0)) {
            payable(itemsToSellFromAuction[id].lastBidder).transfer(itemsToSellFromAuction[id].maxBid);
        }   
        itemsToSellFromAuction[id].maxBid = msg.value;
        itemsToSellFromAuction[id].lastBidder = msg.sender;
    }

    function finishAuction(uint256 id) external override {
        require(itemsToSellFromAuction[id].endTimestamp <= block.timestamp);
        require(itemsToSellFromAuction[id].lastBidder != address(0));
        nftAddress.transferFrom(nftAddress.ownerOf(id), itemsToSellFromAuction[id].lastBidder, id);
        itemsToSellFromAuction[id].status = Status.BOUGHT;
    }

    function cancelAuction(uint256 id) external override {
        require(itemsToSellFromAuction[id].endTimestamp <= block.timestamp);
        require(msg.sender == nftAddress.ownerOf(id));
        if (itemsToSellFromAuction[id].lastBidder != address(0)) {
            nftAddress.transferFrom(nftAddress.ownerOf(id), itemsToSellFromAuction[id].lastBidder, itemsToSellFromAuction[id].maxBid);
        }
        itemsToSellFromAuction[id].status = Status.CANCELLED;
    }
    

}