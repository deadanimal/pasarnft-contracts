//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./ERC721Base.sol";

contract Minter721 is ERC721, AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public dao;
    uint256 public createFee;
    uint256 public custodyFee;
    uint256 public mintFee;

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;  

    event Created(string name, string symbol, uint256 _royalty, address _creator, address token, uint256 tokenId);
    event SelfManaged(uint256 tokenId);
    event Minted(uint256 tokenId, address to, string uri);

    mapping(uint256 => address) public tokenContract;

    constructor(address _dao) ERC721("Pasar NFT Factory", "NFTF") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        dao = _dao;
        createFee = 100e18;
        custodyFee = 100e18;
        mintFee = 1e18; // 1
    }

    function updateDao(address _dao) public onlyRole(MINTER_ROLE) {
        dao = _dao;
    }

    function updateFees(uint256 _create, uint256 _custody, uint256 _mint) public onlyRole(MINTER_ROLE) {
        createFee = _create;
        custodyFee = _custody;
        mintFee = _mint;
    }


    function create(string memory name, string memory symbol, uint256 _royalty, address _creator) public payable {

        address payable receiver = payable(dao);
        bool sent = receiver.send(createFee);
        require(sent, "Failed to send Ether");   
        require(_royalty > 0 && _royalty <= 2000, "must exceed zero and below 20%");

        ERC721Base token = new ERC721Base(name, symbol, _royalty, _creator);
        address tokenAddress = address(token);
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);  
        tokenContract[tokenId] = tokenAddress;     

        emit Created(name, symbol, _royalty, _creator, tokenAddress, tokenId);
    }

    function mint(uint256 _tokenId, address to, string memory uri) public payable {

        address payable receiver = payable(dao);
        bool sent = receiver.send(mintFee);
        require(sent, "Failed to send Ether");
        require(ownerOf(_tokenId) == msg.sender, "only owner");

        ERC721Base token = ERC721Base(tokenContract[_tokenId]);
        token.safeMint(to, uri);

        emit Minted(_tokenId, to, uri);
    }

    function selfCustody(uint256 _tokenId) public payable {
        address payable receiver = payable(dao);
        bool sent = receiver.send(custodyFee);
        require(sent, "Failed to send Ether"); 
        require(ownerOf(_tokenId) == msg.sender, "only owner");
        ERC721Base token = ERC721Base(tokenContract[_tokenId]);
        require(token.owner() == address(this), "not custodian of contract");
        token.transferOwnership(msg.sender);

        emit SelfManaged(_tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }    


}
