// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

//pragma experimental ABIEncoderV2;

// functions for recovering and managing Ethereum account ECDSA signatures
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// MultisigWallet Factory
import "./MultisigWalletFactory.sol";

contract MultisigWallet {
    MultisigWalletFactory public multisigWalletFactory;

    // Pass the bytes32 as the first parameter for the ECDSA functions
    using ECDSA for bytes32;
    // Deposit event
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    // ExecuteTransactions event from calldata
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

    // Keep track of the MultisigWallet Owners
    address[] public owners;
    mapping(address => bool) public isOwner;

    uint256 public nonce;
    uint256 public chainId;
    uint256 public signaturesRequired;

    // Only Owners of the MultisigWallet
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not Owner");
        _;
    }

    // Only the MultisigWallet instance
    modifier onlySelf() {
        require(msg.sender == address(this), "Not Self");
        _;
    }

    // Non Zero signatures
    modifier nonZeroSignatures(uint256 _signaturesRequired) {
        require(_signaturesRequired > 0, "Must be non-zero sigs required");
        _;
    }

    // Non Zero address
    modifier nonZeroAddress(address _newOwner) {
        require(_newOwner != address(0), "Invalid owner");
        _;
    }

    constructor(
        uint256 _chainId,
        address[] memory _initialOwners,
        uint256 _signaturesRequired,
        address _factory
    ) payable nonZeroSignatures(_signaturesRequired) {
        multisigWalletFactory = MultisigWalletFactory(_factory);

        // Validate Owners & Signatures required
        require(_initialOwners.length > 0, "Owners required");
        require(
            _signaturesRequired > 0 &&
                _signaturesRequired <= _initialOwners.length,
            "Invalid required number of owners"
        );

        // Update MultisigWallet Owners
        for (uint256 i; i < _initialOwners.length; i++) {
            address owner = _initialOwners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "Owner is not unique");

            isOwner[owner] = true;
            owners.push(owner);

            emit Owner(owner, isOwner[owner]);
        }

        signaturesRequired = _signaturesRequired;
        chainId = _chainId;
    }

    // Enable receiving deposits
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    // Get the transaction hash
    function getTransactionHash(
        uint256 _nonce,
        address _to,
        uint256 _value,
        bytes memory _data
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    address(this),
                    chainId,
                    _nonce,
                    _to,
                    _value,
                    _data
                )
            );
    }

    // Returns the address that signed a hashed message (`hash`) with `signature`.
    function recover(bytes32 _hash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        return _hash.toEthSignedMessageHash().recover(_signature);
    }

    // Excute the calldata transaction
    function executeTransaction(
        address payable to,
        uint256 value,
        bytes memory data,
        bytes[] memory signatures
    ) public onlyOwner returns (bytes memory) {
        bytes32 _hash = getTransactionHash(nonce, to, value, data);

        nonce++;

        // Valid signatures counter
        uint256 validSignatures;
        address duplicateGuard;

        // Recover the signing addresess and validate if unique and update valid signatures
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

        // Validate number of signatures against required
        require(
            validSignatures >= signaturesRequired,
            "executeTransaction: not enough valid signatures"
        );

        // Execute the calldata
        (bool success, bytes memory result) = to.call{value: value}(data);
        require(success, "executeTransaction: tx failed");

        // Emit the ExecuteTransaction event
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

    // Add a new Owner
    function addOwner(address _newOwner, uint256 _newSignaturesRequired)
        public
        onlySelf
        nonZeroSignatures(_newSignaturesRequired)
        nonZeroAddress(_newOwner)
    {
        require(!isOwner[_newOwner], "addSigner: owner not unique");

        isOwner[_newOwner] = true;
        owners.push(_newOwner);
        signaturesRequired = _newSignaturesRequired;

        emit Owner(_newOwner, isOwner[_newOwner]);
        multisigWalletFactory.emitOwners(
            address(this),
            owners,
            _newSignaturesRequired
        );
    }

    // Remove a Owner
    function removeOwner(address _oldOwner, uint256 _newSignaturesRequired)
        public
        onlySelf
        nonZeroSignatures(_newSignaturesRequired)
    {
        require(isOwner[_oldOwner], "removeSigner: not owner");

        _removeOwnerList(_oldOwner);
        signaturesRequired = _newSignaturesRequired;

        emit Owner(_oldOwner, isOwner[_oldOwner]);
        multisigWalletFactory.emitOwners(
            address(this),
            owners,
            _newSignaturesRequired
        );
    }

    // Pop Owner from the list
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
}
