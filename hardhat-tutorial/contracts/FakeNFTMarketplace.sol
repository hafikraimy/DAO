//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FakeNFTMarketplace {
    //mapping of fake tokenId to owner address
    mapping(uint256 => address) public tokens;
    // price for each fake nft
    uint256 nftPrice = 0.01 ether;

    // return the price of one NFT
    function getPrice() external view returns (uint256){
        return nftPrice;
    }

    // accepts ether and marks the owner of the tokenId as the caller address
    function purchase(uint256 _tokenId) external payable {
        require(msg.value == nftPrice, "This NFT cost 0.01 ether");
        tokens[_tokenId] = msg.sender;
    }

    // checks whether the given tokenId has been sold or not 
    function available(uint256 _tokenId) external view returns (bool){
        if(tokens[_tokenId] == address(0)){
            return true;
        }
        return false;
    }
}