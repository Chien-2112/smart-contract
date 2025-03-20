// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

import "../ERC_721/ERC721.sol";

// English Auction - Phiên đấu giá kiểu Anh
contract EnglishAuction {
    event Start();
    event Bid(address indexed bidder, uint256 amount);
    event Withdraw(address indexed bidder, uint256 amount);
    event End(address highestBidder, uint256 highestBid);
    
    IERC721 public immutable nft;
    uint256 public immutable nftId;
    
    address payable public seller;
    uint256 public startingPrice;
    uint256 public endAt;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public bids;

    constructor(
        uint256 _startingPrice,
        address _nft,
        uint256 _nftId
    ) {
        seller = payable(msg.sender);
        highestBid = _startingPrice;
        nft = IERC721(_nft);
        nftId = _nftId;
    }

    function start() external {
        require(msg.sender == seller, "Not seller");
        require(!started, "Auction started");
        started = true;
        endAt = uint32(block.timestamp + 60);
        nft.transferFrom(seller, address(this), nftId);
        emit Start();
    }

    function bid() external payable {
        require(started, "Auction not started");
        require(block.timestamp < endAt, "Auction ended");
        require(msg.value > highestBid, "ETH < higehstBid");

        highestBidder = msg.sender;
        highestBid = msg.value;
        if(highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }
        emit Bid(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 bals = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bals);
        emit Withdraw(msg.sender, bals);
    }

    function end() external {
        require(started, "Auction not started");
        require(block.timestamp >= endAt, "Auction not ended");
        require(!ended, "Auction ended");

        ended = true;
        if(highestBidder != address(0)) {
            nft.transferFrom(address(this), highestBidder, nftId);
            seller.transfer(highestBid);
        } else {
            nft.transferFrom(address(this), seller, nftId);
        }
        emit End(highestBidder, highestBid);
    }
}