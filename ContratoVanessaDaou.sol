// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.8.0;

contract VanessaDaou {
    
    // Global variables
    
    address payable private owner;
    
    uint8 private deleteTries;
    
    uint private totalDebts;
    
    // Constructor
    
    constructor(){
        
        owner = payable(msg.sender);
        
        // It will decrease each time the owner try to destruct the contract
        deleteTries = 3;
        
        totalDebts = 0;
        
    }
    
    // Structures
    
    struct Product{
        string name;
        uint units;
        uint price;
        string description;
    }
    
    // Each Client has its own debts and total expend
    
    struct Client{
        address clientAddress;
        uint code;
        string name;
        string country;
        uint totalExpend;
        uint debt;
    }
    
    // Mappings
    
    // First two save products and clients to search by its name and code respectively
    
    mapping (string => Product) private products;
    
    mapping (uint => Client) private clients;
    
    // Next one maps user addresses with its unique code (used in map clients)
    
    mapping (address => uint) private clientCodeByAddress;
    
    // Next two map the names and codes used by the products and clients respectively to avoid duplication
    
    mapping (string => bool) private productNames;
    
    mapping (uint => bool) private usedClientCodes;
    
    // This one saves the total Ether expend by the client of each country, key string is the country name
    
    mapping (string => uint) private expendByCountries;
    
    
    // Modifiers
    
    modifier isOwner(){
        require(msg.sender == owner, "Only the owner can call this");
        _;
    }
    
    modifier isNotClient () {
        require (clientCodeByAddress[msg.sender]==0, "This Address is already registered");
        _;
    }
    
    modifier isClient () {
        require (clientCodeByAddress[msg.sender]!=0, "User not registered as client");
        _;
    }
    
    modifier clientCodeNotExists (uint code) {
        require (!usedClientCodes[code], "Code is already in use");
        _;
    }
    
    modifier hasNotDebt (){
        uint code = clientCodeByAddress[msg.sender];
        require (clients[code].debt == 0, "Client with debt can not buy");
        _;
    }
    
    modifier isPositive (uint number) {
        require (number>0, "Arguments need to be positive");
        _;
    }
    
    modifier productNotExists (string memory _name) {
        require (!productNames[_name], "Product name already in use");
        _;
    }
    
    modifier productAvailable (string memory _name) {
        require (products[_name].units > 0, "Product is not available");
        _;
    }
    
    modifier productExists (string memory _name) {
        require (productNames[_name], "Product doesn't exists");
        _;
    }
    
    /*
    Prices are stored in Ether value, but by default systems assumes they are weis
    so we need to make the conversion from Ethers to Weis multipling by 10^18
    */
    modifier exactPrice (uint price) {
        require (msg.value == (price*10**18), "Just can pay with the exact price in Ether");
        _;
    }
    
    // Events
    
    event CreateNewProduct (address creator, string name, uint units, uint price, string description);
    
    event CreateNewClient (address client, uint code, string name, string country);
    
    event BuyProduct (address seller, address buyer, string produtcName, uint clientCode, uint basePrice, uint price);
    
    // Functions
    
    /*
    newProduct creates a new product if it is called by the owner, if the product name doesn't exists yet,
    and if its numeric arguments are entire positive numbers
    
    It also updates the produtcNames map with the new product name to true
    */
    
    function newProduct(string memory _name, uint256 _units, uint256 _price, string memory _description)
    public
    isOwner
    productNotExists(_name)
    isPositive(_price)
    isPositive(_units)
    {
        Product memory product;
        
        product.name = _name;
        product.units = _units;
        product.price = _price;
        product.description = _description;
        
        products[_name] = product;
        productNames[_name] = true;
        
        emit CreateNewProduct(msg.sender, _name, _units, _price, _description);
        
    }
    
    /*
    newClient creates a new client if the user has not already a client binded to its address,
    if its code is positive and if the client code doesn't exists yet
    
    Initialize the client's totalExpend and debt in 0, and updates the clientCodeByAddress and
    usedClientCodes maps with a address to code (uint) and code (uint) to true respectively
    */
    
    function newClient (uint _code, string memory _name, string memory _country)
    public
    isNotClient
    isPositive(_code)
    clientCodeNotExists(_code)
    {
        Client memory client;
        
        client.clientAddress = msg.sender;
        client.code = _code;
        client.name = _name;
        client.country =_country;
        client.debt = 0;
        client.totalExpend = 0;
        
        clientCodeByAddress[msg.sender] = _code;
        clients[_code] = client;
        usedClientCodes[_code] = true;
        
        emit CreateNewClient(msg.sender, _code, _name, _country);
        
    }
    
    /*
    finalPrice show to the client the product price with the given name while it exists
    calculates for each client and each product if it deserves a discount
    */
    
    function finalPrice (string memory productName)
    public
    view
    isClient
    productExists(productName)
    returns (uint)
    {
        uint clientCode = clientCodeByAddress[msg.sender];
        uint clientExpend = clients[clientCode].totalExpend;
        uint productPrice = products[productName].price;
        
        if ((productPrice>=3) && (clientExpend>=50)){
            return (productPrice - 3);
        }
        else{
            return (productPrice);
        }
    }
    
    /*
    productInformation shows to the clients all the information about a product
    referenced with a given name while it exists
    */
    
    function productInformation (string memory productName)
    public
    view
    isClient
    productExists(productName)
    returns (string memory name, uint units, uint price, string memory description)
    {
        Product memory product = products[productName];
        name = product.name;
        units = product.units;
        price = product.price;
        description = product.description;
    }
    
    /*
    buyProduct allows clients to pay for a product while exists one with the given name
    and it has units in inventary, but just to clients thas has not debts and pays the exact
    product price
    
    The function updates client totalExpend with the value given by the function finalPrice
    and the product unit with the same value minus 1.
    
    It also updates the expendByCountries map usind the client country's name as key and adding to
    its remaining value, the current buy payment price
    */
    
    function buyProduct (string memory productName)
    public
    payable
    isClient
    productExists(productName)
    productAvailable(productName)
    hasNotDebt
    exactPrice(finalPrice(productName))
    {
        uint clientCode = clientCodeByAddress[msg.sender];
        Client memory client = clients[clientCode];
        Product memory product = products[productName];
        
        uint buyPrice = finalPrice(productName);
        
        client.totalExpend += buyPrice;
        product.units -= 1;
        
        clients[clientCode] = client;
        products[productName] = product;
        expendByCountries[client.country] += buyPrice;
        
        emit BuyProduct (owner, msg.sender, product.name, client.code, product.price, buyPrice);
    }
    
    /*
    sellsInCountry returns to the owner the amount sells of a country by the given name
    */
    
    function sellsInCountry (string memory countryName)
    public
    view
    isOwner
    returns (uint countryTotal)
    {
        countryTotal = expendByCountries[countryName];
    }
    
    /*
    destructContract allows the owner to destruct the contract after 3 function uses
    
    If the function haven't been used 3 times, it returns a warning message
    */
    
    function destructContract()
    public
    payable
    isOwner
    returns (string memory message)
    {
        message = "";
        deleteTries -= 1;
        if (deleteTries == 0){
            selfdestruct(owner);
        } else if (deleteTries == 2) {
            message = "Are you sure? Press de button other 2 times";
        } else {
            message = "Are you sure? Press de button 1 more time";
        }
    }
    
}