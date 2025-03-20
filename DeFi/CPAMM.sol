// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

import "../ERC_20/ERC20.sol";

contract CPAMM {
	IERC20 public immutable token0;
	IERC20 public immutable token1;

	uint256 public reserve0;
	uint256 public reserve1;

	uint256 public totalSupply;
	mapping(address => uint256) public _balances;
	
	constructor(address _token0, address _token1) {
		token0 = IERC20(_token0);
		token1 = IERC20(_token1);
	}

	function _mint(address _to, uint256 _amount) private {
		_balances[_to] += _amount;
		totalSupply += _amount;
	}

	function _burn(address _from, uint256 _amount) private {
		_balances[_from] -= _amount;
		totalSupply -= _amount;
	}

	function _update(uint256 _reserve0, uint256 _reserve1) private {
		reserve0 = _reserve0;
		reserve1 = _reserve1;
	}

	function swap(address _tokenIn, uint256 _amountIn) external returns(uint256 amountOut) {
		require(
			_tokenIn == address(token0) || _tokenIn == address(token1),
			"Invalid token"
		);
		require(_amountIn > 0, "amount in = 0");

		bool isToken0 = _tokenIn == address(token0);
		(IERC20 tokenIn, IERC20 tokenOut, uint256 reserveIn, uint256 reserveOut)
		= isToken0
			? (token0, token1, reserve0, reserve1)
			: (token1, token0, reserve1, reserve0);
		tokenIn.transferFrom(msg.sender, address(this), _amountIn);

		uint256 amountInWithFee = (_amountIn * 997) / 1000;
		amountOut = 
			(reserveOut * amountInWithFee) / (reserveIn + amountInWithFee);
		tokenOut.transfer(msg.sender, amountOut);

		_update(
			token0.balanceOf(address(this)),
			token1.balanceOf(address(this))
		);
	}

	function addLiquidity(uint256 _amount0, uint256 _amount1) external returns(uint256 shares) {
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

        if(reserve0 > 0 || reserve1 > 0) {
            require(
                reserve0 * _amount1 == reserve1 * _amount0,
                "x / y != dx / dy"
            );
        }
        if(totalSupply == 0) {
            shares = _sqrt(_amount0 * _amount1);
        } else {
            shares = _min(
                _amount0 * totalSupply / reserve0,
                _amount1 * totalSupply / reserve1
            );
            require(shares > 0, "shares = 0");
            _mint(msg.sender, shares);
        }

        _update(
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        );
    }

	function removeLiquidity(uint256 _shares) external returns(uint256 _amount0, uint256 _amount1) {
        uint256 bal0 = token0.balanceOf(address(this));
        uint256 bal1 = token1.balanceOf(address(this));

        _amount0 = (bal0 * _shares) / totalSupply;
        _amount1 = (bal1 * _shares) / totalSupply;
        require(_amount0 > 0 && _amount1 > 0, "amount0 or amount1 = 0");
        _burn(msg.sender, _shares);

        _update(bal0 - _amount0, bal0 - _amount1);
        token0.transfer(msg.sender, _amount0);
        token1.transfer(msg.sender, _amount1);
    }

	function _sqrt(uint256 y) private pure returns(uint256 z) {
		if(y > 3) {
			z = y;
			uint256 x = y / 2 + 1;
			while(x < z) {
				z = x;
				x = (y / x + x) / 2;
			}
		} else if(y != 0) {
			z = 1;
		}
	}

	function _min(uint256 x, uint256 y) private pure returns(uint256) {
		return x <= y ? x : y;
	}
}
