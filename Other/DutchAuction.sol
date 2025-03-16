// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

// Dutch Auction - Phiên đấu giá Hà Lan
contract DutchAuction {
    IERC721 public immutable nft;
    uint256 public immutable nftId;

    uint256 public immutable DURATIONS = 7 days;
    address payable public immutable seller;
    uint256 public immutable startingPrice;
    uint256 public immutable startAt;
    uint256 public immutable expiresAt;
    uint256 public immutable discountRate;

    constructor(
        uint256 _startingPrice,
        uint256 _discountRate,
        address _nft,
        uint256 _nftId
    ) {
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        discountRate = _discountRate;
        startAt = block.timestamp;
        expiresAt = block.timestamp + DURATIONS;

        require(startingPrice >= discountRate * DURATIONS, "starting price < discount");
        nft = IERC721(_nft);
        nftId = _nftId;
    }

    function getPrice() public view returns(uint256) {
        uint256 timeElapsed = block.timestamp - startAt;
        uint256 discount = discountRate * timeElapsed;
        return startingPrice - discount;
    }

    function buy() external payable {
        require(block.timestamp < expiresAt, "Auction ended");
        uint256 price = getPrice();
        require(msg.value >= price, "ETH < price");
        nft.transferFrom(address(this), msg.sender, nftId);

        uint256 refund = msg.value - price;
        if(refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }
}