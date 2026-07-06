// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title SimpleRWA
/// @notice A minimal tokenized real-world-asset contract, shaped around what
///         Robinhood Chain is actually built for: transferable, DeFi-composable
///         real-world-asset tokens, but with the two properties every RWA
///         issuer needs -- an onchain compliance gate and a way to reflect
///         off-chain state (price/NAV) onchain.
///
///         This is intentionally simple: a single owner-controlled allowlist
///         (`isEligible`) gates transfers, and an owner-settable `pricePerShare`
///         mirrors an off-chain NAV or reference price feed. Real RWA issuance
///         (e.g. Robinhood's own Stock Tokens) uses far more machinery --
///         KYC providers, custodians, oracles, jurisdictional restrictions --
///         but this is the right shape to start learning the pattern from.
///
///         Not audited. For onboarding/demo purposes only.
contract SimpleRWA is ERC20, Ownable {
    /// @notice Off-chain reference price for one whole token, in USD cents.
    ///         e.g. 15042 == $150.42. Owner-settable to simulate an oracle
    ///         push; swap this for a real Chainlink feed read in production.
    uint256 public pricePerShareCents;

    /// @notice Compliance allowlist. Both sender and recipient must be
    ///         eligible for a transfer to succeed (mint/burn exempted via
    ///         the zero address checks in _isTransferAllowed).
    mapping(address => bool) public isEligible;

    event EligibilityUpdated(address indexed account, bool eligible);
    event PriceUpdated(uint256 oldPriceCents, uint256 newPriceCents);

    error NotEligible(address account);

    constructor(string memory name_, string memory symbol_, uint256 initialPriceCents, address owner_)
        ERC20(name_, symbol_)
        Ownable(owner_)
    {
        pricePerShareCents = initialPriceCents;
        isEligible[owner_] = true;
        emit EligibilityUpdated(owner_, true);
    }

    /// @notice Owner-gated mint, e.g. after an off-chain subscription/KYC flow
    ///         completes. Recipient must already be eligible.
    function mint(address to, uint256 amount) external onlyOwner {
        if (!isEligible[to]) revert NotEligible(to);
        _mint(to, amount);
    }

    function setEligibility(address account, bool eligible) external onlyOwner {
        isEligible[account] = eligible;
        emit EligibilityUpdated(account, eligible);
    }

    /// @notice Push an updated reference price. In production, replace this
    ///         with a Chainlink oracle read (Chainlink is RH Chain's official
    ///         oracle partner) instead of an owner-pushed value.
    function setPricePerShareCents(uint256 newPriceCents) external onlyOwner {
        uint256 old = pricePerShareCents;
        pricePerShareCents = newPriceCents;
        emit PriceUpdated(old, newPriceCents);
    }

    /// @dev Enforce the compliance gate on every transfer, including
    ///      transferFrom. Mint (from == address(0)) and burn (to ==
    ///      address(0)) skip the opposite-side check.
    function _update(address from, address to, uint256 value) internal override {
        if (from != address(0) && !isEligible[from]) revert NotEligible(from);
        if (to != address(0) && !isEligible[to]) revert NotEligible(to);
        super._update(from, to, value);
    }
}
