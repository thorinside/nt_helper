# Spec Requirements Document

> Spec: Physical Input/Output Connections Visualization
> Created: 2025-08-30

## Overview

Implement visualization of physical input/output connections in the routing editor widget to show users how their algorithms connect to the Disting NT's physical hardware jacks based on bus assignments. This feature will provide clear visibility into the signal routing between algorithms and physical ports, improving understanding of the complete audio/CV signal flow.

## User Stories

### Hardware-to-Algorithm Connection Visibility

As a user configuring algorithms, I want to see which physical input jacks are connected to my algorithm inputs, so that I can understand how external signals reach my algorithms.

Users need to see the complete signal chain from physical inputs (Audio In 1-2, CV 1-6, Gate 1-2, Trigger 1-2) through to algorithm inputs. The visualization should automatically detect connections based on parameter bus assignments (buses 1-12) and display them as visual connections on the routing canvas.

### Algorithm-to-Hardware Output Visibility  

As a user designing patches, I want to see which physical output jacks my algorithm outputs are routed to, so that I can verify my audio/CV signals reach the correct hardware outputs.

Users need visibility into how their algorithm outputs connect to physical outputs (Audio Out 1-8) based on output bus assignments (buses 13-20). The connections should update dynamically when parameter values change and follow algorithm nodes when they're repositioned.

### Connection Following and Visual Distinction

As a user organizing the routing canvas, I want physical connections to follow algorithm nodes when I move them and be visually distinct from user-created routing connections, so that I can distinguish between hardware routing and custom internal routing.

Physical connections should use different visual styling (colors, line styles) and automatically update their endpoints when nodes are repositioned, while not interfering with interactive connection creation workflows.

## Spec Scope

1. **Physical Input Connection Discovery** - Automatically detect connections from physical inputs (buses 1-12) to algorithm inputs based on parameter values
2. **Physical Output Connection Discovery** - Automatically detect connections from algorithm outputs to physical outputs (buses 13-20) based on parameter values  
3. **Visual Connection Rendering** - Display physical connections with distinct styling that doesn't interfere with user interactions
4. **Dynamic Connection Updates** - Update connections when algorithm nodes move or parameter values change
5. **Architecture Integration** - Use existing AlgorithmRouting abstractions without duplicating routing logic in the cubit

## Out of Scope

- AUX bus connections (buses 21-28) - reserved for future implementation
- User editing of physical connections - these are read-only based on parameter values
- Physical connection validation or conflict detection - this is informational only
- Export/import of physical connection data - derived from existing parameter data

## Expected Deliverable

1. Physical connections are automatically discovered and rendered on the routing canvas based on current parameter values
2. Connections follow algorithm nodes when repositioned and update when parameter values change  
3. Physical connections are visually distinct from user-created connections and don't interfere with interactive workflows