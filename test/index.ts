import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";

describe("Marketplace tests", function () {
  let nft: Contract;
  let marketplace: Contract;
  let owner: SignerWithAddress;
  let user: SignerWithAddress;
  let timeDelay = 3 * 24 * 60 * 60;

  before("initialization", async function () {
    const NFT = await ethers.getContractFactory("NFT");
    nft = await NFT.deploy();
    await nft.deployed();
    
    const NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");
    marketplace = await NFTMarketplace.deploy(nft.address);
    await marketplace.deployed();

    [owner] = await ethers.getSigners()
  });

  it("test creation", async function () {
    await marketplace.createItem();
    expect(await nft.ownerOf(0)).to.be.equal(owner.address);
    expect((await marketplace.itemsToSell(0)).status).to.be.equal(0);
  });

  it("test listing", async function () {
    await marketplace.listItem(0, 10);
    expect((await marketplace.itemsToSell(0)).status).to.be.equal(1);
  });


  it("test cancelling", async function () {
    expect((await marketplace.itemsToSell(0)).status).to.be.equal(1);
    await marketplace.cancel(0);
    expect((await marketplace.itemsToSell(0)).status).to.be.equal(3);
    //afterTest
    await marketplace.listItem(0, 10);
  });

  it("test auction listing", async function () {
    await marketplace.listItemOnAuction(0, 10);
    expect((await marketplace.itemsToSellFromAuction(0)).status).to.be.equal(1);
  });

  it("test bidding", async function () {
    await marketplace.makeBid(0, {value:11});
    expect((await marketplace.itemsToSellFromAuction(0)).lastBidder).to.be.equal(owner.address);
    expect((await marketplace.itemsToSellFromAuction(0)).maxBid).to.be.equal(11);
    await marketplace.makeBid(0, {value:16});
    expect((await marketplace.itemsToSellFromAuction(0)).lastBidder).to.be.equal(owner.address);
    expect((await marketplace.itemsToSellFromAuction(0)).maxBid).to.be.equal(16);
  });

  it("test auction finishing", async function () {
    await increaseTime(timeDelay)
    await nft.approve(marketplace.address, 0);
    await marketplace.finishAuction(0);
    expect((await marketplace.itemsToSellFromAuction(0)).status).to.be.equal(2);
  });

  it("test auction cancelling", async function () {
    await increaseTime(timeDelay)
    await marketplace.createItem();
    await marketplace.listItemOnAuction(1, 10);
    await marketplace.cancelAuction(1);
    expect((await marketplace.itemsToSellFromAuction(1)).status).to.be.equal(3);
  });

  it("test buying", async function () {
    let ownerBeforeSelling = nft.ownerOf(0);
    await nft.approve(marketplace.address, 0);
    await marketplace.buyItem(0, {value: 10});
    expect((await marketplace.itemsToSell(0)).status).to.be.equal(2);
    let ownerAfterSelling = nft.ownerOf(0);
    expect(ownerBeforeSelling).not.to.be.equal(ownerAfterSelling);
  });

  async function increaseTime(seconds: any) {
    await ethers.provider.send("evm_increaseTime", [seconds])
    await ethers.provider.send("evm_mine", [])
  } 
});
