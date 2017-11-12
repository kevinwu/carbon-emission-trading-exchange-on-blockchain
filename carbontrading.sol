pragma solidity ^0.4.0;
contract CarbonTrading {

    struct Account {
        string name;
        uint256 coins;
    }

    struct SellOffer {
        address seller;
        uint256 coins;
        uint256 minimumPrice;
    }

    struct Balance {
        uint256 etherAmount;
        bool updated;
    }

    address issuer;
    uint256 officialPrice;
    uint256 etherToWei = 1000000000000000000;
    mapping(address => Account) accounts;
    mapping(address => Balance) balances;
    SellOffer sellOffer;

    /// Create a new Carbon Trading Marketplace with $(_numProposals) different proposals.
    function CarbonTrading(uint256 _numInitialCoins) public {
        issuer = msg.sender;
        accounts[issuer].coins = _numInitialCoins;
    }

    /// set coin price (by issuer)
    function setCoinPrice(uint256 _price) public {
        synchronizeEther();

        officialPrice = _price;
    }

    /// grant coins to a non-issuer account
    function grantCoins(address toAccount, uint256 _numCoins) public {
        synchronizeEther();

        if (msg.sender != issuer || accounts[msg.sender].coins < _numCoins) return;
        accounts[toAccount].coins += _numCoins;
        accounts[msg.sender].coins -= _numCoins;
    }

    /// Create coins (by the issuer)
    function mineCoins(uint256 _numCoins) public {
        synchronizeEther();

        if (msg.sender != issuer) return;
        accounts[issuer].coins += _numCoins;
    }

    /// synchronize Ether
    function synchronizeEther() public {
        if(balances[msg.sender].updated == false){
            balances[msg.sender].etherAmount = msg.sender.balance/1000000000000000000.0;
            balances[msg.sender].updated = true;
        }
    }

    /// sell contract on open market with minimum price
    function sellCoins(uint256 _numCoins, uint256 _minimumPrice) public {
        synchronizeEther();

        if (accounts[msg.sender].coins < _numCoins) return;
        sellOffer.seller = msg.sender;
        sellOffer.coins = _numCoins;
        sellOffer.minimumPrice = _minimumPrice;
    }

    /// buy contract on open market with maximum price
    function buyCoins(uint256 _numCoins, uint256 _maximumPrice) public {
        synchronizeEther();

        if(_maximumPrice < sellOffer.minimumPrice) return;
        uint256 maxCoins = _numCoins;
        if(maxCoins > accounts[sellOffer.seller].coins) {
            maxCoins = accounts[sellOffer.seller].coins;
        }
        if(maxCoins > sellOffer.coins){
            maxCoins = sellOffer.coins;
        }
        //transfer coins
        accounts[sellOffer.seller].coins -= maxCoins;
        accounts[msg.sender].coins += maxCoins;
        sellOffer.coins = 0;

        //transfer ether
        uint256 transactionAmount = maxCoins*sellOffer.minimumPrice;
        balances[sellOffer.seller].etherAmount += transactionAmount;
        balances[msg.sender].etherAmount -= transactionAmount;
    }

    /// access coins
    function accessCoins(uint256 _numCoins, uint256 _offeredPrice) public {
        synchronizeEther();

        if(_offeredPrice < officialPrice) return;
        uint256 maxCoins = _numCoins;
        if(maxCoins > accounts[issuer].coins){
            maxCoins = accounts[issuer].coins;
        }

        //transfer coins
        accounts[issuer].coins -= maxCoins;
        accounts[msg.sender].coins += maxCoins;

        //transfer ether
        uint256 transactionAmount = maxCoins;
        balances[issuer].etherAmount += transactionAmount;
        balances[msg.sender].etherAmount -= transactionAmount;
    }

    function showAccountCoins() public constant returns (uint256 _numCoins, uint256 _etherBalance) {
        _numCoins = accounts[msg.sender].coins;
        _etherBalance = balances[msg.sender].etherAmount;
    }
}
