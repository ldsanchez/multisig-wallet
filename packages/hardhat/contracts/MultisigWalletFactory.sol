// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// MultisigWallet instance contract
import "./MultisigWallet.sol";

contract MultisigWalletFactory {
    // Keep track of MultisigWallet instances
    MultisigWallet[] public multisigWallets;
    mapping(address => bool) existsMultisigWallet;

    // MultisigWallet Create event
    event Create(
        uint256 indexed contractId,
        address indexed contractAddress,
        address creator,
        address[] owners,
        uint256 signaturesRequired
    );

    // MultisigWallet Owners event
    event Owners(
        address indexed contractAddress,
        address[] owners,
        uint256 indexed signaturesRequired
    );

    constructor() {}

    // Only registered wallet instances can call the logger
    modifier onlyRegistered() {
        require(
            existsMultisigWallet[msg.sender],
            "caller not registered to use logger"
        );
        _;
    }

    // Emit Owner events used from MultisigWallet instance
    function emitOwners(
        address _contractAddress,
        address[] memory _owners,
        uint256 _signaturesRequired
    ) external onlyRegistered {
        emit Owners(_contractAddress, _owners, _signaturesRequired);
    }

    // Get the number of wallets
    function numberOfMultisigWallets() public view returns (uint256) {
        return multisigWallets.length;
    }

    // Create a MultisigWallet instance and make it payable
    function createMultisigWallet(
        uint256 _chainId,
        address[] memory _owners,
        uint256 _signaturesRequired
    ) public payable {
        // MultisigWallet ID
        uint256 id = numberOfMultisigWallets();

        // Create a new instance
        MultisigWallet multisigWallet = (new MultisigWallet){value: msg.value}(
            _chainId,
            _owners,
            _signaturesRequired,
            address(this)
        );
        // Update
        multisigWallets.push(multisigWallet);
        existsMultisigWallet[address(multisigWallet)] = true;

        // Emit Create and Initial Owners events
        emit Create(
            id,
            address(multisigWallet),
            msg.sender,
            _owners,
            _signaturesRequired
        );
        emit Owners(address(multisigWallet), _owners, _signaturesRequired);
    }

    // Get MultisigWallet information
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
