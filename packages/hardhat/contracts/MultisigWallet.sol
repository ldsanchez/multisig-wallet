// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./MultisigWalletFactory.sol";

contract MultisigWallet {
    MultisigWalletFactory public multisigWalletFactory;
    using ECDSA for bytes32;

    event Deposit(address indexed sender, uint256 amount);
    event Submit(uint256 indexed txId);
    event Approve(address indexed owner, uint256 indexed txId);
    event Revoke(address indexed owner, uint256 indexed txId);
    //event Execute(uint256 indexed txId);
    event ExecuteTransaction(
        address indexed owner,
        address payable to,
        uint256 value,
        bytes data,
        uint256 nonce,
        bytes32 hash,
        bytes result
    );
    event Owner(address indexed owner, bool added);

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public nonce;
    uint256 public chainId;
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

    modifier nonZeroSignatures(uint256 _signaturesRequired) {
        require(_signaturesRequired > 0, "Must be non-zero sigs required");
        _;
    }

    modifier nonZeroAddress(address _newOwner) {
        require(_newOwner != address(0), "addSigner: zero address");
        _;
    }

    constructor(
        uint256 _chainId,
        address[] memory _owners,
        uint256 _signaturesRequired,
        address _factory
    ) payable {
        multisigWalletFactory = MultisigWalletFactory(_factory);
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
        chainId = _chainId;
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
                    chainId,
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

    function addSigner(address newOwner, uint256 newSignaturesRequired)
        public
        onlySelf
        nonZeroSignatures(newSignaturesRequired)
        nonZeroAddress(newOwner)
    {
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

    function removeSigner(address _oldOwner, uint256 newSignaturesRequired)
        public
        onlySelf
        nonZeroSignatures(newSignaturesRequired)
    {
        require(isOwner[_oldOwner], "removeSigner: not owner");

        _removeOwnerList(_oldOwner);
        signaturesRequired = newSignaturesRequired;

        emit Owner(_oldOwner, isOwner[_oldOwner]);
        multisigWalletFactory.emitOwners(
            address(this),
            owners,
            newSignaturesRequired
        );
    }

    function _removeOwnerList(address _oldOwner) private {
        isOwner[_oldOwner] = false;
        uint256 ownersLength = owners.length;
        address[] memory poppedOwners = new address[](owners.length);
        for (uint256 i = ownersLength - 1; i >= 0; i--) {
            if (owners[i] != _oldOwner) {
                poppedOwners[i] = owners[i];
                owners.pop();
            } else {
                owners.pop();
                for (uint256 j = i; j < ownersLength - 1; j++) {
                    owners.push(poppedOwners[j]);
                }
                return;
            }
        }
    }

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

    // function execute(uint256 _txId)
    //     external
    //     txExists(_txId)
    //     notExecuted(_txId)
    // {
    //     require(
    //         _getApprovalCount(_txId) >= signaturesRequired,
    //         "approvals < required"
    //     );
    //     Transaction storage transaction = transactions[_txId];
    //     transaction.executed = true;

    //     (bool success, ) = transaction.to.call{value: transaction.value}(
    //         transaction.data
    //     );

    //     require(success, "tx failed");

    //     emit Execute(_txId);
    // }

    function executeTransaction(
        address payable to,
        uint256 value,
        bytes memory data,
        bytes[] memory signatures
    ) public onlyOwner returns (bytes memory) {
        bytes32 _hash = getTransactionHash(nonce, to, value, data);

        nonce++;

        uint256 validSignatures;
        address duplicateGuard;
        for (uint256 i = 0; i < signatures.length; i++) {
            address recovered = recover(_hash, signatures[i]);
            require(
                recovered > duplicateGuard,
                "executeTransaction: duplicate or unordered signatures"
            );
            duplicateGuard = recovered;

            if (isOwner[recovered]) {
                validSignatures++;
            }
        }

        require(
            validSignatures >= signaturesRequired,
            "executeTransaction: not enough valid signatures"
        );

        (bool success, bytes memory result) = to.call{value: value}(data);
        require(success, "executeTransaction: tx failed");

        emit ExecuteTransaction(
            msg.sender,
            to,
            value,
            data,
            nonce - 1,
            _hash,
            result
        );
        return result;
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
