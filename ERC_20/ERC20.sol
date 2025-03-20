// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

// ERC20 - TOKEN.
interface IERC20 {
    function totalSupply() external view returns(uint256);
    function balanceOf(address _account) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

contract ERC20 is IERC20 {
    string public name;
    string public symbol;
    uint256 public _totalSupply;
    uint256 public decimals;

    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public allowances;

    constructor(string memory _name, string memory _symbol, uint256 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function totalSupply() external view returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address _account) external view returns(uint256) {
        require(_account != address(0), "Address is not valid");
        return _balances[_account];
    }

    function allowance(address owner, address spender)
        external view returns(uint256)
    {
        return allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount) external returns(bool) {
        require(recipient != address(0), "Address is not valid");
        require(amount <= _balances[msg.sender], "Insufficient amount");
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;

    }
    function approve(address spender, uint256 amount) external returns(bool) {
        require(spender != address(0), "Address is not valid");
        require(amount <= _balances[msg.sender], "Insufficient amount");
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool) {
        require(recipient != address(0), "Address is not valid");
        require(amount <= allowances[sender][msg.sender], "Insufficient amount");
        require(amount <= _balances[sender], "Insufficient amount");

        allowances[sender][msg.sender] -= amount;
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _mint(address _to, uint256 _amount) internal {
        require(_to != address(0), "Address is not valid");
        _balances[_to] += _amount;
        _totalSupply += _amount;
    }

    function _burn(address _from, uint256 _amount) internal {
        require(_from != address(0), "Address is not valid");
        _balances[_from] -= _amount;
        _totalSupply -= _amount;
    }
}