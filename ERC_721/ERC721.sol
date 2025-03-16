// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

// ERC721 - NFT.
interface IERC165 {
    function supportsInterface(bytes4 interfaceId)
        external view returns(bool);
}

interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns(uint256);
    function ownerOf(uint256 id) external view returns(address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) external;
    function transferFrom(address from, address to, uint256 id) external;
    function approve(address spender, uint256 id) external;
    function getApproval(uint256 id) external view returns(bool);
    function setApprovedForAll(address operator, bool approved) external;
    function isApprovedForAll(address  owner, address operator) external view returns(bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata 
    ) external returns(bytes4);
}

// IERC 1155 - MULTI TOKEN.
interface IERC1155 {
    function balanceOf(address owner, uint256 id) external view returns(uint256);
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) 
        external view returns(uint256[] memory);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id, 
        uint256 value,
        bytes calldata data
    ) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids, 
        uint256[] calldata values,
        bytes calldata data
    ) external;
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns(bool);
}

interface IERC1155TokenReceiver {
    function onERC1155Received(
        address operator, 
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns(bytes4);

    function onERC1155BatchReceived(
        address operator, 
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns(bytes4);
}

contract ERC1155 is IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    mapping(address => mapping(uint256 => uint256)) public _balanceOf;
    mapping(address => mapping(address => bool)) public _isApprovedForAll;

    function balanceOf(address owner, uint256 id) external view returns(uint256) {
        require(owner != address(0), "owner = 0 address");
        return _balanceOf[owner][id];
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) 
        external view returns(uint256[] memory balances) 
    {
        require(owners.length == ids.length, "owners length != ids length");
        balances = new uint256[](owners.length);

        unchecked {
            for(uint256 i = 0; i < owners.length; i++) {
                balances[i] = _balanceOf[owners[i]][ids[i]];
            }
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id, 
        uint256 value,
        bytes calldata data
    ) external {
        require(
            msg.sender == from || _isApprovedForAll[from][msg.sender],
            "Not authorized"
        );
        require(to != address(0), "Address is not valid");

        _balanceOf[from][id] -= value;
        _balanceOf[to][id] += value;
        emit TransferSingle(msg.sender, from, to, id, value);

        if(to.code.length > 0) {
            require(
                IERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender, from, id, value, data
                ) == IERC1155TokenReceiver.onERC1155Received.selector,
                "unsafe transfer"
            );
        }
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids, 
        uint256[] calldata values,
        bytes calldata data
    ) external {
        require(
            msg.sender == from || _isApprovedForAll[from][msg.sender],
            "Not authorized"
        );
        require(ids.length == values.length, "ids length != values length");
        require(to != address(0), "Address is not valid");

        for(uint256 i = 0; i < ids.length; i++) {
            _balanceOf[from][ids[i]] -= values[i];
            _balanceOf[to][ids[i]] += values[i];
        }
        emit TransferBatch(msg.sender, from, to, ids, values);

        if(to.code.length > 0) {
            require(
                IERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender, from, ids, values, data
                ) == IERC1155TokenReceiver.onERC1155Received.selector,
                "unsafe transfer"
            );
        }
    }
    function setApprovalForAll(address operator, bool approved) external {
        require(operator != address(0), "Address is not valid");
        _isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) external view returns(bool) {
        return _isApprovedForAll[owner][operator];
    }

    function _mint(address _to, uint256 id, uint256 value, bytes calldata data) internal {
        require(_to != address(0), "Address is not valid");
        _balanceOf[_to][id] += value;
        emit TransferSingle(msg.sender, address(0), _to, id, value);

        if(_to.code.length > 0) {
            require(
                IERC1155TokenReceiver(_to).onERC1155Received(
                    msg.sender, address(0), id, value, data
                ) == IERC1155TokenReceiver.onERC1155Received.selector,
                "unsafe transfer"
            );
        }
    }

    function _batchMint(
        address _to, 
        uint256[] calldata ids, 
        uint256[] calldata values, 
        bytes calldata data
    ) internal {
        require(ids.length == values.length, "ids length != values length");
        require(_to != address(0), "Address is not valid");

        for(uint256 i = 0; i < ids.length; i++) {
            _balanceOf[_to][ids[i]] += values[i];
        }
        emit TransferBatch(msg.sender, address(0), _to, ids, values);

        if(_to.code.length > 0) {
            require(
                IERC1155TokenReceiver(_to).onERC1155BatchReceived(
                    msg.sender, address(0), ids, values, data
                ) == IERC1155TokenReceiver.onERC1155Received.selector,
                "unsafe transfer"
            );
        }
    } 

    function _burn(address _from, uint256 id, uint256 value) internal {
        require(_from != address(0), "Address is not valid");
        _balanceOf[_from][id] -= value;
        emit TransferSingle(msg.sender, _from, address(0), id, value);
    }

    function _batchBurn(
        address _from, 
        uint256[] calldata ids, 
        uint256[] calldata values
    ) internal {
        require(_from != address(0), "Address is not valid");
        require(ids.length == values.length, "ids length != values length");

        for(uint256 i = 0; i < ids.length; i++) {
            _balanceOf[_from][ids[i]] -= values[i];
        }
        emit TransferBatch(msg.sender, _from, address(0), ids, values);
    }
}