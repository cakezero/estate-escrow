// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.20;

contract EstateEscrow {
    address immutable owner;

    error IdDoesNotExist();
    error SellerHasBeenPaid();
    error SendRequiredAmount();

    event BuyerDeposit(
        address indexed buyer,
        address indexed seller,
        uint indexed amount
    );
    event BuyerHasBeenRefunded(address indexed buyer, uint amount);
    event SellerPaid(address indexed seller, uint indexed amount);

    mapping(string => DealInfo) public dealInfo;
    mapping(string => bool) public idExist;
    mapping(string => bool) public payConfirmed;

    struct DealInfo {
        address buyer;
        address seller;
        uint amount;
        string propertyUrl;
    }

    constructor() {
        owner = msg.sender;
    }

    /** 
    @notice This function is to recieve funds and store the deal information between the buyer and seller.
    @param _url This should be the url/link to the property images or documents.
    @param id This should be an id gotten from the backend.
    */
    function deposit(
        address _seller,
        address _buyer,
        uint _amount,
        string calldata id,
        string calldata _url
    ) external payable {
        if (msg.value != _amount) revert SendRequiredAmount();

        dealInfo[id] = DealInfo({
            buyer: _buyer,
            seller: _seller,
            amount: _amount,
            propertyUrl: _url
        });

        payConfirmed[id] = false;
        idExist[id] = true;
        emit BuyerDeposit(_buyer, _seller, _amount);
    }

    function refund(string calldata id) external payable onlyOwner {
        if (!idExist[id]) revert IdDoesNotExist();
        if (payConfirmed[id] == true) revert SellerHasBeenPaid();

        address buyer = dealInfo[id].buyer;
        uint amount = dealInfo[id].amount;

        (bool success, ) = payable(buyer).call{value: amount}("");
        require(success, "Error refunding buyer");

        emit BuyerHasBeenRefunded(buyer, amount);
    }

    function paySeller(string calldata id) external payable onlyOwner {
        if (!idExist[id]) revert IdDoesNotExist();
        if (payConfirmed[id] == true) revert SellerHasBeenPaid();

        address seller = dealInfo[id].seller;
        uint amount = dealInfo[id].amount;

        (bool success, ) = payable(seller).call{value: amount}("");
        require(success, "Error sending seller's funds");

        payConfirmed[id] = true;
        emit SellerPaid(dealInfo[id].seller, dealInfo[id].amount);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You cannot perform this action");
        _;
    }
}
