/**
 *Submitted for verification at scan.coredao.com on 2023-05-01
*/

//SPDX-License-Identifier: MIT

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol
// Solidity signature: VTS DEV0x00

/*
https://sluppyup.com / Website
https://t.me/SluppyYup / Telegram
https://twitter.com/SluppyYup / Twitter
*/


import "./UniswapV2Router1.sol";
import "./UniswapV2Router2.sol";
import "./UniswapV2Factory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./context.sol";
import "./safemath.sol";
import "./ierc20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";



// File: contracts/3_Ballot.sol


pragma solidity ^0.8.10;







contract SluppyToken is Context, ERC20Burnable, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => bool) controllers;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) public _isBlackListed;
    mapping(address => bool) private _isExcluded;

    address[] private _excluded;

    address private constant BUSD =
        address(0x81bCEa03678D1CEF4830942227720D542Aa15817);

    /// ERROR

    error SluppyToken__OnlyControllersCanMint();


    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1 * 10**8 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Sluppy"; 
    string private _symbol = "SL";
    uint8 private _decimals = 9;

    struct BuyFee {
        uint16 liquidityFee;
        uint16 marketingFee;
        uint16 buybackFee;
        uint16 taxFee;
    }

    struct SellFee {
        uint16 liquidityFee;
        uint16 marketingFee;
        uint16 buybackFee;
        uint16 taxFee;
    }

    BuyFee public buyFee;
    SellFee public sellFee;

    uint16 private _taxFee;
    uint16 private _liquidityFee;
    uint16 private _marketingFee;
    uint16 private _buybackFee;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address public _marketingWallet = payable(address(0x38897AeC34Eb1256A15989E2866Ebbd1680f7aa3)); 
    address public _buybackWallet = payable(address(0x19C26514D557581eBe91E4005EB0BA8622119D7A)); 

    bool internal inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
     bool private isTradingEnabled;
    uint256 public tradingStartBlock;
   
    uint256 private lastBlock;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;

    uint256 private numTokensSellToAddToLiquidity = 1 * 10**7 * 10**9; 
    uint8 public constant BLOCKCOUNT = 100;


    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    } //what do you want the token amount to be for threshhold

    constructor() {
        _rOwned[_msgSender()] = _rTotal;

        buyFee.liquidityFee = 4; //liquidity
        buyFee.marketingFee = 1; //marketing
        buyFee.buybackFee = 1; //buyback
        buyFee.taxFee = 4; //reflections

        sellFee.liquidityFee = 5; //liquidity
        sellFee.marketingFee = 1; //marketing
        sellFee.buybackFee = 1; //buyback
        sellFee.taxFee = 5; //reflections 

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(BUSD, address(this));

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        maxSellAmount = totalSupply().mul(125).div(100000);
        maxBuyAmount = totalSupply().mul(125).div(100000);
        maxWalletAmount = totalSupply().mul(5).div(1000);

        IERC20(BUSD).approve(address(uniswapV2Router), ~uint256(0));

        lastBlock = block.number;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }


    /// FUNCTIONS

    function mint(address to, uint256 amount) external {
        if (!controllers[msg.sender]){
            revert SluppyToken__OnlyControllersCanMint();
        }
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) external {
        if (controllers[msg.sender]){
            _burn(account, amount);
        }
    }
    /// OWNER FUNCTION
    function setController(address controller, bool _state)
        external
        payable
        onlyOwner
    {
        controllers[controller] = _state;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

     function enableTrading() external onlyOwner {
        isTradingEnabled = true;
        tradingStartBlock = block.number;
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function setBlackList(address addr, bool value) external onlyOwner {
        _isBlackListed[addr] = value;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setBuyFee(
        uint16 liq,
        uint16 market,
        uint16 buyback,
        uint16 tax
    ) external onlyOwner {
        buyFee.liquidityFee = liq;
        buyFee.marketingFee = market;
        buyFee.buybackFee = buyback;
        buyFee.taxFee = tax;
    }

    function setSellFee(
        uint16 liq,
        uint16 market,
        uint16 buyback,
        uint16 tax
    ) external onlyOwner {
        sellFee.liquidityFee = liq;
        sellFee.marketingFee = market;
        sellFee.buybackFee = buyback;
        sellFee.taxFee = tax;
    }

    function setNumTokensSellToAddToLiquidity(uint256 numTokens)
        external
        onlyOwner
    {
        numTokensSellToAddToLiquidity = numTokens;
    }

    function updateRouter(address newAddress) external onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "TOKEN: The router already has that address"
        );
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), BUSD);
        uniswapV2Pair = _uniswapV2Pair;
    }

    

    function setMaxWallet(uint256 value) external onlyOwner {
        maxWalletAmount = value;
    }

    function setMaxBuyAmount(uint256 value) external onlyOwner {
        maxBuyAmount = value;
    }

    function setMaxSellAmount(uint256 value) external onlyOwner {
        maxSellAmount = value;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function claimStuckTokens(address _token) external onlyOwner {
        require(_token != address(this), "No rug pulls :)");

        if (_token == address(0x0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }

        IERC20 erc20token = IERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(owner(), balance);
    }

    receive() external payable {
        this;
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBuyback,
            uint256 tMarketing
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tBuyback,
            tMarketing,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tBuyback = calculateBuyBackFee(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        tTransferAmount = tTransferAmount.sub(tBuyback).sub(tMarketing);
        return (tTransferAmount, tFee, tLiquidity, tBuyback, tMarketing);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 tBuyback,
        uint256 tMarketing,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rBuyback = tBuyback.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rTransferAmount = rAmount
            .sub(rFee)
            .sub(rLiquidity)
            .sub(rBuyback)
            .sub(rMarketing);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function _takeRewardAndMarketing(uint256 tBuyback, uint256 tMarketing)
        private
    {
        uint256 currentRate = _getRate();
        uint256 rBuyback = tBuyback.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);

        _rOwned[address(this)] = _rOwned[address(this)].add(rMarketing).add(
            rBuyback
        );
        if (_isExcluded[address(this)]) {
        _tOwned[address(this)] = _tOwned[address(this)].add(tMarketing).add(
            tBuyback
        );
        }
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_liquidityFee).div(10**2);
    }

    function calculateBuyBackFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_buybackFee).div(10**2);
    }

    function calculateMarketingFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_marketingFee).div(10**2);
    }

    function removeAllFee() private {
        _taxFee = 0;
        _liquidityFee = 0;
        _buybackFee = 0;
        _marketingFee = 0;
    }

    function setBuy() private {
        _taxFee = buyFee.taxFee;
        _liquidityFee = buyFee.liquidityFee;
        _buybackFee = buyFee.buybackFee;
        _marketingFee = buyFee.marketingFee;
    }

    function setSell() private {
        _taxFee = sellFee.taxFee;
        _liquidityFee = sellFee.liquidityFee;
        _buybackFee = sellFee.buybackFee;
        _marketingFee = sellFee.marketingFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBlackListed[from] && !_isBlackListed[to],"Account is blacklisted");
        require(
            isTradingEnabled || _isExcludedFromFee[from],
            "Trading not enabled yet"
        );


        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;

          contractTokenBalance = numTokensSellToAddToLiquidity;

            uint256 forMarketing = contractTokenBalance
                .mul(buyFee.marketingFee + sellFee.marketingFee)
                .div(
                    buyFee.marketingFee +
                        sellFee.marketingFee +
                        buyFee.liquidityFee +
                        sellFee.liquidityFee +
                        buyFee.buybackFee +
                        sellFee.buybackFee
                );

            uint256 forLiquidity = contractTokenBalance
                .mul(buyFee.liquidityFee + sellFee.liquidityFee)
                .div(
                    buyFee.marketingFee +
                        sellFee.marketingFee +
                        buyFee.liquidityFee +
                        sellFee.liquidityFee +
                        buyFee.buybackFee +
                        sellFee.buybackFee
                );

            swapAndConvert(
                contractTokenBalance - forLiquidity - forMarketing,
                forLiquidity,
                forMarketing
            );
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, buyback, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndConvert(
        uint256 forBuyBack,
        uint256 forLiquidity,
        uint256 forMarketing
    ) private lockTheSwap {
        uint256 initialBalance = IERC20(BUSD).balanceOf(address(this));
        uint256 half = forLiquidity.div(2);

        swapTokensForBNB(forBuyBack + forMarketing + half);
        swapBNBForBUSD(address(this).balance);

        uint256 newBalance = IERC20(BUSD).balanceOf(address(this)).sub(
            initialBalance
        );

        uint256 buybackAmount = newBalance.mul(forBuyBack).div(
            forBuyBack + forMarketing + half
        );
        IERC20(BUSD).transfer(_buybackWallet, buybackAmount);

        uint256 marketingAmount = newBalance.mul(forMarketing).div(
            forBuyBack + forMarketing + half
        );
        IERC20(BUSD).transfer(_marketingWallet, marketingAmount);

        addLiquidity(half, newBalance - buybackAmount - marketingAmount);
    }


    function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = BUSD;
        path[2] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBNBForBUSD(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = BUSD;

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(
            0, // accept any amount of Tokens
            path,
            address(this),
            block.timestamp.add(300)
        );
    }

    function swapTokensForBUSD(uint256 tokenAmount, address recepient) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = BUSD;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            recepient,
            block.timestamp.add(360)
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 busdAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidity(
            address(this),
            BUSD,
            tokenAmount,
            busdAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        removeAllFee();

        if (takeFee) {

            require(block.number > lastBlock,"One transfer per block");

            lastBlock = block.number;

           

            if (recipient != uniswapV2Pair) {
                require(
                    balanceOf(recipient) + amount <= maxWalletAmount,
                    "Balance exceeds limit"
                );
            }
            if (sender == uniswapV2Pair) {
                require(amount <= maxBuyAmount, "Buy exceeds limit");
                 if (block.number < tradingStartBlock + BLOCKCOUNT) {
                    _isBlackListed[recipient] = true;
                }
                setBuy();
            }
            if (recipient == uniswapV2Pair) {
                require(amount <= maxSellAmount, "Sell exceeds limit");
                setSell();
            }
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeRewardAndMarketing(
            calculateBuyBackFee(tAmount),
            calculateMarketingFee(tAmount)
        );
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeRewardAndMarketing(
            calculateBuyBackFee(tAmount),
            calculateMarketingFee(tAmount)
        );
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeRewardAndMarketing(
            calculateBuyBackFee(tAmount),
            calculateMarketingFee(tAmount)
        );
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeRewardAndMarketing(
            calculateBuyBackFee(tAmount),
            calculateMarketingFee(tAmount)
        );
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    } 

}