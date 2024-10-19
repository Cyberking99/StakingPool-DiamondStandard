// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract KingCollections {
    mapping(uint256 => mapping(address => uint256)) public balances;
    mapping(uint256 => string) public tokenURIs;

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event URI(string value, uint256 indexed id);

    function _balanceOf(address account, uint256 id) public view returns (uint256) {
        return balances[id][account];
    }

    function _mint(address to, uint256 id, uint256 amount, string memory _uri) internal {
        balances[id][to] += amount;
        tokenURIs[id] = _uri;
        emit TransferSingle(msg.sender, address(0), to, id, amount);
        emit URI(_uri, id);
    }

    function uri(uint256 id) public view returns (string memory) {
        require(bytes(tokenURIs[id]).length > 0, "Error(ERC1155): Token ID does not exist");
        return tokenURIs[id];
    }
}