# Mapping Pallet Balances Trait Methods to WebAssembly Implementation

- [Mapping Pallet Balances Trait Methods to WebAssembly Implementation](#mapping-pallet-balances-trait-methods-to-webassembly-implementation)
    - [Overview](#overview)
    - [Calling Convention](#calling-convention)
    - [Trait-to-Wasm Mapping](#trait-to-wasm-mapping)
      - [1. **Inspect Trait** (Read-Only Balance Queries)](#1-inspect-trait-read-only-balance-queries)
        - [1.1 `total_issuance() -> Balance`](#11-total_issuance---balance)
        - [1.2 `minimum_balance() -> Balance`](#12-minimum_balance---balance)
        - [1.3 `balance(who: AccountId) -> Balance`](#13-balancewho-accountid---balance)
        - [1.4 `total_balance(who: AccountId) -> Balance`](#14-total_balancewho-accountid---balance)
        - [1.5 `reducible_balance(who: AccountId, preservation: Preservation, force: Fortitude) -> Balance`](#15-reducible_balancewho-accountid-preservation-preservation-force-fortitude---balance)
      - [2. **Unbalanced Trait** (Mutating Without Imbalance Tracking)](#2-unbalanced-trait-mutating-without-imbalance-tracking)
        - [2.1 `write_balance(who: AccountId, amount: Balance) -> Result<Option<Balance>>`](#21-write_balancewho-accountid-amount-balance---resultoptionbalance)
        - [2.2 `set_total_issuance(amount: Balance)`](#22-set_total_issuanceamount-balance)
        - [2.3 `deactivate(amount: Balance)` and `reactivate(amount: Balance)`](#23-deactivateamount-balance-and-reactivateamount-balance)
        - [2.4 `increase_balance(who: AccountId, amount: Balance, precision: Precision) -> Result<Balance>`](#24-increase_balancewho-accountid-amount-balance-precision-precision---resultbalance)
        - [2.5 `decrease_balance(who: AccountId, amount: Balance, precision: Precision, preservation: Preservation, fortitude: Fortitude) -> Result<Balance>`](#25-decrease_balancewho-accountid-amount-balance-precision-precision-preservation-preservation-fortitude-fortitude---resultbalance)
      - [3. **Mutate Trait** (Balanced Transfer Operations)](#3-mutate-trait-balanced-transfer-operations)
        - [3.1 `transfer(source: AccountId, dest: AccountId, amount: Balance, preservation: Preservation) -> Result<Balance>`](#31-transfersource-accountid-dest-accountid-amount-balance-preservation-preservation---resultbalance)
        - [3.2 `burn_from(who: AccountId, amount: Balance, preservation: Preservation, precision: Precision, fortitude: Fortitude) -> Result<Balance>`](#32-burn_fromwho-accountid-amount-balance-preservation-preservation-precision-precision-fortitude-fortitude---resultbalance)
      - [4. **InspectHold Trait** (Reserved Balance Queries)](#4-inspecthold-trait-reserved-balance-queries)
        - [4.1 `balance_on_hold(who: AccountId) -> Balance`](#41-balance_on_holdwho-accountid---balance)
        - [4.2 `total_balance_on_hold() -> Balance`](#42-total_balance_on_hold---balance)
      - [5. **MutateHold Trait** (Reserved Balance Mutations)](#5-mutatehold-trait-reserved-balance-mutations)
        - [5.1 `hold(who: AccountId, amount: Balance) -> Result<()>`](#51-holdwho-accountid-amount-balance---result)
        - [5.2 `release(who: AccountId, amount: Balance, precision: Precision) -> Result<Balance>`](#52-releasewho-accountid-amount-balance-precision-precision---resultbalance)
      - [6. **InspectFreeze Trait** (Lock Inspection)](#6-inspectfreeze-trait-lock-inspection)
        - [6.1 `balance_frozen(who: AccountId) -> Balance`](#61-balance_frozenwho-accountid---balance)
        - [6.2 `can_deposit(who: AccountId, amount: Balance, provenance: Provenance) -> DepositConsequence`](#62-can_depositwho-accountid-amount-balance-provenance-provenance---depositconsequence)
        - [6.3 `can_withdraw(who: AccountId, amount: Balance) -> WithdrawConsequence`](#63-can_withdrawwho-accountid-amount-balance---withdrawconsequence)
      - [7. **MutateFreeze Trait** (Lock Management)](#7-mutatefreeze-trait-lock-management)
        - [7.1 `set_freeze(who: AccountId, id: [u8; 8], amount: Balance) -> Result<()>`](#71-set_freezewho-accountid-id-u8-8-amount-balance---result)
        - [7.2 `thaw(who: AccountId, id: [u8; 8]) -> Result<()>`](#72-thawwho-accountid-id-u8-8---result)
      - [8. **Balanced Trait** (Imbalance-Tracking Operations)](#8-balanced-trait-imbalance-tracking-operations)
        - [8.1 `deposit(who: AccountId, amount: Balance, precision: Precision) -> Result<CreditImbalance>`](#81-depositwho-accountid-amount-balance-precision-precision---resultcreditimbalance)
        - [8.2 `issue(amount: Balance) -> CreditImbalance`](#82-issueamount-balance---creditimbalance)
        - [8.3 `rescind(amount: Balance) -> DebtImbalance`](#83-rescindamount-balance---debtimbalance)
        - [8.4 `resolve(who: AccountId, credit: CreditImbalance) -> Result<()>`](#84-resolvewho-accountid-credit-creditimbalance---result)
        - [8.5 `settle(who: AccountId, debt: DebtImbalance, preservation: Preservation) -> Result<CreditImbalance>`](#85-settlewho-accountid-debt-debtimbalance-preservation-preservation---resultcreditimbalance)
    - [Summary Table: Trait Method to Wasm Handler Mapping](#summary-table-trait-method-to-wasm-handler-mapping)
    - [Parameter Decoding Patterns](#parameter-decoding-patterns)
      - [**Pattern 1: Fixed-Size Parameters (AccountId, u128)**](#pattern-1-fixed-size-parameters-accountid-u128)
      - [**Pattern 2: Enum Parameters (Preservation, Precision, etc.)**](#pattern-2-enum-parameters-preservation-precision-etc)
      - [**Pattern 3: Option Parameters**](#pattern-3-option-parameters)
    - [Event Emission Protocol](#event-emission-protocol)
      - [**Event Encoding Format**](#event-encoding-format)
      - [**Example: Transfer Event**](#example-transfer-event)


### Overview

The original `pallet_balances` implements nine traits from the `frame_support::traits::tokens::fungible` family, providing a comprehensive interface for balance operations. The `balances_contract` WebAssembly module reimplements this functionality as message handlers, accessible through the contract's message dispatch mechanism. This appendix establishes a systematic correspondence between the trait methods and their Wasm implementations.

### Calling Convention

All contract interactions follow the **Ink! ABI calling convention**:

1. **Message Invocation**: External callers invoke contract methods by providing:
   - **Selector** (4 bytes): BLAKE2-256 hash of method signature, truncated to first 4 bytes
   - **Encoded Parameters**: SCALE-encoded method arguments

2. **Input Decoding** (via `seal_input`):
   ```wasm
   seal_input(buffer_ptr: i32, buffer_len_ptr: i32)
   ```
   Writes SCALE-encoded input to contract memory. The contract's dispatcher (function 73) then:
   - Extracts the 4-byte selector
   - Matches selector to handler via cascading `br_table` dispatch
   - Decodes parameters from remaining bytes

3. **Execution**: Handler function executes business logic, reading/writing storage via:
   ```wasm
   seal_get_storage(key_ptr, key_len, out_ptr, out_len_ptr) → status_code
   seal_set_storage(key_ptr, key_len, val_ptr, val_len) → old_val_size
   ```

4. **Result Encoding** (via `seal_return`):
   ```wasm
   seal_return(flags: i32, data_ptr: i32, data_len: i32) → never_returns
   ```
   Returns SCALE-encoded `Result<T, Error>` to caller, terminating execution.

5. **Event Emission** (via `seal_deposit_event`):
   ```wasm
   seal_deposit_event(topics_ptr, topics_len, data_ptr, data_len)
   ```
   Emits indexed events for balance changes (Transfer, Endowed, etc.)

---

### Trait-to-Wasm Mapping

#### 1. **Inspect Trait** (Read-Only Balance Queries)

The `Inspect` trait provides non-mutating methods to query account balances.

##### 1.1 `total_issuance() -> Balance`
- **Selector**: `0x6AEA3206` 
- **Handler**: Function 73, handler index 1 (label `@67`)
- **Wasm Flow**:
  ```wasm
  ;; Load from storage at key "total_issuance"
  local.get 0
  i32.const 66840      ;; Storage key prefix
  call 52              ;; read_account_from_storage (helper)
  
  ;; Return u128 value
  local.get 11         ;; total_issuance (high 64)
  local.get 10         ;; total_issuance (low 64)
  call 60              ;; return_u128_result
  ```
- **Storage Key**: `BLAKE2(0x66840 || b"total_issuance")`
- **Returns**: `Result<u128, Error>` SCALE-encoded

##### 1.2 `minimum_balance() -> Balance`
- **Selector**: `0xA7EAE324`
- **Handler**: Function 73, handler index 3
- **Wasm Flow**:
  ```wasm
  ;; Read existential_deposit from contract state
  local.get 0
  i64.load offset=32   ;; ED low 64 bits
  local.get 0
  i64.load offset=40   ;; ED high 64 bits
  call 60              ;; Return as Result<u128>
  ```
- **Note**: Returns value from in-memory contract state (not storage lookup)

##### 1.3 `balance(who: AccountId) -> Balance`
- **Selector**: `0x0F5C5E92`
- **Handler**: Function 73, handler index 9
- **Wasm Flow**:
  ```wasm
  ;; Decode AccountId parameter (32 bytes at offset 4)
  local.get 0
  i32.const 160
  i32.add
  local.get 1          ;; Decoded AccountId
  call 52              ;; read_account_from_storage (func 52)
  
  ;; Extract account.free field (first u128 in AccountData)
  local.get 0
  i64.load offset=304  ;; free (low 64)
  local.get 0
  i64.load offset=312  ;; free (high 64)
  call 60              ;; return_u128_result
  ```
- **Storage Key**: `BLAKE2(0x66840 || account_id)`
- **Returns**: `Result<u128, Error>` with account's free balance

##### 1.4 `total_balance(who: AccountId) -> Balance`
- **Selector**: `0x7A2095E3`
- **Handler**: Function 73, handler index 10
- **Wasm Flow**:
  ```wasm
  ;; Read account data
  local.get 0
  i32.const 304
  i32.add
  local.get 1
  call 52
  
  ;; Calculate free + reserved (saturating add)
  local.get 0
  i64.load offset=304  ;; free (low)
  local.get 0
  i64.load offset=320  ;; reserved (low)
  i64.add              ;; Saturating addition (overflow → u128::MAX)
  ;; ... (high 64 bits similarly)
  
  call 60              ;; Return result
  ```
- **Arithmetic**: Uses saturating addition (overflow clamped to `u128::MAX`)

##### 1.5 `reducible_balance(who: AccountId, preservation: Preservation, force: Fortitude) -> Balance`
- **Selector**: `0x2E9A5C32`
- **Handler**: Function 73, handler index 25 (complex path)
- **Wasm Flow**:
  ```wasm
  ;; Calculate: free - max(frozen, existential_deposit) if Preserve mode
  local.get 0
  i32.const 304
  i32.add
  local.get 12         ;; amount (low)
  local.get 14         ;; amount (high)
  local.get 1          ;; AccountId ptr
  local.get 5          ;; preservation flag
  call 53              ;; calculate_reducible_balance (func 53)
  ```
- **Preservation Modes**:
  - `Expendable` (0): Returns `free - frozen`
  - `Preserve` (1): Returns `max(0, free - frozen - ED)`
  - `Protect` (2): Same as `Preserve`
- **Fortitude** (currently unused in calculation, reserved for future use)

---

#### 2. **Unbalanced Trait** (Mutating Without Imbalance Tracking)

The `Unbalanced` trait provides methods that directly mutate balances without creating imbalance objects.

##### 2.1 `write_balance(who: AccountId, amount: Balance) -> Result<Option<Balance>>`
- **Selector**: `0xDC9A5E14`
- **Handler**: Function 73, handler index 24
- **Wasm Flow**:
  ```wasm
  ;; Authorization check (only owner)
  local.get 0
  i32.const 288
  i32.add
  call 45              ;; get_caller_account_id
  local.get 1          ;; Expected owner
  call 51              ;; account_id_ne (compare)
  
  ;; If not owner, return Err(NotAllowed)
  if
    i32.const 6
    i32.const 1
    call 57            ;; encode_and_return_result (func 57)
  end
  
  ;; Load current account
  local.get 0
  i32.const 304
  i32.add
  local.get 2
  call 52
  
  ;; Check if new balance < ED but > 0 (dust case)
  ;; ... (complex dust handling logic)
  
  ;; Update account.free, adjust total_issuance
  ;; ... (arithmetic with overflow checks)
  
  ;; Write back to storage
  local.get 2
  local.get 0
  i32.const 304
  i32.add
  call 28              ;; write_account_to_storage (func 28)
  ```
- **Dust Handling**: If `0 < amount < ED`, the account is reaped and `Some(dust_amount)` is returned
- **Issuance Update**: Adjusts both `total_issuance` and `active_issuance` to reflect the delta

##### 2.2 `set_total_issuance(amount: Balance)`
- **Selector**: `0xF9A48F8E`
- **Handler**: Function 73, handler index 19
- **Wasm Flow**:
  ```wasm
  ;; Authorization check (owner only)
  ;; ... (same pattern as write_balance)
  
  ;; Load old total_issuance
  local.get 0
  i64.load offset=16   ;; old_total (low)
  local.get 0
  i64.load offset=24   ;; old_total (high)
  
  ;; Set new value
  local.get 0
  local.get 12         ;; new_total (low)
  i64.store offset=16
  local.get 0
  local.get 14         ;; new_total (high)
  i64.store offset=24
  
  ;; Adjust active_issuance proportionally
  ;; If old_total = 0, set active_issuance = new_total
  ;; Otherwise, active_issuance = min(active_issuance, new_total)
  ```
- **Proportional Adjustment**: Maintains `active_issuance ≤ total_issuance` invariant

##### 2.3 `deactivate(amount: Balance)` and `reactivate(amount: Balance)`
- **Selectors**: 
  - `deactivate`: `0x11D5A05F`
  - `reactivate`: `0xA7B9E95D`
- **Handlers**: Function 73, handler indices 20-21
- **Wasm Flow** (deactivate):
  ```wasm
  ;; Authorization check
  ;; ...
  
  ;; Saturating subtraction
  local.get 0
  i64.load offset=24   ;; active_issuance (low)
  local.get 12         ;; amount (low)
  i64.sub              ;; Compute difference
  local.tee 13
  
  ;; Check for underflow
  local.get 0
  i64.load offset=24
  local.get 13
  i64.lt_u             ;; If underflow, clamp to 0
  select
  
  ;; Store result
  local.get 0
  local.get 13
  i64.store offset=24
  ```
- **Reactivate**: Similar logic but with saturating add clamped to `total_issuance`

##### 2.4 `increase_balance(who: AccountId, amount: Balance, precision: Precision) -> Result<Balance>`
- **Selector**: `0xB2E13B27`
- **Handler**: Function 73, handler index 16
- **Wasm Flow**:
  ```wasm
  ;; Load account
  local.get 0
  i32.const 304
  i32.add
  local.get 1
  call 52
  
  ;; Check if new account (free = 0)
  local.get 0
  i64.load offset=304
  i64.eqz
  if
    ;; Check amount ≥ ED
    local.get 12       ;; amount (low)
    local.get 0
    i64.load offset=32 ;; ED (low)
    i64.lt_u
    if
      ;; Handle based on precision
      local.get 5      ;; precision discriminant
      i32.eqz          ;; Exact?
      if
        ;; Return Err(ExistentialDeposit)
        i32.const 1
        i32.const 1
        call 57
      else
        ;; Return Ok(0) for BestEffort
        i64.const 0
        i64.const 0
        call 60
      end
    end
  end
  
  ;; Checked addition: account.free + amount
  ;; ... (overflow check with precision handling)
  
  ;; Update total_issuance
  ;; ... (checked add)
  
  ;; Write account to storage
  call 28
  
  ;; Emit Endowed event
  local.get 0
  i32.const 544
  i32.add
  call 42              ;; emit_transfer_event variant
  ```
- **Precision Handling**:
  - `Exact`: Fails on overflow/ED violation
  - `BestEffort`: Returns partial amount on overflow, 0 on ED violation

##### 2.5 `decrease_balance(who: AccountId, amount: Balance, precision: Precision, preservation: Preservation, fortitude: Fortitude) -> Result<Balance>`
- **Selector**: `0xA194B221`
- **Handler**: Function 73, handler index 26
- **Wasm Flow**: 
  - Delegates to `burn_from` (same function, different selector)
  - See section 2.7 below for detailed flow

---

#### 3. **Mutate Trait** (Balanced Transfer Operations)

The `Mutate` trait provides methods that maintain balance conservation (transfers, not minting).

##### 3.1 `transfer(source: AccountId, dest: AccountId, amount: Balance, preservation: Preservation) -> Result<Balance>`
- **Selector**: `0xCE8F142D`
- **Handler**: Function 73, handler index 5
- **Wasm Flow**:
  ```wasm
  ;; Get caller (enforced as source in this handler)
  local.get 0
  i32.const 288
  i32.add
  call 45              ;; get_caller_account_id
  
  ;; Verify caller = source (authorization)
  ;; ...
  
  ;; Delegate to transfer_with_checks
  local.get 0
  i32.const 544
  i32.add
  local.get source     ;; from (caller)
  local.get dest       ;; to
  local.get amount_low
  local.get amount_high
  local.get preservation
  i32.const 1          ;; fortitude = Force (for this selector)
  call 71              ;; transfer_with_checks (func 71)
  
  ;; Check result
  local.get 0
  i32.load8_u offset=544
  if
    ;; Transfer failed, return error
    i32.const 1
    local.get 0
    i32.const 544
    i32.add
    call 61            ;; return_result_error
  end
  
  ;; Success: encode and return Ok(())
  call 58              ;; return_ok_unit
  ```
- **Preservation Enforcement** (in function 71):
  ```wasm
  ;; Calculate reducible balance
  local.get 0
  i64.load offset=16   ;; from.free (low)
  local.get 0
  i64.load offset=48   ;; from.frozen (low)
  i64.sub              ;; usable = free - frozen
  
  ;; Check preservation mode
  local.get 5          ;; preservation discriminant
  i32.const 255
  i32.and
  if                   ;; If Preserve or Protect
    ;; Check new_balance ≥ ED
    local.get new_balance_low
    local.get 0
    i64.load offset=32 ;; ED (low)
    i64.lt_u
    if
      ;; Return Err(Expendability)
      local.get 0
      i32.const 3
      i32.store8 offset=1
      br exit_path
    end
  end
  ```

##### 3.2 `burn_from(who: AccountId, amount: Balance, preservation: Preservation, precision: Precision, fortitude: Fortitude) -> Result<Balance>`
- **Selector**: `0x9EA394B1`
- **Handler**: Function 73, handler index 27
- **Wasm Flow**:
  ```wasm
  ;; Load account
  local.get 0
  i32.const 304
  i32.add
  local.get who
  call 52
  
  ;; Calculate reducible balance
  local.get 0
  i32.const 544
  i32.add
  local.get amount_low
  local.get amount_high
  local.get who
  local.get preservation
  call 53              ;; calculate_reducible_balance (func 53)
  
  ;; Get reducible amount
  local.get 0
  i64.load offset=552  ;; reducible (high)
  local.get 0
  i64.load offset=544  ;; reducible (low)
  
  ;; Determine actual burn amount based on precision
  block
    local.get precision
    i32.eqz            ;; Exact?
    if
      ;; Check reducible ≥ amount
      local.get reducible_low
      local.get amount_low
      i64.lt_u
      if
        ;; Determine error type (InsufficientBalance or Expendability)
        ;; ... (check if due to locks vs preservation)
        call 57        ;; return error
      end
      
      ;; Use exact amount
      local.get amount_low
      local.get amount_high
      br 1
    else
      ;; BestEffort: use min(amount, reducible)
      local.get amount_low
      local.get reducible_low
      local.get amount_low
      local.get reducible_low
      i64.gt_u
      select             ;; actual_burn = min(amount, reducible)
    end
  end
  local.set actual_burn_low
  
  ;; Subtract from account.free
  local.get 0
  i64.load offset=304
  local.get actual_burn_low
  i64.sub
  i64.store offset=304
  
  ;; Update total_issuance (saturating sub)
  ;; ...
  
  ;; Handle dust if 0 < new_balance < ED
  local.get new_balance_low
  local.get 0
  i64.load offset=32   ;; ED
  i64.lt_u
  if
    ;; Call dust handler (func 76, check_deposit_feasibility)
    ;; Transfers to dust_trap or burns
  end
  
  ;; Emit Burned event
  local.get 0
  i32.const 544
  i32.add
  call 42              ;; emit_transfer_event (modified for burn)
  
  ;; Return actual burned amount
  local.get actual_burn_low
  local.get actual_burn_high
  call 60
  ```
- **Dust Handling** (in function 76):
  ```wasm
  ;; Check if dust_trap is set
  local.get 0
  i32.load8_u offset=84  ;; dust_trap.is_some()
  i32.const 1
  i32.eq
  if
    ;; Transfer dust to trap account
    local.get 0
    i32.const 85
    i32.add            ;; dust_trap AccountId
    local.get dust_amount
    call 70            ;; deposit_into_account
  else
    ;; Burn dust, emit DustLost event
    ;; total_issuance -= dust_amount
  end
  ```

---

#### 4. **InspectHold Trait** (Reserved Balance Queries)

The `InspectHold` trait deals with reserved (held) balances that cannot be spent.

##### 4.1 `balance_on_hold(who: AccountId) -> Balance`
- **Selector**: `0xA1B8F1E6`
- **Handler**: Function 73, handler index 11
- **Wasm Flow**:
  ```wasm
  ;; Read account data
  local.get 0
  i32.const 304
  i32.add
  local.get 1
  call 52
  
  ;; Return account.reserved field (u128 at offset +16)
  local.get 0
  i64.load offset=320  ;; reserved (low)
  local.get 0
  i64.load offset=328  ;; reserved (high)
  call 60
  ```
- **Storage Layout**: `AccountData` structure in storage:
  ```
  Offset  Field        Size
  +0      free         16 bytes (u128)
  +16     reserved     16 bytes (u128)
  +32     frozen       16 bytes (u128)
  ```

##### 4.2 `total_balance_on_hold() -> Balance`
- **Selector**: `0x33F3948D`
- **Handler**: Function 73, handler index 21
- **Wasm Flow**:
  ```wasm
  ;; Iterate over all accounts (storage enumeration not directly supported)
  ;; This is a simplified implementation that sums reserved balances
  ;; In practice, contract maintains this as a separate storage value
  
  local.get 0
  i64.load offset=40   ;; Cached total_reserved (low)
  local.get 0
  i64.load offset=48   ;; Cached total_reserved (high)
  call 60
  ```

---

#### 5. **MutateHold Trait** (Reserved Balance Mutations)

The `MutateHold` trait provides methods to reserve and unreserve balances.

##### 5.1 `hold(who: AccountId, amount: Balance) -> Result<()>`
- **Selector**: `0xC1D8E627` (aliased as `reserve`)
- **Handler**: Function 73, handler index 22
- **Wasm Flow**:
  ```wasm
  ;; Load account
  local.get 0
  i32.const 304
  i32.add
  local.get who
  call 52
  
  ;; Check usable balance (free - frozen)
  local.get 0
  i64.load offset=304  ;; free (low)
  local.get 0
  i64.load offset=336  ;; frozen (low)
  i64.sub
  local.tee usable_low
  
  local.get amount_low
  i64.lt_u             ;; usable < amount?
  if
    i32.const 3        ;; Err(LiquidityRestrictions)
    call 57
  end
  
  ;; Subtract from free
  local.get 0
  local.get 0
  i64.load offset=304
  local.get amount_low
  i64.sub
  i64.store offset=304
  
  ;; Add to reserved (checked)
  local.get 0
  i64.load offset=320  ;; reserved (low)
  local.get amount_low
  i64.add
  local.tee new_reserved_low
  
  ;; Check overflow
  local.get 0
  i64.load offset=320
  local.get new_reserved_low
  i64.gt_u             ;; Overflow?
  if
    i32.const 4        ;; Err(Overflow)
    call 57
  end
  
  ;; Store new reserved
  local.get 0
  local.get new_reserved_low
  i64.store offset=320
  
  ;; Write to storage
  call 28
  
  ;; Emit Reserved event
  ;; ... (event encoding via seal_deposit_event)
  ```

##### 5.2 `release(who: AccountId, amount: Balance, precision: Precision) -> Result<Balance>`
- **Selector**: `0xF5A8B128` (aliased as `unreserve`)
- **Handler**: Function 73, handler index 23
- **Wasm Flow**:
  ```wasm
  ;; Calculate actual release amount
  local.get amount_low
  local.get 0
  i64.load offset=320  ;; reserved (low)
  local.tee reserved_low
  
  ;; actual = min(amount, reserved)
  local.get amount_low
  local.get reserved_low
  i64.gt_u
  select
  local.set actual_low
  
  ;; Subtract from reserved
  local.get 0
  local.get reserved_low
  local.get actual_low
  i64.sub
  i64.store offset=320
  
  ;; Add to free (checked)
  local.get 0
  i64.load offset=304
  local.get actual_low
  i64.add
  ;; ... (overflow check)
  i64.store offset=304
  
  ;; Emit Unreserved event
  ;; ...
  
  ;; Return actual released amount
  local.get actual_low
  local.get actual_high
  call 60
  ```
- **Precision**: `BestEffort` mode automatically applied (releases min(amount, reserved))

---

#### 6. **InspectFreeze Trait** (Lock Inspection)

The `InspectFreeze` trait allows querying balance locks (frozen amounts).

##### 6.1 `balance_frozen(who: AccountId) -> Balance`
- **Selector**: `0x2F1A9DDC`
- **Handler**: Function 73, handler index 28
- **Wasm Flow**:
  ```wasm
  ;; Read account data
  local.get 0
  i32.const 304
  i32.add
  local.get who
  call 52
  
  ;; Return account.frozen field (u128 at offset +32)
  local.get 0
  i64.load offset=336  ;; frozen (low)
  local.get 0
  i64.load offset=344  ;; frozen (high)
  call 60
  ```

##### 6.2 `can_deposit(who: AccountId, amount: Balance, provenance: Provenance) -> DepositConsequence`
- **Selector**: `0xB3F881A9`
- **Handler**: Function 73, handler index 17
- **Wasm Flow**:
  ```wasm
  ;; Load account
  local.get 0
  i32.const 304
  i32.add
  local.get who
  call 52
  
  ;; Check for overflow
  local.get 0
  i64.load offset=304  ;; free (low)
  local.get amount_low
  i64.add
  local.tee new_free_low
  
  ;; Detect carry
  local.get 0
  i64.load offset=304
  local.get new_free_low
  i64.gt_u             ;; Overflow?
  if
    i32.const 4        ;; DepositConsequence::Overflow
    call 60            ;; Return enum value
  end
  
  ;; Check total_issuance overflow
  local.get 0
  i64.load offset=16
  local.get amount_low
  i64.add
  ;; ... (similar overflow check)
  if
    i32.const 4
    call 60
  end
  
  ;; Check ED for new accounts
  local.get 0
  i64.load offset=304
  i64.eqz              ;; Is new account?
  if
    local.get new_free_low
    local.get 0
    i64.load offset=32 ;; ED (low)
    i64.lt_u
    if
      i32.const 2      ;; DepositConsequence::BelowMinimum
      call 60
    end
  end
  
  ;; Success
  i32.const 7          ;; DepositConsequence::Success
  call 60
  ```
- **DepositConsequence Enum**:
  - `0`: `Success`
  - `1`: (unused in current implementation)
  - `2`: `BelowMinimum`
  - `3`: `CannotCreate`
  - `4`: `Overflow`
  - `5`: (unused)
  - `6`: (unused)
  - `7`: Success (alternative encoding)

##### 6.3 `can_withdraw(who: AccountId, amount: Balance) -> WithdrawConsequence`
- **Selector**: `0xF7A8F3E1`
- **Handler**: Function 73, handler index 18
- **Wasm Flow**:
  ```wasm
  ;; Calculate usable balance
  local.get 0
  i64.load offset=304  ;; free (low)
  local.get 0
  i64.load offset=336  ;; frozen (low)
  i64.sub
  local.tee usable_low
  
  ;; Check if usable < amount
  local.get amount_low
  i64.gt_u
  if
    i32.const 2        ;; WithdrawConsequence::BalanceLow
    call 60
  end
  
  ;; Calculate new balance
  local.get 0
  i64.load offset=304
  local.get amount_low
  i64.sub
  local.tee new_balance_low
  
  ;; Check if would create dust (0 < new_balance < ED)
  local.get new_balance_low
  i64.const 0
  i64.gt_u
  if
    local.get new_balance_low
    local.get 0
    i64.load offset=32 ;; ED (low)
    i64.lt_u
    if
      ;; Return ReducedToZero(new_balance)
      i32.const 3      ;; Discriminant
      ;; ... (encode new_balance in error payload)
      call 57
    end
  end
  
  ;; Success
  i32.const 7
  call 60
  ```
- **WithdrawConsequence Enum**:
  - `0`: `Success`
  - `1`: (unused)
  - `2`: `BalanceLow`
  - `3`: `ReducedToZero(Balance)` (includes 16-byte payload)
  - `4`: `WouldDie`
  - `5`: (unused)
  - `6`: (unused)
  - `7`: Success (alternative)

---

#### 7. **MutateFreeze Trait** (Lock Management)

The `MutateFreeze` trait provides methods to set and remove balance locks.

##### 7.1 `set_freeze(who: AccountId, id: [u8; 8], amount: Balance) -> Result<()>`
- **Selector**: `0xCD0F5A06` (aliased as `set_lock`)
- **Handler**: Function 73, handler index 32
- **Wasm Flow**:
  ```wasm
  ;; Read existing locks from storage
  local.get 0
  i32.const 464
  i32.add
  local.get who
  call 20              ;; encode_locks_to_storage (func 20, also does read)
  
  ;; Extract locks vector metadata
  local.get 0
  i32.load offset=464  ;; locks.capacity
  local.get 0
  i32.load offset=468  ;; locks.ptr
  local.get 0
  i32.load offset=472  ;; locks.len
  
  ;; Search for existing lock with same ID
  local.get locks_ptr
  local.set current_lock
  i32.const 0
  local.set index
  
  loop                 ;; Search loop
    local.get index
    local.get locks_len
    i32.eq
    if                 ;; Not found
      ;; Check max_locks limit
      local.get locks_len
      local.get 0
      i32.load offset=240  ;; max_locks
      i32.ge_u
      if
        i32.const 5    ;; Err(TooManyLocks)
        call 57
      end
      
      ;; Append new lock
      local.get 0
      i32.const 484
      i32.add
      local.get lock_id  ;; 8-byte ID
      i64.store
      local.get 0
      i32.const 492
      i32.add
      local.get amount_low
      i64.store
      local.get 0
      i32.const 500
      i32.add
      local.get amount_high
      i64.store
      
      local.get 0
      i32.const 464
      i32.add          ;; vec metadata
      local.get 0
      i32.const 484
      i32.add          ;; new lock struct
      i32.const 67536  ;; error context
      call 25          ;; vec_push_balance_lock (func 25)
      
      br exit_search
    end
    
    ;; Check if current lock ID matches
    local.get current_lock
    i32.const 16
    i32.add
    i64.load align=1   ;; lock.id (8 bytes at offset +16)
    local.get lock_id
    i64.eq
    if
      ;; Update existing lock amount
      local.get current_lock
      local.get amount_low
      i64.store
      local.get current_lock
      i32.const 8
      i32.add
      local.get amount_high
      i64.store
      br exit_search
    end
    
    ;; Next lock
    local.get current_lock
    i32.const 32       ;; sizeof(BalanceLock)
    i32.add
    local.set current_lock
    local.get index
    i32.const 1
    i32.add
    local.set index
    br 0
  end
  
  exit_search:
  ;; Recalculate max lock (frozen)
  local.get 0
  i32.const 464
  i32.add
  call compute_max_lock  ;; Iterates over locks vector
  
  ;; Update account.frozen
  local.get 0
  local.get max_lock_low
  i64.store offset=336
  
  ;; Write locks to storage (key: BLAKE2(0x66836 || account_id))
  local.get who
  local.get 0
  i32.load offset=468  ;; locks.ptr
  local.get 0
  i32.load offset=472  ;; locks.len
  call 30              ;; write_locks_to_storage (func 30)
  
  ;; Write updated account
  local.get who
  local.get 0
  i32.const 304
  i32.add
  call 28
  
  ;; Emit Locked event if frozen increased
  ;; ...
  ```
- **Lock Storage Format**:
  ```
  Key: BLAKE2(0x66836 || AccountId)
  Value: SCALE(Vec<BalanceLock>)
    = Compact<u32>(len) || [BalanceLock; len]
  
  BalanceLock = {
    id: [u8; 8],        // +0, bytes 0-7
    _padding: [u8; 8],  // +8, bytes 8-15 (alignment)
    amount: u128        // +16, bytes 16-31
  }
  ```
- **Max Lock Calculation** (in handler):
  ```wasm
  ;; Assume locks_ptr points to first lock
  local.get locks_ptr
  i64.load             ;; First lock amount (low)
  local.set max_low
  local.get locks_ptr
  i32.const 8
  i32.add
  i64.load
  local.set max_high
  
  ;; Iterate over remaining locks
  local.get locks_len
  i32.const 1
  i32.sub
  local.set remaining
  local.get locks_ptr
  i32.const 32
  i32.add
  local.set current
  
  loop
    local.get remaining
    i32.eqz
    if
      br exit_max
    end
    
    ;; Load current lock amount
    local.get current
    i64.load
    local.tee current_low
    
    ;; Compare with current max
    local.get max_low
    local.get current_low
    i64.lt_u           ;; max < current?
    if
      ;; Update max
      local.get current_low
      local.set max_low
      local.get current
      i32.const 8
      i32.add
      i64.load
      local.set max_high
    end
    
    ;; Next lock
    local.get current
    i32.const 32
    i32.add
    local.set current
    local.get remaining
    i32.const 1
    i32.sub
    local.set remaining
    br 0
  end
  
  exit_max:
  ;; max_low, max_high now contain maximum lock amount
  ```

##### 7.2 `thaw(who: AccountId, id: [u8; 8]) -> Result<()>`
- **Selector**: `0x11A08D5C` (aliased as `remove_lock`)
- **Handler**: Function 73, handler index 33
- **Wasm Flow**:
  ```wasm
  ;; Read locks vector
  local.get 0
  i32.const 464
  i32.add
  local.get who
  call 20              ;; Read locks
  
  ;; Filter out lock with matching ID
  ;; (Uses Vec::retain pattern)
  local.get locks_ptr
  local.set src
  local.get locks_ptr
  local.set dst
  local.get locks_len
  local.set remaining
  i32.const 0
  local.set new_len
  
  loop                 ;; Retain loop
    local.get remaining
    i32.eqz
    if
      br exit_retain
    end
    
    ;; Check if current lock should be kept
    local.get src
    i32.const 16
    i32.add
    i64.load align=1   ;; lock.id
    local.get target_id
    i64.ne             ;; Keep if ID doesn't match
    if
      ;; Copy to destination (may be same as source)
      local.get dst
      local.get src
      i32.const 32     ;; sizeof(BalanceLock)
      memory.copy
      
      local.get dst
      i32.const 32
      i32.add
      local.set dst    ;; Advance destination
      
      local.get new_len
      i32.const 1
      i32.add
      local.set new_len
    end
    
    ;; Next source lock
    local.get src
    i32.const 32
    i32.add
    local.set src
    local.get remaining
    i32.const 1
    i32.sub
    local.set remaining
    br 0
  end
  
  exit_retain:
  ;; Update vector length
  local.get 0
  local.get new_len
  i32.store offset=472
  
  ;; Recalculate frozen (max of remaining locks)
  ;; ... (same logic as set_freeze)
  
  ;; Write updated locks (or remove if empty)
  local.get new_len
  i32.eqz
  if
    ;; Clear storage entry
    ;; Calculate key: BLAKE2(0x66836 || account_id)
    local.get 0
    i32.const 592
    i32.add
    local.get who
    call 21            ;; encode_mapping_key
    
    local.get 0
    i32.load offset=600  ;; key_ptr
    local.get 0
    i32.load offset=604  ;; key_len
    call 4             ;; seal_clear_storage
  else
    ;; Write updated vector
    call 30
  end
  
  ;; Emit Unlocked event if frozen decreased
  ;; ...
  ```

---

#### 8. **Balanced Trait** (Imbalance-Tracking Operations)

The `Balanced` trait provides methods that return imbalance objects (credit/debt) for later settlement.

##### 8.1 `deposit(who: AccountId, amount: Balance, precision: Precision) -> Result<CreditImbalance>`
- **Selector**: `0x05C81D55`
- **Handler**: Function 73, handler index 6
- **Wasm Flow**:
  ```wasm
  ;; Same logic as increase_balance (handler 16)
  ;; ... (check ED, overflow, update account)
  
  ;; Create CreditImbalance return value
  ;; CreditImbalance is a struct { amount: u128 }
  local.get actual_deposited_low
  local.get actual_deposited_high
  
  ;; Encode as Result<CreditImbalance, Error>
  local.get 0
  i32.const 288
  i32.add
  i32.const 0          ;; Ok discriminant
  call 64
  
  ;; Encode CreditImbalance (just encode the u128)
  local.get actual_deposited_low
  local.get actual_deposited_high
  local.get 0
  i32.const 288
  i32.add
  call 33              ;; encode_u128
  
  ;; Return encoded result
  ;; ...
  call 65              ;; seal_return_wrapper
  ```
- **Note**: The imbalance object is immediately resolved (returned as a value, not stored). The Wasm implementation doesn't maintain a separate imbalance registry.

##### 8.2 `issue(amount: Balance) -> CreditImbalance`
- **Selector**: `0x8B3BEC3B` (constructor-like, actually part of `pair` method)
- **Handler**: Function 73, handler index 0 (default case)
- **Wasm Flow**:
  ```wasm
  ;; Check for overflow in total_issuance
  local.get 0
  i64.load offset=16   ;; total_issuance (low)
  local.get amount_low
  i64.add
  ;; ... (overflow check)
  
  ;; Create (CreditImbalance, DebtImbalance) pair
  ;; In Wasm, this returns as a tuple encoded in Result
  
  ;; Encode Result::Ok discriminant
  i32.const 0
  call 64
  
  ;; Encode tuple (CreditImbalance { amount }, DebtImbalance { amount })
  local.get amount_low
  local.get amount_high
  call 33              ;; Encode first imbalance
  
  local.get amount_low
  local.get amount_high
  call 33              ;; Encode second imbalance (same value)
  ```

##### 8.3 `rescind(amount: Balance) -> DebtImbalance`
- **Selector**: `0x55F85D0F`
- **Handler**: Function 73, handler index 29
- **Wasm Flow**: Similar to `issue`, but returns only `DebtImbalance`

##### 8.4 `resolve(who: AccountId, credit: CreditImbalance) -> Result<()>`
- **Selector**: `0x06A7D814`
- **Handler**: Function 73, handler index 7
- **Wasm Flow**:
  ```wasm
  ;; Extract credit.amount from encoded parameter
  ;; ... (SCALE decode u128)
  
  ;; Delegate to mint_into
  local.get who
  local.get credit_amount_low
  local.get credit_amount_high
  
  ;; Same logic as increase_balance (handler 16)
  ;; ... (check ED, update account, adjust issuance)
  
  ;; Return Ok(())
  call 58              ;; return_ok_unit
  ```
- **Note**: `mint` (selector `0x461AF21A`, handler 4) performs authorization check (`caller == owner`), while `resolve` may allow public resolution depending on contract configuration.

##### 8.5 `settle(who: AccountId, debt: DebtImbalance, preservation: Preservation) -> Result<CreditImbalance>`
- **Selector**: `0xC8CB2133`
- **Handler**: Function 73, handler index 8
- **Wasm Flow**:
  ```wasm
  ;; Extract debt.amount
  ;; ...
  
  ;; Try to burn the debt amount
  local.get who
  local.get debt_amount_low
  local.get debt_amount_high
  local.get preservation
  i32.const 1          ;; Precision::BestEffort (always)
  i32.const 0          ;; Fortitude::Polite
  call 71              ;; Delegates to burn_from logic
  
  ;; Calculate remaining debt (unburned)
  local.get debt_amount_low
  local.get burned_low
  i64.sub
  local.tee remaining_low
  
  ;; Return CreditImbalance { amount: remaining }
  ;; Encode Result::Ok discriminant
  i32.const 0
  call 64
  
  ;; Encode CreditImbalance struct
  local.get remaining_low
  local.get remaining_high
  call 33
  
  call 65
  ```
- **Semantics**: Attempts to burn `debt.amount` from `who`. If insufficient balance (due to preservation or locks), returns the unburnable portion as a `CreditImbalance`.

---

### Summary Table: Trait Method to Wasm Handler Mapping

| Trait | Method | Selector | Handler Index | Key Functions |
|-------|--------|----------|---------------|---------------|
| **Inspect** | `total_issuance()` | `0x6AEA3206` | 1 | 52 (read storage) |
| | `minimum_balance()` | `0xA7EAE324` | 3 | (direct read) |
| | `balance(who)` | `0x0F5C5E92` | 9 | 52 |
| | `total_balance(who)` | `0x7A2095E3` | 10 | 52, saturating add |
| | `reducible_balance(...)` | `0x2E9A5C32` | 25 | 53 (calc reducible) |
| **Unbalanced** | `write_balance(...)` | `0xDC9A5E14` | 24 | 52, 28, 76 (dust) |
| | `set_total_issuance(...)` | `0xF9A48F8E` | 19 | (direct write) |
| | `increase_balance(...)` | `0xB2E13B27` | 16 | 52, 28, 42 (event) |
| | `decrease_balance(...)` | `0xA194B221` | 26 | 53, 71, 28 |
| **Mutate** | `transfer(...)` | `0xCE8F142D` | 5 | 45, 71, 28, 42 |
| | `burn_from(...)` | `0x9EA394B1` | 27 | 53, 71, 76 |
| **InspectHold** | `balance_on_hold(who)` | `0xA1B8F1E6` | 11 | 52 (read reserved) |
| **MutateHold** | `hold(...)` (reserve) | `0xC1D8E627` | 22 | 52, 28, 42 |
| | `release(...)` (unreserve) | `0xF5A8B128` | 23 | 52, 28, 42 |
| **InspectFreeze** | `balance_frozen(who)` | `0x2F1A9DDC` | 28 | 52 (read frozen) |
| | `can_deposit(...)` | `0xB3F881A9` | 17 | 52, overflow checks |
| | `can_withdraw(...)` | `0xF7A8F3E1` | 18 | 52, 53 |
| **MutateFreeze** | `set_freeze(...)` (set_lock) | `0xCD0F5A06` | 32 | 20, 25, 30 |
| | `thaw(...)` (remove_lock) | `0x11A08D5C` | 33 | 20, 30, vector ops |
| **Balanced** | `deposit(...)` | `0x05C81D55` | 6 | 52, 28, imbalance encoding |
| | `issue(...)` | `0x8B3BEC3B` | 0 | (pair creation) |
| | `resolve(...)` | `0x06A7D814` | 7 | (delegate to mint) |
| | `settle(...)` | `0xC8CB2133` | 8 | 71 (burn), imbalance calc |

---

### Parameter Decoding Patterns

#### **Pattern 1: Fixed-Size Parameters (AccountId, u128)**
```wasm
;; Example: transfer(to: AccountId, amount: Balance)
;; Input layout: [selector: 4] [to: 32] [amount: 16]

;; Decode AccountId (bytes 4-35)
local.get input_ptr
i32.const 4
i32.add
local.tee account_ptr  ;; Points to AccountId

;; Copy to stack (unaligned loads for reconstruction)
local.get account_ptr
i64.load align=1       ;; Bytes 0-7
local.get account_ptr
i32.const 8
i32.add
i64.load align=1       ;; Bytes 8-15
;; ... (repeat for bytes 16-31)

;; Decode u128 (bytes 36-51)
local.get input_ptr
i32.const 36
i32.add
i64.load align=1       ;; Low 64 bits
local.get input_ptr
i32.const 44
i32.add
i64.load align=1       ;; High 64 bits
```

#### **Pattern 2: Enum Parameters (Preservation, Precision, etc.)**
```wasm
;; Example: burn_from(..., precision: Precision)
;; Input layout: [...] [precision: 1 byte discriminant]

;; Read discriminant
local.get input_ptr
i32.const 52           ;; Offset of enum
i32.add
i32.load8_u            ;; Load single byte

;; Validate range (Precision has 2 variants: Exact=0, BestEffort=1)
local.tee precision
i32.const 2
i32.ge_u
if
  ;; Invalid discriminant, panic
  local.get precision
  call 69              ;; panic_invalid_enum (func 69)
end
```

#### **Pattern 3: Option<T> Parameters**
```wasm
;; Example: new_with_dust_trap(dust_trap: Option<AccountId>)
;; Input layout: [discriminant: 1] [AccountId: 32 if Some, 0 if None]

;; Decode discriminant
local.get input_ptr
i32.load8_u
local.tee discriminant

;; Match on discriminant
block
  block
    local.get discriminant
    br_table 0 1 2     ;; 0: None, 1: Some, 2+: invalid
  end
  
  ;; Case None
  i32.const 0          ;; Store None marker
  br exit_decode
end

;; Case Some: decode AccountId (next 32 bytes)
local.get input_ptr
i32.const 1
i32.add
;; ... (decode AccountId)
i32.const 1            ;; Store Some marker

exit_decode:
```

---

### Event Emission Protocol

Events are emitted via `seal_deposit_event` with the following structure:

#### **Event Encoding Format**
```
Topics: [topic₀, topic₁, ..., topicₙ]  (each topic is 32 bytes)
Data:   SCALE(EventStruct)
```

#### **Example: Transfer Event**
```wasm
;; Function 42: emit_transfer_event
;; Event: Transfer { from: Option<AccountId>, to: Option<AccountId>, value: Balance }

;; Initialize encoder for topics
local.get 0
i64.const 16384
i64.store offset=40    ;; Buffer capacity
local.get 0
i32.const 69258        ;; Buffer ptr
i32.store offset=36

;; Encode topic count (2 for Transfer: from and to)
local.get encoder
i32.const 2
call 39                ;; encode_vec_length (Compact<u32>)

;; Encode event signature topic
local.get encoder
i32.const 67784        ;; "Transfer" string constant
call 34                ;; encode_event_topic (hashes to 32-byte topic)

;; Build from/to topic hashes
local.get encoder
local.get from_account_ptr
call 34                ;; Hash from AccountId

local.get encoder
local.get to_account_ptr
call 34                ;; Hash to AccountId

;; Extract topics buffer
local.get 0
i32.load offset=44     ;; Topics length
local.get 0
i32.load offset=48     ;; Topics ptr

;; Encode event data (from, to, value)
local.get 0
i32.const 16
i32.add
local.get encoder
call 63                ;; encode_option_account_id (from)

local.get 0
i32.const 49
i32.add
local.get encoder
call 63                ;; encode_option_account_id (to)

local.get value_low
local.get value_high
local.get encoder
call 33                ;; encode_u128 (value)

;; Extract data buffer
local.get 0
i32.load offset=56     ;; Data length
local.get 0
i32.load offset=60     ;; Data ptr

;; Emit event
call 2                 ;; seal_deposit_event(topics_ptr, topics_len, data_ptr, data_len)
```

**Topic Hash Derivation**:
```
topic = BLAKE2-256(SCALE(AccountId))
```

For `Transfer` event:
- Topic 0: `BLAKE2("Transfer")` (event signature)
- Topic 1: `BLAKE2(SCALE(from))` (sender account)
- Topic 2: `BLAKE2(SCALE(to))` (recipient account)

**Data Payload** (SCALE-encoded):
```
Transfer {
  from: Option<AccountId>,  // 1 byte discriminant + 32 bytes if Some
  to: Option<AccountId>,    // 1 byte discriminant + 32 bytes if Some
  value: Balance            // 16 bytes (u128 little-endian)
}
```
