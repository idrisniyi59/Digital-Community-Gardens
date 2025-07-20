# Digital Community Gardens

A decentralized system for managing community gardens through smart contracts on the Stacks blockchain.

## Overview

The Digital Community Gardens system consists of five interconnected smart contracts that facilitate community-driven gardening initiatives:

1. **Plot Allocation Contract** - Manages assignment of garden spaces to community members
2. **Resource Sharing Contract** - Handles tool and equipment lending between gardeners
3. **Harvest Distribution Contract** - Coordinates produce sharing among participants
4. **Maintenance Responsibility Contract** - Assigns and tracks upkeep tasks
5. **Educational Workshop Contract** - Organizes gardening classes and events

## Features

### Plot Allocation
- Register garden plots with size and location details
- Assign plots to community members
- Track plot status and ownership
- Handle plot transfers between members

### Resource Sharing
- Register tools and equipment for community use
- Manage lending periods and availability
- Track resource condition and maintenance needs
- Handle reservations and returns

### Harvest Distribution
- Record harvest yields from individual plots
- Coordinate sharing of produce among community members
- Track distribution history and contributions
- Manage surplus allocation to food banks or community kitchens

### Maintenance Responsibilities
- Create maintenance tasks for garden upkeep
- Assign responsibilities to community members
- Track task completion and quality
- Reward active participants with community points

### Educational Workshops
- Schedule gardening classes and educational events
- Manage instructor assignments and participant registration
- Track attendance and feedback
- Maintain educational resource library

## Contract Architecture

Each contract operates independently while maintaining data consistency through standardized data structures and validation rules.

### Data Types

- **Principal**: Stacks wallet addresses for user identification
- **Uint**: Numeric values for IDs, quantities, and timestamps
- **String-ascii**: Text data for names, descriptions, and metadata
- **Bool**: Status flags and boolean properties

### Error Handling

All contracts implement comprehensive error handling with descriptive error codes:
- Input validation errors (ERR-INVALID-INPUT)
- Permission errors (ERR-NOT-AUTHORIZED)
- Resource availability errors (ERR-NOT-AVAILABLE)
- State consistency errors (ERR-INVALID-STATE)

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Stacks wallet for deployment

### Installation

\`\`\`bash
git clone <repository-url>
cd digital-community-gardens
npm install
\`\`\`

### Testing

\`\`\`bash
npm test
\`\`\`

### Deployment

\`\`\`bash
clarinet deploy
\`\`\`

## Usage Examples

### Registering a Plot
\`\`\`clarity
(contract-call? .plot-allocation register-plot "Plot A1" u100 "North section near water source")
\`\`\`

### Lending a Tool
\`\`\`clarity
(contract-call? .resource-sharing lend-resource u1 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u7)
\`\`\`

### Recording a Harvest
\`\`\`clarity
(contract-call? .harvest-distribution record-harvest u1 u50 "Tomatoes")
\`\`\`

## Contributing

Community contributions are welcome! Please follow the established patterns for error handling, data validation, and documentation.

## License

MIT License - see LICENSE file for details
