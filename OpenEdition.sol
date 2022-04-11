// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// @title: Open Edition
// Originally written by @andrewjiang for DrifterShoots' First Day Out Open Edition

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract OpenEdition is AdminControl, ICreatorExtensionTokenURI {
    enum ContractStatus {
        Paused,
        PreMint,
        Public,
        Closed
    }
    
    using Strings for uint256;

    ContractStatus public contractStatus = ContractStatus.Paused;
    address private _creator;
    address public _donationAddress;
    string private _day;
    string private _dayPreview;
    string private _night;
    uint public _price;
    bytes32 public _merkleRoot;    
    uint256 public totalSupply = 0;

    mapping(uint256 => bool) public tokenIdDayOrNight; // By default, the 'night' metadata is shown

    constructor(
        address creator,
        string memory day,
        string memory dayPreview,
        string memory night,
        bytes32 merkleRoot,
        address donationAddress,
        uint price
    ) public {
        _creator = creator;
        _day = day;
        _dayPreview = dayPreview;
        _night = night;
        _merkleRoot = merkleRoot;
        _donationAddress = donationAddress;
        _price = price;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function airdrop(address[] memory receivers) public adminRequired {
        for (uint i; i < receivers.length; i++) {
            IERC721CreatorCore(_creator).mintExtension(receivers[i]);
            totalSupply += 1;
        }
    }

    function mintPrivate(uint256 quantity, bytes32[] calldata proof) public payable callerIsUser {      
        require(contractStatus == ContractStatus.PreMint, "Pre mint is yet not available");
        require(msg.value == _price * quantity, "Not enough ETH sent");
        require(canMintPrivate(msg.sender, proof), "Failed wallet verification");      
        IERC721CreatorCore(_creator).mintExtensionBatch(msg.sender, uint16(quantity));
        totalSupply += quantity;
    }

    function mintPublic(uint256 quantity) public payable callerIsUser {
        require(contractStatus == ContractStatus.Public, "Public minting yet not available");
        require(msg.value == _price * quantity, "Not enough ETH sent");
        IERC721CreatorCore(_creator).mintExtensionBatch(msg.sender, uint16(quantity));
        totalSupply += quantity;
    }

    function setImages(string memory day, string memory dayPreview, string memory night) public adminRequired {
        _day = day;
        _dayPreview = dayPreview;
        _night = night;
    }
 
    function setPrice(uint price) public adminRequired {
        _price = price;
    }

    function setDonationAddress(address donationAddress) public adminRequired {
        require(donationAddress != address(0), "Donation address cannot be 0x0");
        _donationAddress = donationAddress;
    }

    function setContractStatus(ContractStatus status) public adminRequired {
        contractStatus = status;
    }

    // Note: Total supply is only used for aesthetic purposes in the title
    function overrideTotalSupply(uint256 supply) public adminRequired{ 
        totalSupply = supply;
    }

    function toggleURI(uint256 tokenId) public {
        require(IERC721Upgradeable(_creator).ownerOf(tokenId) == msg.sender, "You are not the owner of this token");
        tokenIdDayOrNight[tokenId] = !tokenIdDayOrNight[tokenId];
    }

    function getName(uint256 tokenId) private view returns (string memory) {
        if(contractStatus == ContractStatus.Closed) {
            return string(abi.encodePacked("Open Edition #", tokenId.toString(), "/", totalSupply.toString()));
        } else {
            return string(abi.encodePacked("Open Edition #", tokenId.toString()));
        }
    }

    // Adjust the metadata as it fits for your project
    function getImage(uint256 tokenId) private view returns (string memory) {
        if(tokenIdDayOrNight[tokenId]) {
            return string(abi.encodePacked(
                '"image":"',
                _dayPreview,
                '","image_url":"',
                _dayPreview,
                '","animation_url":"',
                _day,
                '","attributes": [{"trait_type": "Side","value": "Day"}]'
            ));
        } else {
            return string(abi.encodePacked(
                '"image":"',
                _night,
                '","image_url":"',
                _night,
                '","attributes": [{"trait_type": "Side","value": "Night"}]'
            ));
        }
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
       require(creator == _creator, "Invalid token");
       return string(abi.encodePacked('data:application/json;utf8,',
        '{"name":"',
            getName(tokenId),
        '",',
        '"created_by":"Artist Name",',
        '"description":"Open Edition\\n\\nArtist: Artist Name",',
            getImage(tokenId),
        '}'
        ));
    }

    function withdraw(address to) public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address creator = payable(to);
        address donation = payable(_donationAddress); // 15% of the funds go to the donation address

        bool success;

        (success, ) = creator.call{value: (sendAmount * 850/1000)}("");
        require(success, "Transaction Unsuccessful");

        (success, ) = donation.call{value: (sendAmount * 150/1000)}("");
        require(success, "Transaction Unsuccessful");
    }

    function canMintPrivate(address account, bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, _merkleRoot, generateMerkleLeaf(account));
    }

    function generateMerkleLeaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function setMerkleRoot(bytes32 merkleRoot) public adminRequired {
        _merkleRoot = merkleRoot;
    }
}