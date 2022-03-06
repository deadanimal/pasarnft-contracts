//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


import "./ERC721Base.sol";

contract Market721 is AccessControl {

    using SafeMath for uint256;
    using Counters for Counters.Counter;    

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public dao;
    uint256 public rate;
    uint256 public minimumPrice;
    uint256 public totalCommissions;
    Counters.Counter public saleCompleted;
    Counters.Counter public saleIdCounter;  

    event SaleCreated(address _contract, uint256 _tokenId, uint256 _price, address _seller);
    event SaleFinalised(address _contractAddress, uint256 _tokenId, uint256 _price, address _seller, address _buyer);
    event SaleStopped(address contractAddress, uint256 tokenId, uint256 price, address seller);
    event SaleForcedStop(address contractAddress, uint256 tokenId, uint256 price, address seller);

    struct Sale {
        address contractAddress;
        uint256 tokenId;
        uint256 price;
        address seller;
        address buyer;
    }

    mapping(uint256 => Sale) public sales;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        dao = msg.sender;
        rate = 250; // 2.5%
        minimumPrice = 1e18; // 1
    }

    function updateDao(address _dao) public onlyRole(MINTER_ROLE) {
        dao = _dao;
    }

    function updateRate(uint256 _rate) public onlyRole(MINTER_ROLE) {
        rate = _rate;
    }  

    function updateMinimumPrice(uint256 _minimumPrice) public onlyRole(MINTER_ROLE) {
        minimumPrice = _minimumPrice;
    }       

    function buy721(uint256 _saleId) public payable {

        address _buyer = msg.sender;
        
        uint256 valuePaid = msg.value;
        Sale storage sale = sales[_saleId];
        EIERC721 token = EIERC721(sale.contractAddress);

        require(valuePaid >= sale.price, "buy price >= saleprice");
        require(token.ownerOf(sale.tokenId) == address(this), "market must own the token");

        uint256 royaltyForMarket = valuePaid.mul(rate).div(10000);
        uint256 royaltyForCreator = valuePaid.mul(token.royalty()).div(10000);
        uint256 netToSeller = valuePaid.sub(royaltyForMarket).sub(royaltyForCreator);
        
        address payable receiverFirst = payable(dao);
        bool sentToMarket = receiverFirst.send(royaltyForMarket);
        require(sentToMarket, "Failed to send Ether sentToMarket");   
        totalCommissions += royaltyForMarket;

        address payable receiverSecond = payable(token.creator());
        bool sentToCreator = receiverSecond.send(royaltyForCreator);
        require(sentToCreator, "Failed to send Ether sentToCreator");  

        address payable receiverThird = payable(sale.seller);
        bool sentToSeller = receiverThird.send(netToSeller);
        require(sentToSeller, "Failed to send Ether sentToSeller");                       

        token.safeTransferFrom(address(this), _buyer, sale.tokenId);
        sale.buyer = _buyer;

        saleCompleted.increment();        

        emit SaleFinalised(sale.contractAddress, sale.tokenId, sale.price, sale.seller, sale.buyer);

    }

    function sell721(address _contract, uint256 _tokenId, uint256 _price) public payable {

        address _seller = msg.sender;
        EIERC721 token = EIERC721(_contract);

        require(_seller == token.ownerOf(_tokenId), "seller must own token");
        require(token.isApprovedForAll(_seller, address(this)) == true, "must approve token");
        require(_price >= minimumPrice, "price must exceed minimum price");

        token.safeTransferFrom(_seller, address(this), _tokenId);

        address payable receiverFirst = payable(dao);
        bool sentToMarket = receiverFirst.send(minimumPrice);
        require(sentToMarket, "Failed to send Ether sentToMarket");   
        totalCommissions += minimumPrice;        
        
        uint256 saleId = saleIdCounter.current();
        saleIdCounter.increment();

        Sale storage sale = sales[saleId];
        sale.contractAddress = _contract;
        sale.tokenId = _tokenId;
        sale.price = _price;
        sale.seller = _seller;

        emit SaleCreated(_contract, _tokenId, _price, _seller);
        
    }

    function stopSelling721(uint256 _saleId) public payable {

        address seller = msg.sender;
        
        Sale storage sale = sales[_saleId];
        EIERC721 token = EIERC721(sale.contractAddress);

        require(sale.seller == seller, "must be seller");
        require(token.ownerOf(sale.tokenId) == address(this), "market must own the token");

        address payable receiverFirst = payable(dao);
        bool sentToMarket = receiverFirst.send(minimumPrice);

        require(sentToMarket, "Failed to send Ether sentToMarket");  

        totalCommissions += minimumPrice;                  
        token.safeTransferFrom(address(this), seller, sale.tokenId);  

        emit SaleStopped(sale.contractAddress, sale.tokenId, sale.price, sale.seller);    
    }

    function forceSelling721(uint256 _saleId) public onlyRole(MINTER_ROLE) {
        Sale storage sale = sales[_saleId];
        EIERC721 token = EIERC721(sale.contractAddress);   

        require(token.ownerOf(sale.tokenId) == address(this), "market must own the token");     
        
        token.safeTransferFrom(address(this), dao, sale.tokenId);   

        emit SaleForcedStop(sale.contractAddress, sale.tokenId, sale.price, sale.seller); 
    }

    function getSale721(uint256 _saleId) public view returns ( address contractAddress, uint256 tokenId, uint256 price, address seller, address buyer) {
        Sale storage sale = sales[_saleId];
        contractAddress = sale.contractAddress;
        tokenId = sale.tokenId;
        price = sale.price;
        seller = sale.seller;
        buyer = sale.buyer;
    }

}
