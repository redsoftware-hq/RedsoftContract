// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract RedsoftContract is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    uint256 listingPrice = 1 ether;
    address payable public ownerOfContract;

    mapping(uint256 => Nft) private tokenIdToNftObject;

    struct Nft {
        uint256 tokenId;
        address payable sellerOfNft;
        address payable ownerOfNft;
        bool isListed;
        uint256 price;
        bool sold;
    }

    event NftMintedEvent(
        uint256 indexed tokenId,
        address indexed sellerOfNft,
        address indexed ownerOfNft,
        bool isListed,
        uint256 price,
        bool sold
    );
    event NFTListedEvent(
        uint256 price,
        uint256 indexed tokenId,
        address indexed oldOwnerOfnft
    );
    event NFTSoldEvent(
        uint256 price,
        uint256 indexed tokenId,
        address indexed oldOwnerOfnft,
        address indexed newOwnerOfNft
    );

    constructor() ERC721("Redsoft Tokens", "RST") {
        ownerOfContract = payable(msg.sender);
    }

    // Updates the listing price of the contract
    function updateListingPrice(uint256 _listingPrice) public payable {
        require(
            ownerOfContract == msg.sender,
            "Only marketplace owner can update listing price"
        );
        listingPrice = _listingPrice;
    }

    // Returns the listing price of the contract
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    // Mints a token
    function mintToken(string memory tokenURI) public returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        tokenIdToNftObject[newTokenId] = Nft(
            newTokenId,
            payable(msg.sender),
            payable(address(0)),
            false,
            0,
            false
        );

        emit NftMintedEvent(
            newTokenId,
            msg.sender,
            address(0),
            false,
            0,
            false
        );

        return newTokenId;
    }

    // Allows someone to resell a token they have purchased
    function resellToken(uint256 tokenId, uint256 price) public payable {
        require(
            tokenIdToNftObject[tokenId].ownerOfNft == msg.sender,
            "Only item owner can perform this operation"
        );
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );
        tokenIdToNftObject[tokenId].sold = false;
        tokenIdToNftObject[tokenId].price = price;
        tokenIdToNftObject[tokenId].isListed = false;
        tokenIdToNftObject[tokenId].sellerOfNft = payable(msg.sender);
        tokenIdToNftObject[tokenId].ownerOfNft = payable(address(this));

        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }

    // Lists a token
    function listNft(uint256 tokenId, uint256 price) public payable {
        require(_exists(tokenId), "Token does not exist");
        require(
            msg.sender == tokenIdToNftObject[tokenId].sellerOfNft,
            "Only token minter can list the token"
        );
        require(
            msg.value == listingPrice,
            "You have to pay the listing price to mint"
        );
        require(price > 0, "Price must be greater than 0");

        tokenIdToNftObject[tokenId].sold = false;
        tokenIdToNftObject[tokenId].price = price;
        tokenIdToNftObject[tokenId].isListed = true;
        tokenIdToNftObject[tokenId].ownerOfNft = payable(msg.sender);
        tokenIdToNftObject[tokenId].sellerOfNft = payable(msg.sender);

        _itemsSold.increment();

        emit NFTListedEvent(0, tokenId, msg.sender);

        payable(ownerOfContract).transfer(msg.value);
    }

    // Returns all minted market items of user
    function fetchNFTsMintedUser(
        address user
    ) public view returns (Nft[] memory) {
        uint256 tokenCount = balanceOf(user);

        Nft[] memory nfts = new Nft[](tokenCount);
        uint256 j = 0;

        for (uint256 i = 1; i <= _tokenIds.current(); i++) {
            if (
                _exists(i) &&
                ownerOf(i) == user &&
                tokenIdToNftObject[i].sold == false
            ) {
                Nft memory nft = tokenIdToNftObject[i];
                nfts[j] = nft;
                j++;
            }
        }

        return nfts;
    }

    // Returns all unsold market items
    function fetchAllUnsoldNFTs() public view returns (Nft[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 unsoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        Nft[] memory items = new Nft[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (tokenIdToNftObject[i + 1].ownerOfNft == address(this)) {
                uint256 currentId = i + 1;
                Nft storage currentItem = tokenIdToNftObject[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // Returns only items that a user has purchased
    function fetchNFTsUser() public view returns (Nft[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (tokenIdToNftObject[i + 1].ownerOfNft == msg.sender) {
                itemCount += 1;
            }
        }

        Nft[] memory items = new Nft[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (tokenIdToNftObject[i + 1].ownerOfNft == msg.sender) {
                uint256 currentId = i + 1;
                Nft storage currentItem = tokenIdToNftObject[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // Returns only items that a user has listed
    function fetchNFTsListedUser(
        address user
    ) public view returns (Nft[] memory) {
        uint256 totalItems = _tokenIds.current();
        uint256 itemCount = 0;
        Nft[] memory listedItems = new Nft[](totalItems);

        for (uint256 i = 1; i <= totalItems; i++) {
            if (
                tokenIdToNftObject[i].sellerOfNft == user &&
                tokenIdToNftObject[i].sold == false &&
                tokenIdToNftObject[i].isListed == true
            ) {
                listedItems[itemCount] = tokenIdToNftObject[i];
                itemCount++;
            }
        }

        Nft[] memory userItems = new Nft[](itemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            userItems[i] = listedItems[i];
        }

        return userItems;
    }

    // Transfers ownership of the item as well as funds between parties
    function buyNFT(uint256 tokenId) public payable {
        require(
            tokenIdToNftObject[tokenId].sellerOfNft != address(0),
            "NFT not listed for sale"
        );
        require(
            msg.value == tokenIdToNftObject[tokenId].price,
            "Incorrect amount sent"
        );
        address seller = tokenIdToNftObject[tokenId].sellerOfNft;
        tokenIdToNftObject[tokenId].sellerOfNft = payable(address(0));
        tokenIdToNftObject[tokenId].ownerOfNft = payable(msg.sender);
        payable(seller).transfer(msg.value);
        safeTransferFrom(ownerOf(tokenId), msg.sender, tokenId);
    }

    // Gets an NFT token details
    // function getNFT(uint256 tokenId)
    //     public
    //     view
    //     returns (
    //         address,
    //         address,
    //         uint256
    //     )
    // {
    //     return (
    //         tokenIdToNftObject[tokenId].sellerOfNft,
    //         tokenIdToNftObject[tokenId].ownerOfNft,
    //         tokenIdToNftObject[tokenId].price,

    //     );
    // }
}
