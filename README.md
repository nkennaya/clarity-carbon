# ClarityCarbon - Tokenized Carbon Credits Smart Contract

## Overview
ClarityCarbon is a smart contract designed for the transparent and secure management of carbon credits. It enables organizations to mint, trade, and retire tokenized carbon credits with built-in verification mechanisms to ensure authenticity and traceability.

## Features
- **Project Registration**: Organizations can register carbon offset projects with verifiable details.
- **Project Verification**: Designated verifiers approve and validate carbon offset projects.
- **Minting Carbon Credits**: Verified projects can generate carbon credits.
- **Trading Credits**: Users can transfer carbon credits to others.
- **Retiring Credits**: Users can permanently retire credits to offset their carbon footprint.
- **Transparent Tracking**: On-chain records ensure accountability and traceability.

## Smart Contract Functions

### Public Functions
1. **register-verifier(verifier-address, name)**
   - Allows the contract owner to register a verifier.
   - Only the contract owner can execute this function.
   
2. **register-project(project-id, name, description, location, methodology, verifier)**
   - Registers a new carbon offset project with relevant details.
   - Only the contract owner can execute this function.
   
3. **verify-project(project-id)**
   - Approves a registered project.
   - Can only be executed by the assigned verifier.

4. **mint-credits(project-id, amount)**
   - Mints new carbon credits for a verified project.
   - Only the verifier of the project can execute this function.

5. **transfer-credits(project-id, amount, recipient)**
   - Transfers carbon credits from one user to another.
   - Ensures the sender has enough balance before transferring.

6. **retire-credits(project-id, amount, retirement-note)**
   - Permanently removes carbon credits from circulation.
   - Records retirement details for transparency.

### Read-Only Functions
1. **get-project(project-id)**
   - Retrieves project details.

2. **get-balance(owner, project-id)**
   - Gets the carbon credit balance of a user.

3. **get-retirement(owner, project-id, retirement-id)**
   - Retrieves details of a retired carbon credit transaction.

4. **get-project-retired-total(project-id)**
   - Gets the total retired credits for a project.

5. **get-verifier(address)**
   - Retrieves verifier details.

## Data Structures
- **Projects**: Stores carbon offset project details.
- **Credit Balances**: Tracks the credit balance of users.
- **Retired Credits**: Stores records of retired credits.
- **Project Retired Totals**: Tracks total retired credits per project.
- **Verifiers**: Manages registered project verifiers.

## Error Handling
The contract defines the following error codes:
- `u100`: Only the contract owner can perform this action.
- `u101`: Unauthorized action.
- `u102`: Invalid project ID.
- `u103`: Invalid credit amount.
- `u104`: Insufficient credit balance.
- `u105`: Credit has already been retired.

## Deployment & Usage
1. Deploy the contract to a blockchain supporting smart contracts.
2. The contract owner registers verifiers.
3. Organizations register projects for verification.
4. Verified projects can mint carbon credits.
5. Users can trade and retire credits to offset carbon footprints.

## License
This smart contract is open-source and available under the MIT License.

