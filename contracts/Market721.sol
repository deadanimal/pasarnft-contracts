//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


import "./ERC721Base.sol";

contract Market721 is AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public dao;
    uint256 public rate;
    uint256 public minimumPrice;

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _saleIdCounter;  

    event SaleCreated();
    event SaleFinalised();
    event SaleStopped();
    event SaleForcedStop();

    struct Sale {
        address contractAddress;
        uint256 tokenId;
        uint256 price;
        address seller;
        address buyer;
    }

    mapping(uint256 => Sale) public sales;

    constructor(address _dao) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        dao = _dao;
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

        uint256 royaltyForMarket = valuePaid.mul(rate).div(10000);
        uint256 royaltyForCreator = valuePaid.mul(token.royalty()).div(10000);
        uint256 netToSeller = valuePaid.sub(royaltyForMarket).sub(royaltyForCreator);

        (bool sentToMarket, bytes memory dataToMarket) = dao.call{value: royaltyForMarket}("");
        require(sentToMarket, "Failed to send Ether sentToMarket");   

        (bool sentToCreator, bytes memory dataToCreator) = token.creator().call{value: royaltyForCreator}("");
        require(sentToCreator, "Failed to send Ether sentToCreator");  

        (bool sentToSeller, bytes memory dataToSeller) = sale.seller.call{value: netToSeller}("");
        require(sentToSeller, "Failed to send Ether sentToSeller");                       

        token.safeTransferFrom(address(this), _buyer, sale.tokenId);
        sale.buyer = _buyer;
    }

    function sell721(address _contract, uint256 _tokenId, uint256 _price) public payable {

        address _seller = msg.sender;
        EIERC721 token = EIERC721(_contract);

        require(_seller == token.ownerOf(_tokenId), "seller must own token");
        require(token.isApprovedForAll(_seller, address(this)) == true, "must approve token");
        require(_price >= minimumPrice, "price must exceed minimum price");

        token.safeTransferFrom(_seller, address(this), _tokenId);

        (bool sentToMarket, bytes memory dataToMarket) = dao.call{value: minimumPrice}("");
        require(sentToMarket, "Failed to send Ether sentToMarket");           
        
        uint256 saleId = _saleIdCounter.current();
        _saleIdCounter.increment();

        Sale storage sale = sales[saleId];
        sale.contractAddress = _contract;
        sale.tokenId = _tokenId;
        sale.price = _price;
        sale.seller = _seller;
        
    }

    function stopSelling721(uint256 _saleId) public payable {

        address seller = msg.sender;
        
        Sale storage sale = sales[_saleId];
        EIERC721 token = EIERC721(sale.contractAddress);

        require(sale.seller == seller, "must be seller");

        (bool sentToMarket, bytes memory dataToMarket) = dao.call{value: minimumPrice}("");
        require(sentToMarket, "Failed to send Ether sentToMarket");            

        token.safeTransferFrom(address(this), seller, sale.tokenId);      
    }

    function forceSelling721(uint256 _saleId) public onlyRole(MINTER_ROLE) {
        
        Sale storage sale = sales[_saleId];
        EIERC721 token = EIERC721(sale.contractAddress);        

        token.safeTransferFrom(address(this), dao, sale.tokenId);   
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
