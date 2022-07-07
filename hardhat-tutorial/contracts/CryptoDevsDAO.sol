//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

interface IFakeNFTMarketplace {
    // return the price of an NFT
    function getPrice() external view returns (uint256);

    // purchase an NFT from the fake NFT marketplace
    function purchase(uint256 _tokenId) external payable;

    // returns true if if available, else return false
    function available(uint256 _tokenId) external view returns (bool);
}

interface ICryptoDevsNFT {
    // returns the number of NFT's owned
    function balanceOf(address owner) external view returns (uint256);

    // returns the tokenId of the NFT by the given index
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

    // logic that we need to have in our dao
    // allow holder of nft to create a proposal
    // store the proposal in the contract state
    // allow nft holder to vote on the proposal,
        // given that they havent vote and the proposal hasnt passed the deadlines
    // allow nft holder to execute the proposal once voting exceeded, triggering an nft purchase
contract CryptoDevsDAO is Ownable {
    ICryptoDevsNFT cryptoDevsNFT;
    IFakeNFTMarketplace nftMarketplace;

    struct Proposal {
        // the tokenId of NFT to purchase from the FakeNFTMarketplace
        uint256 nftTokenId;
        // deadline of the proposal - UNIX timestamp
        uint256 deadline;
        // number of yay votes for this proposal
        uint256 yayVotes;
        // number of nay votes for this proposal
        uint256 nayVotes;
        // indicate whether proposal has been executed or not
        bool executed;
        // mapping of the Crypto Dev NFT tokenIds to boolean
        // indicated whether that NFT has already been used to cast a vote or not
        mapping(uint256 => bool) voters;
    }

    enum Vote {
        YAY,
        NAY
    }

    // mapping of ID to Proposal
    mapping(uint256 => Proposal) public proposals;
    // number of proposal that have been created
    uint256 public numProposals;

    // the payable allows the constructor to receive ETH deposit when it is being deployed to fill the ETH DAO treasury
    constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
    }

    // a modifier that only allows a function to be called by someone who owns at least 1 CryptoDevsNFT
    modifier nftHolderOnly() {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "Not a DAO member");
        _;
    }

    // a modifier which only allows function to be called if has not exceed the deadline 
    modifier activeProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline > block.timestamp,
            "DEADLINE_EXCEEDED"
        );
        _;
    }

    // a modifier which allows a function to be called 
    // if the proposal's deadline has exceeded and has not execute yet
    modifier inactiveProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline < block.timestamp,
            "DEADLINE_NOT_EXCEEDED"
        );
        require(
            proposals[proposalIndex].executed == false,
            "PROPOSAL_ALREADY_EXECUTED"
        );
        _;
    }

    function executeProposal(uint256 proposalIndex)
        external
        nftHolderOnly
        inactiveProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];

        if (proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    function voteOnProposal(uint256 proposalIndex, Vote vote)
        external
        nftHolderOnly
        activeProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];

        uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint256 numVotes = 0;

        for (uint256 i = 0; i < voterNFTBalance; i++) {
            uint256 tokenID = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenID] == false) {
                numVotes++;
                proposal.voters[tokenID] = true;
            }
        }

        require(numVotes > 0, "ALREADY_VOTED");

        if (vote == Vote.YAY) {
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    // allows CryptoDevsNFT holder to create a new proposal in the DAO
    // _nftTokenId - the tokenID of the NFT to be purchased from the FakeNFTMarketplace if this proposal passed
    // returns the proposal ID of the newly created proposal
    function createProposal(uint256 _nftTokenId)
        external
        nftHolderOnly
        returns (uint256)
    {
        require(nftMarketplace.available(_nftTokenId), "NFT_NOT_FOR_SALE");

        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;
        numProposals++;

        return numProposals - 1;
    }

    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}
}
