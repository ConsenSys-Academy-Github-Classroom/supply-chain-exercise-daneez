// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {
    address public owner;

    uint public skuCount;
    mapping(uint => Item) public items;

    enum State {
        ForSale,
        Sold,
        Shipped,
        Received
    }
    struct Item {
        string name;
        uint sku;
        uint price;
        State state;
        address payable seller;
        address payable buyer;
    }
    /*
     * Events
     */

    event LogForSale(uint sku);
    event LogSold(uint sku);
    event LogShipped(uint sku);
    event LogReceived(uint sku);

    /*
     * Modifiers
     */

    modifier isOwner(address _owner) {
        require(msg.sender == owner);
        _;
    }

    modifier verifyCaller(address _address) {
        require(msg.sender == _address);
        _;
    }

    modifier paidEnough(uint _price) {
        require(msg.value >= _price);
        _;
    }

    modifier checkValue(uint _sku) {
        uint _price = items[_sku].price;
        uint amountToRefund = msg.value - _price;
        items[_sku].buyer.transfer(amountToRefund);
        _;
    }

    // For each of the following modifiers, use what you learned about modifiers
    // to give them functionality. For example, the forSale modifier should
    // require that the item with the given sku has the state ForSale. Note that
    // the uninitialized Item.State is 0, which is also the index of the ForSale
    // value, so checking that Item.State == ForSale is not sufficient to check
    // that an Item is for sale. Hint: What item properties will be non-zero when
    // an Item has been added?

    modifier forSale(uint _sku) {
        require(items[_sku].state == State.ForSale);
        _;
    }
    modifier sold(uint _sku) {
        require(items[_sku].state == State.Sold);
        _;
    }
    modifier shipped(uint _sku) {
        require(items[_sku].state == State.Shipped);
        _;
    }
    modifier received(uint _sku) {
        require(items[_sku].state == State.Received);
        _;
    }

    constructor() public {
        // 1. Set the owner to the transaction sender
        owner = msg.sender;
        // 2. Initialize the sku count to 0. Question, is this necessary?
        skuCount = 0;
    }

    function addItem(string memory _name, uint _price)
        public returns (bool)
    {
        items[skuCount] = Item({
            name: _name,
            sku: skuCount,
            price: _price,
            state: State.ForSale,
            seller: msg.sender,
            buyer: address(0)
        });

        skuCount = skuCount + 1;
        emit LogForSale(skuCount);
        return true;
    }

    // Implement this buyItem function.
    function buyItem(uint sku) public payable forSale(sku) paidEnough(items[sku].price) checkValue(sku){
        items[sku].seller.transfer(items[sku].price);
        items[sku].buyer = msg.sender;
        items[sku].state = State.Sold;
        emit LogSold(sku);
    }

    function shipItem(uint sku) public sold(sku) verifyCaller(items[sku].seller){
        items[sku].state = State.Shipped;
        emit LogShipped(sku);
    }

    function receiveItem(uint sku) public shipped(sku) verifyCaller(items[sku].buyer) {
        items[sku].state = State.Received;
        emit LogReceived(sku);
    }

    function fetchItem(uint _sku)
        public
        view
        returns (
            string memory name,
            uint sku,
            uint price,
            State state,
            address seller,
            address buyer
        )
    {
        name = items[_sku].name;
        sku = items[_sku].sku;
        price = items[_sku].price;
        state = State(items[_sku].state);
        seller = items[_sku].seller;
        buyer = items[_sku].buyer;
        return (name, sku, price, state, seller, buyer);
    }
}
