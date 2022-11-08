// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//@author PZ
//@title HypeSaints

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "erc721a/contracts/ERC721A.sol";

contract HypeSaints is Ownable, ERC721A, ReentrancyGuard {

    using SafeMath for uint256;


    uint256 private constant SERIES_SUPPLY = 3333;

    uint256 private series = 0;

    uint256 public saleStartTime = 1656975601;

    bytes32 public merkleRoot;

    string public baseURI;

    mapping(address => uint256) public totalMinted;

    mapping(uint256 => string) public saintsType;

    constructor(
        string memory _baseURI,
        bytes32 _merkleRoot
    ) ERC721A("HypeSaints", "HPST") {
        baseURI = _baseURI;
        merkleRoot = _merkleRoot;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setSaleStartTime(uint256 _saleStartTime) external onlyOwner {
        saleStartTime = _saleStartTime;
    }

    function setSeries(uint256 _series) external onlyOwner {
        series = _series;
    }

      // For marketing etc.
    function kolMint(address[] memory _team, uint256[] memory _teamMint) external onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            require(totalSupply() + _teamMint[i] <= SERIES_SUPPLY.mul(series), "Max supply exceeded");
            _safeMint(_team[i], _teamMint[i]);
        }
    }

    function whitelistMint(address _account, uint256 _quantity, bytes32[] calldata _proof,string memory _saintsType) external payable callerIsUser {
        require(currentTime() >= saleStartTime, "HypeSaints whitelist has not opened yet");
        require(isWhiteListed(msg.sender, _proof), "Not whitelisted");
        require(totalMinted[msg.sender] + _quantity <= 2, "You can only mint 2 NFT on the HypeSaints Whitelist Sale");
        require(totalSupply() + _quantity <= SERIES_SUPPLY.mul(series), "Max supply exceeded");
        saintsType[totalSupply()] = _saintsType;
        totalMinted[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function publicSaleMint(address _account, uint256 _quantity, string memory _saintsType) external payable callerIsUser {
        require(currentTime() > saleStartTime + 16 hours, "HypeSaints public mint is not open yet");
        require(currentTime() < saleStartTime + 64 hours, "HypeSaints public mint is closed");
        require(totalMinted[msg.sender] + _quantity <= 2, "You can only mint up to 2 Soulda NFTs on the Public Mint");
        require(totalSupply() + _quantity <= SERIES_SUPPLY.mul(series), "Max supply exceeded");
        saintsType[totalSupply()] = _saintsType;
        totalMinted[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }


    //Whitelist
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function isWhiteListed(address _account, bytes32[] calldata _proof) internal view returns(bool) {
        return _verify(leaf(_account), _proof);
    }

    function leaf(address _account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns(bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    function currentTime() internal view returns(uint256) {
        return block.timestamp;
    }
}