## ADDED Requirements

### Requirement: Unsigned gather immediate

The dispatcher SHALL zero-extend each five-bit `vrgather.vi` index to the scalar operand width for both masked and unmasked instructions.

#### Scenario: Exhaustive decoding
- **WHEN** a legal `vrgather.vi` with any immediate from 0 through 31 is dispatched
- **THEN** the backend scalar operand equals that unsigned immediate

#### Scenario: Broadcast across the sign boundary
- **WHEN** indices 15, 16 and 31 address initialized e8 source elements within VLMAX
- **THEN** all active destination elements equal the addressed source element and execution completes

#### Scenario: Source beyond active length
- **WHEN** VL is shortened to 5 and index 31 remains below VLMAX
- **THEN** the active destination elements receive source element 31

#### Scenario: Masked broadcast
- **WHEN** a masked immediate gather uses index 16 or 31 with mask-undisturbed policy
- **THEN** enabled elements receive the source value and masked-off elements retain their old values

### Requirement: Preserve signed immediates

The dispatcher SHALL retain sign extension for signed OPIVI arithmetic operands.

#### Scenario: Signed arithmetic controls
- **WHEN** `vadd.vi` is dispatched with any immediate encoding from 0 through 31
- **THEN** the scalar operand is the sign-extended five-bit value
