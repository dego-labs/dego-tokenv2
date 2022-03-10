// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../library/ERC20.sol";

/// @title DegoTokenV2 Contract
contract DegoTokenV2 is Ownable, ERC20, Pausable {
    using SafeMath for uint256;

    //events
    event eveSetRate(uint256 burn_rate, uint256 reward_rate);
    event eveRewardPool(address rewardPool);
    event Mint(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed sender, uint256 indexed value);

    event AddMinter(address minter);
    event DelMinter(address minter);

    event AddBlackAccount(address blackAccount);
    event DelBlackAccount(address blackAccount);

    // for minters
    mapping (address => bool) public _minters;

    // for black list
    mapping(address => bool) public blackAccountMap;
    
    /// Constant token specific fields
    uint256 public  _maxSupply = 0;

    // hardcode limit rate
    uint256 public constant _maxGovernValueRate = 2000;// 2000/10000
    uint256 public constant _minGovernValueRate = 0;  // 0
    uint256 public constant _rateBase = 10000; 

    // additional variables for use if transaction fees ever became necessary
    uint256 public  _burnRate = 0;       
    uint256 public  _rewardRate = 0;   

    uint256 public _totalBurnToken = 0;
    uint256 public _totalRewardToken = 0;

    // reward pool!
    address public _rewardPool = 0x6666666666666666666666666666666666666666;
    
    // burn pool!
    address public _burnPool = 0x6666666666666666666666666666666666666666;

    /**
     * CONSTRUCTOR
     *
     * @dev Initialize the Token
     */

    constructor () public ERC20("dego.finance", "DEGOV2") {
         _maxSupply = 21000000 * (10**18);
    }

    /**
    * @dev for mint function
    */
    function mint(address account, uint256 amount) external 
    {
        require(account != address(0), "ERC20: mint to the zero address");
        require(_minters[msg.sender], "!minter");

        uint256 curMintSupply = totalSupply().add(_totalBurnToken);
        uint256 newMintSupply = curMintSupply.add(amount);
        require(newMintSupply <= _maxSupply,"supply is max!");
        
        _mint(account, amount);
        emit Mint(address(0), account, amount);
    }

    function pause() external onlyOwner{
        super._pause();
    }

    function unpause() external onlyOwner{
        super._unpause();
    }

    function addMinter(address _minter) external onlyOwner
    {
        require(!_minters[_minter], "is minter");
        _minters[_minter] = true;
        emit AddMinter(_minter);
    }
    
    function removeMinter(address _minter) external onlyOwner 
    {
        require(_minters[_minter], "not is minter");
        _minters[_minter] = false;
        emit DelMinter(_minter);
    }

    function addBlackAccount(address _blackAccount) external onlyOwner {
        require(!blackAccountMap[_blackAccount], "has in black list");
        blackAccountMap[_blackAccount] = true;
        emit AddBlackAccount(_blackAccount);
    }

    function delBlackAccount(address _blackAccount) external onlyOwner {
        require(blackAccountMap[_blackAccount], "not in black list");

        blackAccountMap[_blackAccount] = false;
        emit DelBlackAccount(_blackAccount);
    }

    /**
    * @dev for govern value
    */
    function setRate(uint256 burn_rate, uint256 reward_rate) external 
        onlyOwner 
    {
        require(_maxGovernValueRate >= burn_rate && burn_rate >= _minGovernValueRate,"invalid burn rate");
        require(_maxGovernValueRate >= reward_rate && reward_rate >= _minGovernValueRate,"invalid reward rate");

        _burnRate = burn_rate;
        _rewardRate = reward_rate;

        emit eveSetRate(burn_rate, reward_rate);
    }

    /**
    * @dev for set reward
    */
    function setRewardPool(address rewardPool) external 
        onlyOwner 
    {
        require(rewardPool != address(0x0));

        _rewardPool = rewardPool;

        emit eveRewardPool(_rewardPool);
    }
    
    
    /**
    * @dev Transfer tokens with fee
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256s the amount of tokens to be transferred
    */
    function _transfer(address from, address to, uint256 value)
    internal override whenNotPaused
    {
        require(!blackAccountMap[from], "can't transfer");
        uint256 sendAmount = value;
        uint256 burnFee = (value.mul(_burnRate)).div(_rateBase);
        if (burnFee > 0) {
            //to burn
            super._transfer(from, _burnPool, burnFee);
            _totalSupply = _totalSupply.sub(burnFee);
            sendAmount = sendAmount.sub(burnFee);
            _totalBurnToken = _totalBurnToken.add(burnFee);
        }

        uint256 rewardFee = (value.mul(_rewardRate)).div(_rateBase);
        if (rewardFee > 0) {
           //to reward
            super._transfer(from, _rewardPool, rewardFee);
            sendAmount = sendAmount.sub(rewardFee);
            _totalRewardToken = _totalRewardToken.add(rewardFee);
        }
        super._transfer(from, to, sendAmount);
    }
}