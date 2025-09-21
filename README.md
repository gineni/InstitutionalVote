# InstitutionalVote

InstitutionalVote is a transparent decision-making system for academic policy development and implementation built on the Stacks blockchain using Clarity smart contracts.

## Overview

This smart contract enables academic institutions to create and manage a democratic voting system for policy decisions. It provides a transparent, immutable record of proposals, votes, and outcomes while ensuring proper authorization and preventing double-voting.

## Features

- **Proposal Management**: Create and manage academic policy proposals with titles and descriptions
- **Institutional Membership**: Role-based access control for institutional members
- **Secure Voting**: Prevention of double-voting with vote tracking
- **Weighted Voting**: Support for different voting power levels per member
- **Transparent Results**: Public visibility of proposal outcomes and vote counts
- **Time-Limited Voting**: Automatic proposal expiration after 24 hours
- **Proposal Execution**: Admin-controlled execution of passed proposals
- **Complete Audit Trail**: Immutable record of all voting activities

## Technical Specifications

- **Blockchain**: Stacks
- **Smart Contract Language**: Clarity v2
- **Epoch**: 2.5
- **Proposal Duration**: 144 blocks (~24 hours)
- **Vote Types**: Yes, No, Abstain
- **Status Types**: Active, Passed, Rejected, Executed

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity runtime packaged as a command line tool
- Node.js (v16 or higher)
- npm or yarn

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd InstitutionalVote
```

2. Navigate to the contract directory:
```bash
cd InstitutionalVote_contract
```

3. Install dependencies:
```bash
npm install
```

4. Run tests:
```bash
npm test
```

## Usage Examples

### Creating a Proposal

```clarity
;; Only institutional members can create proposals
(contract-call? .InstitutionalVote create-proposal
    "Budget Allocation 2024"
    "Proposal to allocate $100k for new lab equipment and software licenses")
```

### Voting on a Proposal

```clarity
;; Vote YES on proposal #1
(contract-call? .InstitutionalVote vote-on-proposal u1 u1)

;; Vote NO on proposal #1
(contract-call? .InstitutionalVote vote-on-proposal u1 u2)

;; Abstain from proposal #1
(contract-call? .InstitutionalVote vote-on-proposal u1 u3)
```

### Checking Proposal Results

```clarity
;; Get proposal details
(contract-call? .InstitutionalVote get-proposal u1)

;; Get proposal results summary
(contract-call? .InstitutionalVote get-proposal-results u1)
```

## Contract Functions

### Admin Functions

| Function | Description | Access |
|----------|-------------|---------|
| `add-institutional-member` | Add a new member to the institution | Admin only |
| `remove-institutional-member` | Remove a member from the institution | Admin only |
| `set-voting-power` | Set voting power for a member | Admin only |
| `execute-proposal` | Execute a passed proposal | Admin only |

### Member Functions

| Function | Description | Access |
|----------|-------------|---------|
| `create-proposal` | Create a new proposal | Members only |
| `vote-on-proposal` | Vote on an active proposal | Members only |
| `finalize-proposal` | Finalize an expired proposal | Anyone |

### Read-Only Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get-proposal` | Get proposal details | Proposal object or none |
| `get-proposal-count` | Get total number of proposals | uint |
| `get-vote` | Get a specific vote | Vote type or none |
| `is-member` | Check if user is a member | boolean |
| `get-voting-power` | Get member's voting power | uint or none |
| `get-admin` | Get contract admin | principal |
| `can-vote` | Check if user can vote on proposal | boolean |
| `get-proposal-results` | Get proposal results summary | Results object or none |

## Data Structures

### Proposal Object
```clarity
{
    id: uint,
    title: (string-ascii 100),
    description: (string-ascii 500),
    proposer: principal,
    start-block: uint,
    end-block: uint,
    yes-votes: uint,
    no-votes: uint,
    abstain-votes: uint,
    status: uint,
    executed: bool
}
```

### Vote Types
- `VOTE-YES` (u1)
- `VOTE-NO` (u2)
- `VOTE-ABSTAIN` (u3)

### Proposal Status
- `STATUS-ACTIVE` (u1)
- `STATUS-PASSED` (u2)
- `STATUS-REJECTED` (u3)
- `STATUS-EXECUTED` (u4)

## Deployment Guide

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy the contract:
```clarity
::deploy_contracts
```

3. Interact with the contract:
```clarity
;; Add a new member
(contract-call? .InstitutionalVote add-institutional-member 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Create a proposal
(contract-call? .InstitutionalVote create-proposal "Test Proposal" "This is a test")
```

### Testnet Deployment

1. Configure your testnet settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deployments deploy --network testnet
```

### Mainnet Deployment

1. Configure your mainnet settings in `settings/Mainnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deployments deploy --network mainnet
```

## Security Considerations

### Access Control
- Only institutional members can create proposals and vote
- Only the admin can manage membership and execute proposals
- Voting power can be adjusted by admin for weighted voting scenarios

### Vote Integrity
- Double-voting prevention through vote tracking
- Time-limited voting periods to ensure timely decisions
- Immutable vote records on the blockchain

### Proposal Lifecycle
- Proposals must be finalized after expiration before status determination
- Only passed proposals can be executed
- Execution is a separate step from passing to allow for implementation planning

## Error Codes

| Error Code | Description |
|------------|-------------|
| u100 | ERR-NOT-AUTHORIZED: User lacks required permissions |
| u101 | ERR-PROPOSAL-NOT-FOUND: Proposal ID does not exist |
| u102 | ERR-PROPOSAL-EXPIRED: Proposal voting period has ended |
| u103 | ERR-PROPOSAL-NOT-ACTIVE: Proposal is not in active status |
| u104 | ERR-ALREADY-VOTED: User has already voted on this proposal |
| u105 | ERR-INVALID-VOTE-TYPE: Invalid vote type provided |
| u106 | ERR-PROPOSAL-ALREADY-EXECUTED: Proposal has already been executed |

## Testing

The project includes comprehensive test coverage using Vitest and Clarinet SDK:

```bash
# Run all tests
npm test

# Run tests with coverage report
npm run test:report

# Watch mode for development
npm run test:watch
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the ISC License.

## Version

Current version: 1.0.0

## Support

For issues and questions, please use the GitHub issue tracker or contact the development team.