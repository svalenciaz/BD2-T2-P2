// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.8.0;

contract VanessaDaou {
    
    // 
    
    address payable private owner;
    
    uint8 private deleteTries;
    
    
    constructor(){
        
        owner = payable(msg.sender);
        deleteTries = 3;
        
    }
    
    struct Product{
        string name;
        uint units;
        uint price;
        string description;
    }
    
    struct Client{
        address clientAddress;
        uint code;
        string name;
        string country;
        uint totalExpend;
        uint debt;
    }
    
    // TODO revisar si debe ser public o private
    
    mapping (string => Product) public products;
    
    mapping (uint => Client) public clients;
    
    mapping (address => uint) public codeClientByAddress;
    
    mapping (string => bool) private usedProductNames;
    
    mapping (uint => bool) private usedClientCodes;
    
    mapping (string => uint) public expendByCountries;
    
    modifier isOwner(){
        require(msg.sender == owner, "Only the owner can call this");
        _;
    }
    
    modifier isPositive (uint number) {
        require (number>0, "Arguments need to be non-negative");
        _;
    }
    
    modifier productNotExists (string memory _name) {
        require (!usedProductNames[_name], "Name is in use");
        _;
    }
    
    modifier clientCodeNotExists (uint code) {
        require (!usedClientCodes[code], "Code is already in use");
        _;
    }
    
    modifier clientAddressAlreadyRegistered (address _address) {
        require (codeClientByAddress[_address]==0, "This Address is already registered");
        _;
    }
    
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
        usedProductNames[_name] = true;
        
    }
    
    function newClient (uint _code, string memory _name, string memory _country)
    public
    clientCodeNotExists(_code)
    isPositive(_code)
    clientAddressAlreadyRegistered(msg.sender)
    {
        Client memory client;
        
        client.clientAddress = msg.sender;
        client.code = _code;
        client.name = _name;
        client.country =_country;
        client.debt = 0;
        client.totalExpend = 0;
        
        codeClientByAddress[msg.sender] = _code;
        clients[_code] = client;
        usedClientCodes[_code] = true;
        
    }
    
    
    
    function destructContract()
    public
    payable
    isOwner
    {
        deleteTries -= 1;
        if (deleteTries == 0){
            selfdestruct(owner);
            deleteTries = 3;
        }
    }
    
}