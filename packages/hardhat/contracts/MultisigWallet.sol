// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./MultisigWalletFactory.sol";

contract MultisigWallet {
    MultisigWalletFactory public multisigWalletFactory;
    using ECDSA for bytes32;

    event Deposit(address indexed sender, uint256 amount);
    event Submit(uint256 indexed txId);
    event Approve(address indexed owner, uint256 indexed txId);
    event Revoke(address indexed owner, uint256 indexed txId);
    event Execute(uint256 indexed txId);
    event Owner(address indexed owner, bool added);

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public signaturesRequired;

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public approved;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, " tx does not exist");
        _;
    }

    modifier notApproved(uint256 _txId) {
        require(!approved[_txId][msg.sender], "tx already approved");
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "Not Self");
        _;
    }

    modifier requireNonZeroSignatures(uint256 _signaturesRequired) {
        require(_signaturesRequired > 0, "Must be non-zero sigs required");
        _;
    }

    constructor(
        uint256 _chainId,
        address[] memory _owners,
        uint256 _signaturesRequired,
        address _factory
    ) payable {
        require(_owners.length > 0, "Owners required");
        require(
            _signaturesRequired > 0 && _signaturesRequired <= _owners.length,
            "Invalid required number of owners"
        );

        for (uint256 i; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "Owner is no unique");

            isOwner[owner] = true;
            owners.push(owner);

            emit Owner(owner, isOwner[owner]);
        }

        signaturesRequired = _signaturesRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function getTransactionHash(
        uint256 _nonce,
        address to,
        uint256 value,
        bytes memory data
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    address(this),
                    //chainId,
                    _nonce,
                    to,
                    value,
                    data
                )
            );
    }

    function recover(bytes32 _hash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        return _hash.toEthSignedMessageHash().recover(_signature);
    }

    //     function addSigner(address newSigner, uint256 newSignaturesRequired) public onlySelf {
    //     require(newSigner != address(0), "addSigner: zero address");
    //     require(!isOwner[newSigner], "addSigner: owner not unique");
    //     require(newSignaturesRequired > 0, "addSigner: must be non-zero sigs required");
    //     isOwner[newSigner] = true;
    //     owners.push(newSigner);
    //     confirmationsRequired = newSignaturesRequired;
    //     logger.emitOwners(address(this), owners, confirmationsRequired);
    //   }

    //   function removeSigner(address oldSigner, uint256 newSignaturesRequired) public onlySelf {
    //     require(isOwner[oldSigner], "removeSigner: not owner");
    //     require(newSignaturesRequired > 0, "removeSigner: must be non-zero sigs required");
    //     _eliminateOwner(oldSigner);
    //     confirmationsRequired = newSignaturesRequired;
    //     logger.emitOwners(address(this), owners, confirmationsRequired);
    //   }

    function addOwner(address newOwner, uint256 newSignaturesRequired)
        public
        onlySelf
        requireNonZeroSignatures(newSignaturesRequired)
    {
        require(newOwner != address(0), "addSigner: zero address");
        require(!isOwner[newOwner], "addSigner: owner not unique");

        isOwner[newOwner] = true;
        owners.push(newOwner);
        signaturesRequired = newSignaturesRequired;

        emit Owner(newOwner, isOwner[newOwner]);
        multisigWalletFactory.emitOwners(
            address(this),
            owners,
            newSignaturesRequired
        );
    }

    //   function removeSigner(address oldSigner, uint256 newSignaturesRequired) public onlySelf requireNonZeroSignatures(newSignaturesRequired) {
    //     require(isOwner[oldSigner], "removeSigner: not owner");

    //      _removeOwner(oldSigner);
    //     signaturesRequired = newSignaturesRequired;

    //     emit Owner(oldSigner, isOwner[oldSigner]);
    //     multiSigFactory.emitOwners(address(this), owners, newSignaturesRequired);
    //   }

    function submit(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner {
        transactions.push(
            Transaction({to: _to, value: _value, data: _data, executed: false})
        );

        emit Submit(transactions.length - 1);
    }

    function approve(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
    {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount(uint256 _txId)
        private
        view
        returns (uint256 count)
    {
        for (uint256 i; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                count += 1;
            }
        }
    }

    function execute(uint256 _txId)
        external
        txExists(_txId)
        notExecuted(_txId)
    {
        require(
            _getApprovalCount(_txId) >= signaturesRequired,
            "approvals < required"
        );
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );

        require(success, "tx failed");

        emit Execute(_txId);
    }

    function revoke(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        require(approved[_txId][msg.sender], "tx not approved");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }
}
