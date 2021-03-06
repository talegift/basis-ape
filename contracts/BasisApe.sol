import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./basiscash/IPool.sol";
import "./interfaces/IBasisApeFactory.sol";

// v0.1.0
contract BasisApe is Ownable {
  address public factory;
  address public beneficiary;

  event Deposit(uint256 amount);
  event Withdraw(address recipient, uint256 amount);
  event EmergencyExit(address recipient);
  event EmergencyWithdraw(address recipient, uint256 amount);

  constructor(address _beneficiary) Ownable() public {
    factory = msg.sender;
    beneficiary = _beneficiary;
  }

  function deposit(uint256 amount) external onlyOwner {
    address pool = IBasisApeFactory(factory).pool();
    address asset = IBasisApeFactory(factory).asset();
    IERC20(asset).approve(pool, amount);
    IPool(pool).stake(amount);
    emit Deposit(amount);
  }

  function withdraw(address recipient, uint256 amount) external onlyOwner {
    address pool = IBasisApeFactory(factory).pool();
    address asset = IBasisApeFactory(factory).asset();
    address bac = IBasisApeFactory(factory).bac();
    IPool(pool).withdraw(amount);
    IPool(pool).getReward();
    IERC20(asset).transfer(msg.sender, amount);
    IERC20(bac).transfer(recipient, IERC20(bac).balanceOf(address(this)));
    emit Withdraw(recipient, amount);
  }

  /*
   * WARNING: DO NOT CALL UNLESS YOU KNOW WHAT YOU'RE DOING
   * Calling this function will break BasisApeFactory functionality. Only use if absolutely necessary.
   */
  function emergencyExit(address recipient) external {
    require(msg.sender == beneficiary, "BasisApe: Must be called by beneficiary");
    address pool = IBasisApeFactory(factory).pool();
    address asset = IBasisApeFactory(factory).asset();
    address bac = IBasisApeFactory(factory).bac();
    IPool(pool).exit();
    IERC20(asset).transfer(recipient, IERC20(asset).balanceOf(address(this)));
    IERC20(bac).transfer(recipient, IERC20(bac).balanceOf(address(this)));
    emit EmergencyExit(recipient);
  }

  /*
   * WARNING: DO NOT CALL UNLESS YOU KNOW WHAT YOU'RE DOING
   * Calling this function will break BasisApeFactory functionality. Only use if absolutely necessary.
   * Rewards are not withdrawn and will be locked.
   */
  function emergencyWithdraw(address recipient, uint256 amount) external {
    require(msg.sender == beneficiary, "BasisApe: Must be called by beneficiary");
    address pool = IBasisApeFactory(factory).pool();
    address asset = IBasisApeFactory(factory).asset();
    IPool(pool).withdraw(amount);
    IERC20(asset).transfer(recipient, amount);
    emit EmergencyWithdraw(recipient, amount);
  }
}
