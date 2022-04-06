// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./MultisigWallet.sol";

contract MultisigWalletFactory {
    MultisigWallet[] public multisigWallets;

    mapping(address => bool) existsMultisigWallet;

    event Create(
        uint256 indexed contractId,
        address indexed contractAddress,
        address creator,
        address[] owners,
        uint256 signaturesRequired
    );

    event Owners(
        address indexed contractAddress,
        address[] owners,
        uint256 indexed signaturesRequired
    );

    constructor() {}

    modifier onlyRegistered() {
        require(
            existsMultisigWallet[msg.sender],
            "caller not registered to use logger"
        );
        _;
    }

    function emitOwners(
        address _contractAddress,
        address[] memory _owners,
        uint256 _signaturesRequired
    ) external onlyRegistered {
        emit Owners(_contractAddress, _owners, _signaturesRequired);
    }

    function numberOfMultisigWallets() public view returns (uint256) {
        return multisigWallets.length;
    }

    function create(
        uint256 _chainId,
        address[] memory _owners,
        uint256 _signaturesRequired
    ) public payable {
        uint256 id = numberOfMultisigWallets();

        MultisigWallet multisigWallet = (new MultisigWallet){value: msg.value}(
            _chainId,
            _owners,
            _signaturesRequired,
            address(this)
        );
        multisigWallets.push(multisigWallet);

        emit Create(
            id,
            address(multisigWallet),
            msg.sender,
            _owners,
            _signaturesRequired
        );
        emit Owners(address(multisigWallet), _owners, _signaturesRequired);
    }

    function getMultisigWallet(uint256 _index)
        public
        view
        returns (
            address multisigWalletAddress,
            uint256 signaturesRequired,
            uint256 balance
        )
    {
        MultisigWallet multisigWallet = multisigWallets[_index];
        return (
            address(multisigWallet),
            multisigWallet.signaturesRequired(),
            address(multisigWallet).balance
        );
    }
}
