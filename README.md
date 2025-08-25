# Staking Rewards Token Project

A decentralized staking rewards smart contract built on the Stacks blockchain using Clarity. This project allows users to stake tokens and earn rewards over time based on a configurable reward rate.

## Features

- **Token Staking**: Users can stake tokens to earn rewards over time
- **Flexible Unstaking**: Partial or full unstaking of tokens
- **Reward Claiming**: Users can claim accumulated rewards at any time
- **Admin Controls**: Contract owner can manage reward rates, minimum stake amounts, and pause functionality
- **Transparent Calculations**: All reward calculations are done on-chain and are fully auditable

## Smart Contract Overview

The contract implements a time-based staking mechanism where users earn rewards proportional to their staked amount and the duration of their stake.

### Key Components

- **Staking Mechanism**: Users stake tokens and earn rewards per block based on the reward rate
- **Reward Pool**: A pool of tokens managed by the contract owner to distribute as rewards
- **Admin Functions**: Owner-only functions for contract management
- **Safety Features**: Pause functionality and input validation

## Contract Functions

### Public Functions

#### `stake(amount)`
Stakes the specified amount of tokens. Users must stake at least the minimum stake amount.

**Parameters:**
- `amount` (uint): Amount of tokens to stake

**Returns:** `(response uint uint)`

#### `unstake(amount)`
Unstakes the specified amount of tokens. Rewards are automatically updated before unstaking.

**Parameters:**
- `amount` (uint): Amount of tokens to unstake

**Returns:** `(response uint uint)`

#### `claim-rewards()`
Claims all accumulated rewards for the caller.

**Returns:** `(response uint uint)`

#### Admin Functions (Owner Only)

- `add-to-reward-pool(amount)`: Adds tokens to the reward pool
- `set-reward-rate(new-rate)`: Updates the reward rate (in basis points)
- `set-min-stake-amount(new-amount)`: Updates minimum stake amount
- `set-contract-paused(paused)`: Pauses or unpauses the contract

### Read-Only Functions

- `get-stake-info(staker)`: Returns staking information for a user
- `get-pending-rewards(staker)`: Returns pending rewards for a user
- `get-total-staked()`: Returns total amount staked in the contract
- `get-reward-rate()`: Returns current reward rate
- `get-min-stake-amount()`: Returns minimum stake amount
- `get-reward-pool()`: Returns current reward pool balance
- `is-contract-paused()`: Returns contract pause status
- `get-contract-owner()`: Returns contract owner address

## Reward Calculation

Rewards are calculated using the following formula:

```
reward_per_block = (staked_amount × reward_rate) / 10000
total_rewards = reward_per_block × blocks_since_last_claim
```

The reward rate is expressed in basis points (1% = 100 basis points).

## Contract Parameters

- **Default Reward Rate**: 100 basis points (1% per block period)
- **Minimum Stake Amount**: 1,000,000 (1 token with 6 decimals)
- **Initial Reward Pool**: 0 (must be funded by owner)

## Deployment

1. Deploy the contract to the Stacks blockchain
2. Fund the reward pool using `add-to-reward-pool`
3. Adjust parameters as needed using admin functions
4. Users can begin staking tokens

## Security Features

- **Owner-only functions** are protected by authorization checks
- **Input validation** prevents invalid amounts and operations
- **Pause functionality** allows emergency contract suspension
- **Reward pool management** ensures rewards are backed by actual tokens
- **Overflow protection** through Clarity's built-in safety features

## Usage Example

```clarity
;; Stake 10 tokens (assuming 6 decimals)
(contract-call? .staking-contract stake u10000000)

;; Check pending rewards
(contract-call? .staking-contract get-pending-rewards 'SP1234...)

;; Claim rewards
(contract-call? .staking-contract claim-rewards)

;; Unstake 5 tokens
(contract-call? .staking-contract unstake u5000000)
```

## Error Codes

- `u100`: Owner-only function called by non-owner
- `u101`: Not authorized
- `u102`: Invalid amount
- `u103`: Insufficient balance
- `u104`: No stake found
- `u105`: Contract is paused

## Development

### Prerequisites

- Clarinet CLI
- Node.js (for testing)
- Stacks blockchain knowledge

### Testing

```bash
clarinet test
```

### Local Development

```bash
clarinet console
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request