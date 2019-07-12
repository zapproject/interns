# Summer19 - Asset Market

## Purpose
To create a decentralized Asset Market where users are able to use Zap to invest in any asset through the help of oracles. This platform consists of two parts : 

The Main Market and the Auxiliary Market(s)

- Main Market
    + Takes the other side of all investments
    + Contains the Zap pool where all liquidity and funds go to and is withdrawn from
    + Has a Bonding Curve that people can bond to take the other side of all Auxiliary Markets
    + Takes 5% of all withdrawls
    + Users who bond to the curve deposits their Zap into the central Zap pool and in returns gets dividends when people withdraw (transaction fee) based on their equity stake percentage

- Auxiliary Market
    + There can be many Auxiliary Markets each representing one asset
    + Able to mint Auxiliary Market Tokens representative of the asset
    + Uses oracles to get live updates on the price of the asset
    + Allows users to use Zap to purchase and sell Auxiliary Market Tokens corresponding to that Auxiliary Market's asset


## How to Set Up
1. After cloning run `npm install`
2. Currently being tested on `truffle develop --network development`


## Functionality of Main Market
- **Initialized with a `Main Market Holder` struct**
**`initalized`** bool - checks if the market is initialized
**`tokens`** uint256 - tracker of how many MainMarketTokens exist
**`zapBalance`** uint256 - tracker of how much Zap is in the pool (in weiZap)

- **Constructor**

	Initializes the following
	**`bondage`** - bonadge contract
	**`zapToken`** - zapToken contract
	**`registry`** - registry contract
	**`currentCost`** - Current Cost contract

###Functions

- **getHolder**  
`function getHolder(address addr) private returns(MainMarketHolder storage)`  
gets existing holder and creates one if one doesn't exist

	Parameters:  
	`addr` - address  
	Returns:  
	`holder` - MainMarketHolder storage

- **getEquityStake**
`function getEquityStake(address holder) public returns (uint256)`
Gets user's equity stake based on total Zap in Contract and holder's zap balance in the Main Market Contract

	Parameters:
	`holder` - address
	Returns:
	`equityStake` - uint256

- **percent**
`function percent(uint numerator, uint denominator, uint precision) public returns(uint quotient)`
Used to increase equity precision

	Parameters:
	`numerator` - uint256
	`denominator` - uint256
	`precision` - uint256
	Returns:
	`quotient` - uint256

- **depositZap**
`function depositZap(uint256 amount) public hasZap(amount) hasApprovedZap(amount) returns (bool)`
Deposits Zap into Main Market Token Contract and approves Bondage

	Parameters:
	`amount` - uint256
	Returns:
	`zapToken.approve(bondageAddr, amount)` - bool

- **bond**
`function bond(uint256 dots) external hasEnoughZapForDots(dots) returns(uint256)`
spends Zap to bond to the Main Market Curve and obtains MainMarketTokens

	Parameters:
	`dots` - uint256
	Returns:
	`zapSpent` - uint256

- **unbond**
`function unbond(uint256 dots) external hasApprovedMMT(dots)`
exchanges MainMarketToken and unbonds dot from Main Market curve and transfers Zap back to user

	Parameters:
	`dots` - uint256

- **remove**
`function remove(address addr) public returns(bool)`
removes address from Main Market holders

	Parameters:
	`addr` - address
	Returns:
	`true` - bool

- **withdraw**
`function withdraw(uint256 amount, address addr) external returns(uint256)`
Withdraw Zap from gains/losses from Auxiliary Market and disperse 5% of the fee based on the percentage of bonded stake on the Main Market

	Parameters:
	`amount` - uint256
	`addr` - address
	Returns:
	`fee` - uint256

###Modifiers
   - `hasEnoughZapForDots` - Requires user to have enough zap to cover cost of dots
   - `hasZap` - Requires user to have enough Zap in their account
   - `hasApprovedZap` - Requires user to approve the Main Market Contract an allowance to spend zap on their behalf
   - `hasApprovedMMT` - Requires user to approve the Main Market Contract an allowance to spend MainMarketTokens on their behalf


## Functinality of Auxiliary Market
**Initialized with a `AuxMarketHolder` struct:**
**`avgPrice`** uint256 - average price tracker of all AuxiliaryMarketTokens user purchased
**`subTokensOwned`** uint256 - tracker of how many Auxiliary asset tokens user has

- **Constructor**

	Initializes the following:
	**`coordinator`** - Zap coordinator contract
	**`mainMarket`** - main market contract
	**`auxiliaryMarketToken` **- auxiliary market token contract
	**`zapToken`** -  Zap Token contract

- **assetPrices array**
    + Currently hard coded prices but should use getCurrentPrice() in the future to query an oracle to get the asset prices

- **buy**
`function buy(uint256 _quantity) public payable returns(uint256)`
purchases the auxiliary market token with zap for the cooresponding asset

	Parameters:
	`_quantity` - uint256

- **sell**
`function sell(uint256 _quantity) public hasApprovedAMT(_quantity)`
sells user's auxiliary market tokens for the asset and gets zap back

	Parameters:
	`_quantity` - uint256

- **getCurrentPrice**
    + **Suppose to query an oracle to obtain the asset's current price

- **getBalance**
`function getBalance(address _address) public view returns (uint256)`
get's user's current Zap balance

	Parameters:
	`_address` - address

- **allocateZap**
`function allocateZap(uint256 amount) public`
allocates user's zap to spend

	Parameters:
	`amount` - uint256

- **getAMTBalance**
`function getAMTBalance(address _owner) public view returns(uint256)`
get's User's current AuxiliaryMarketToken balance (corresponding to the asset of the Auxiliary Market)

	Parameters:
	`_owner` - address

###Modifiers
  - **`hasApprovedAMT` **- Requires User to approve the Main Market Contract an allowance to spend amt on their behalf

## Future of Project
- Allow Auxiliary Markets to deploy its own oracle and query from it