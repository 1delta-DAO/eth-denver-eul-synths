import {ERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Fiat is ERC20 {
    uint8 private immutable _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20(name, symbol) {
        _decimals = decimals;
        _mint(msg.sender, 1_000_000 * 10 ** decimals);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
