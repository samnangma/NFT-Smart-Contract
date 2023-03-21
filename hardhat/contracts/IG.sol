// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWhitelist.sol";

contract IG is ERC721Enumerable, ERC2981, Ownable {
    using Strings for uint256;

    string private baseURI;

    address private artist;

    uint96 public royaltyFee;

    uint256 public _price = 0.02 ether;

    uint256 public _presaleprice = 0.01 ether;

    bool public _paused;

    uint256 public maxTokenIds = 10;

    uint256 public tokenIds;

    IWhitelist whitelist;

    uint256 public nftPerAddressLimit;

    uint256 public presaleStarted;

    uint public duration;

    modifier onlyWhenNotPaused() {
        require(!_paused, "Contract currently paused");
        _;
    }
    event Sale(address from, address to, uint256 value);

    constructor(
        string memory _initBaseURI,
        uint96 _royaltyFee,
        address _artist,
        address whitelistContract
    ) ERC721("IG", "IGCollection") {
        baseURI = _initBaseURI;
        royaltyFee = _royaltyFee;
        artist = _artist;
        _setDefaultRoyalty(_artist, _royaltyFee);
        whitelist = IWhitelist(whitelistContract);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setDuration(uint _setDuration) public onlyOwner {
        require(_setDuration != 0, "Not Allowed to Start the Duration");
        require(presaleStarted == 0, "You already set the duration");
        presaleStarted = block.timestamp;
        duration = presaleStarted + _setDuration;
    }


    function setNftPerAddressLimit(uint256 _limitNFT) public onlyOwner {
        nftPerAddressLimit = _limitNFT;
    }

    function presaleEnded() public view returns (uint256) {
        return block.timestamp + duration;
    } 

    function presaleMint() public payable onlyWhenNotPaused {
        require(block.timestamp < presaleEnded(), "Presale is not running");
        require(
            whitelist.whitelistedAddresses(msg.sender),
            "You are not whitelisted"
        );
        require(tokenIds < maxTokenIds, "Exceeded maximum Crypto Devs supply");

        require(msg.value >= _presaleprice, "Ether sent is not correct");
        tokenIds += 1;

        if (msg.sender != owner()) {
            uint256 ownerTokenCount = balanceOf(msg.sender);
            require(
                ownerTokenCount < nftPerAddressLimit,
                "You cannot mint anymore!!"
            );
        }
 
        _safeMint(msg.sender, tokenIds);
    }

    function mint() public payable onlyWhenNotPaused {
        require(block.timestamp >= presaleEnded(), "Presale has not ended yet");
        require(tokenIds < maxTokenIds, "Exceed maximum Crypto Devs supply");
        require(msg.value >= _price, "Ether sent is not correct");
        tokenIds += 1;

        if (msg.sender != owner()) {
            uint256 ownerTokenCount = balanceOf(msg.sender);
            require(
                ownerTokenCount < nftPerAddressLimit,
                "You allowed to mint 3 NFT only!!"
            );
        }
        _safeMint(msg.sender, tokenIds);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenIds
    ) public override(ERC721, IERC721) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenIds),
            "ERC721: transfer caller is not owner nor approved"
        );

        super._transfer(from, to, tokenIds);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenIds
    ) public override(ERC721, IERC721) {
        super.safeTransferFrom(from, to, tokenIds, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenIds,
        bytes memory _data
    ) public override(ERC721, IERC721) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenIds),
            "ERC721: transfer caller is not owner nor approved"
        );

        _safeTransfer(from, to, tokenIds, _data);
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmcHtq18JdQCnnaL3Y84kWvU4PytzpHJ9DE86UzxwdG7Br/";
    }

    function setRoyaltyFee(uint96 _royaltyFee) public onlyOwner {
        royaltyFee = _royaltyFee;
    }

    function setPaused(bool val) public onlyOwner onlyWhenNotPaused {
        _paused = val;
    }

    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable {}

    fallback() external payable {}
}
