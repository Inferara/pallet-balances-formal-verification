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
   Writes SCALE-encoded input to contract memory. The contract's dispatcher (function 63) then:
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
- **Handler**: Function 63, handler index 1
- **Wasm Flow**:
  ```wasm
  ;; Reads contract's internal state offset 0-15 (total_issuance)
  local.get 0           ;; Contract state ptr
  i64.load              ;; total_issuance (low 64)
  local.get 0
  i32.const 8
  i32.add
  i64.load              ;; total_issuance (high 64)
  call 50               ;; return_u128_result
  ```
- **Storage**: Read from contract state memory (not storage lookup)
- **Returns**: `Result<u128, Error>` SCALE-encoded

##### 1.2 `minimum_balance() -> Balance`
- **Selector**: `0xA7EAE324`
- **Handler**: Function 63, handler index 3
- **Wasm Flow**:
  ```wasm
  ;; Read existential_deposit from contract state (offset 32-47)
  local.get 0
  i64.load offset=32    ;; ED (low 64)
  local.get 0
  i32.const 40
  i32.add
  i64.load              ;; ED (high 64)
  call 50               ;; return_u128_result
  ```
- **Note**: Returns value from in-memory contract state (offset 32)

##### 1.3 `balance(who: AccountId) -> Balance`
- **Selector**: `0x0F5C5E92`
- **Handler**: Function 63, handler index 9
- **Wasm Flow**:
  ```wasm
  ;; Decode AccountId from input buffer
  local.get 0
  i32.const 216
  i32.add
  local.get 1           ;; Reader state ptr
  call 35               ;; decode_account_id
  
  ;; Check decode success
  local.get 0
  i32.load8_u offset=216
  br_if error_path
  
  ;; Read account from storage
  local.get 0
  i32.const 216
  i32.add               ;; Result destination
  local.get 0
  i32.const 217
  i32.add               ;; Decoded AccountId ptr
  call 46               ;; read_account_from_storage (func 46)
  
  ;; Extract free field (first u128 in AccountData at offset 0)
  local.get 0
  i64.load offset=216   ;; free (low 64)
  local.get 0
  i32.const 224
  i32.add
  i64.load              ;; free (high 64)
  call 50               ;; return_u128_result
  ```
- **Storage Key**: `BLAKE2(0x0001000F || account_id)` (prefix 65540)
- **Returns**: `Result<u128, Error>` with account's free balance

##### 1.4 `total_balance(who: AccountId) -> Balance`
- **Selector**: `0x7A2095E3`
- **Handler**: Function 63, handler index 10
- **Wasm Flow**:
  ```wasm
  ;; Read account data
  local.get 0
  i32.const 216
  i32.add
  local.get 1           ;; Decoded AccountId
  call 46               ;; read_account_from_storage
  
  ;; Load free and reserved balances
  local.get 0
  i64.load offset=216   ;; free (low)
  local.get 0
  i64.load offset=232   ;; reserved (low)
  
  ;; Saturating add (low 64 bits)
  i64.add
  local.tee 13          ;; sum_low
  
  ;; High 64 bits with carry
  local.get 0
  i32.const 224
  i32.add
  i64.load              ;; free (high)
  local.get 0
  i32.const 240
  i32.add
  i64.load              ;; reserved (high)
  i64.add
  
  ;; Add carry from low addition
  local.get 0
  i64.load offset=216   ;; original free (low)
  local.get 13          ;; sum_low
  i64.gt_u              ;; detect carry
  i64.extend_i32_u
  i64.add
  
  ;; Return result
  local.get 13
  call 50
  ```
- **Arithmetic**: Uses saturating addition with overflow detection

##### 1.5 `reducible_balance(who: AccountId, preservation: Preservation, force: Fortitude) -> Balance`
- **Selector**: `0x2E9A5C32`
- **Handler**: Function 63, handler index 25
- **Wasm Flow**:
  ```wasm
  ;; Decode parameters
  local.get 0
  i32.const 208
  i32.add
  local.get 1           ;; Reader ptr
  call 35               ;; decode_account_id
  
  ;; Decode preservation enum
  local.get 1
  call 58               ;; decode_preservation
  
  ;; Calculate reducible balance
  local.get 0
  i32.const 216
  i32.add               ;; Result ptr
  local.get 12          ;; amount_low (decoded)
  local.get 14          ;; amount_high (decoded)
  local.get 0
  i32.const 209
  i32.add               ;; AccountId ptr
  local.get 5           ;; preservation discriminant
  call 47               ;; calculate_reducible_balance (func 47)
  
  ;; Return result
  local.get 0
  i64.load offset=216
  local.get 0
  i32.const 224
  i32.add
  i64.load
  call 50
  ```
- **Preservation Modes** (in function 47):
  - `Expendable` (0): Returns `free - frozen`
  - `Preserve` (1): Returns `max(0, free - frozen - ED)`
  - `Protect` (2): Same as `Preserve`
- **Fortitude**: Currently ignored in calculation

---

#### 2. **Unbalanced Trait** (Mutating Without Imbalance Tracking)

The `Unbalanced` trait provides methods that directly mutate balances without creating imbalance objects.

##### 2.1 `write_balance(who: AccountId, amount: Balance) -> Result<Option<Balance>>`
- **Selector**: `0xDC9A5E14`
- **Handler**: Function 63, handler index 24
- **Wasm Flow**:
  ```wasm
  ;; Authorization check (owner only)
  local.get 0
  i32.const 208
  i32.add
  call 42               ;; get_caller_account_id
  
  local.get 0
  i32.const 208
  i32.add
  local.get 1           ;; Expected owner from state
  call 44               ;; account_id_ne
  
  ;; If not owner, return Err(NotAllowed)
  if
    i32.const 1
    i32.const 6
    call 49             ;; encode_and_return_result
  end
  
  ;; Read current account
  local.get 0
  i32.const 216
  i32.add
  local.get 2           ;; AccountId ptr
  call 46               ;; read_account_from_storage
  
  ;; Calculate delta and check for dust
  ;; If 0 < new_balance < ED, call dust handler
  ;; ... (complex arithmetic)
  
  ;; Update account.free
  local.get 0
  local.get new_free_low
  i64.store offset=216
  
  ;; Adjust total_issuance
  ;; ... (checked add/sub)
  
  ;; Write back to storage
  local.get 2
  local.get 0
  i32.const 216
  i32.add
  call 28               ;; write_account_to_storage
  ```
- **Dust Handling**: Delegates to function 66 (`check_deposit_feasibility`)
- **Issuance Update**: Adjusts both `total_issuance` and `active_issuance`

##### 2.2 `set_total_issuance(amount: Balance)`
- **Selector**: `0xF9A48F8E`
- **Handler**: Function 63, handler index 19
- **Wasm Flow**:
  ```wasm
  ;; Authorization check (owner only)
  ;; ... (same pattern as write_balance)
  
  ;; Load old total_issuance from state
  local.get 0
  i64.load              ;; old_total (low 64)
  local.get 0
  i32.const 8
  i32.add
  i64.load              ;; old_total (high 64)
  
  ;; Set new value
  local.get 0
  local.get 12          ;; new_total (low, from decode)
  i64.store
  local.get 0
  local.get 14          ;; new_total (high)
  i64.store offset=8
  
  ;; Adjust active_issuance proportionally
  ;; If old_total = 0, set active = new_total
  ;; Otherwise, active = min(active, new_total)
  ```
- **Proportional Adjustment**: Maintains `active_issuance ≤ total_issuance` invariant

##### 2.3 `deactivate(amount: Balance)` and `reactivate(amount: Balance)`
- **Selectors**: 
  - `deactivate`: `0x11D5A05F`
  - `reactivate`: `0xA7B9E95D`
- **Handlers**: Function 63, handler indices 20-21
- **Wasm Flow** (deactivate):
  ```wasm
  ;; Authorization check
  ;; ...
  
  ;; Load active_issuance from state (offset 16-31)
  local.get 0
  i64.load offset=16    ;; active (low)
  local.get 12          ;; amount (low)
  i64.sub
  local.tee 13
  
  ;; Saturating sub (clamp to 0 on underflow)
  local.get 0
  i64.load offset=16
  local.get 13
  i64.lt_u              ;; Underflow?
  if
    i64.const 0
    local.set 13
  end
  
  ;; Store result
  local.get 0
  local.get 13
  i64.store offset=16
  ```
- **Reactivate**: Similar logic but saturating add clamped to `total_issuance`

##### 2.4 `increase_balance(who: AccountId, amount: Balance, precision: Precision) -> Result<Balance>`
- **Selector**: `0xB2E13B27`
- **Handler**: Function 63, handler index 16
- **Wasm Flow**:
  ```wasm
  ;; Decode AccountId and amount
  ;; ... (standard decoding)
  
  ;; Load account
  local.get 0
  i32.const 216
  i32.add
  local.get 1           ;; AccountId ptr
  call 46
  
  ;; Check if new account (free = 0)
  local.get 0
  i64.load offset=216   ;; free (low)
  local.get 0
  i32.const 224
  i32.add
  i64.load              ;; free (high)
  i64.or
  i64.eqz
  if
    ;; Check amount ≥ ED
    local.get 12        ;; amount (low)
    local.get 0
    i64.load offset=32  ;; ED (low)
    i64.lt_u
    if
      ;; Handle based on precision
      local.get 5       ;; precision discriminant
      i32.eqz           ;; Exact?
      if
        ;; Return Err(BelowMinimum)
        i32.const 1
        i32.const 2
        call 49
      else
        ;; Return Ok(0) for BestEffort
        i64.const 0
        i64.const 0
        call 50
      end
    end
  end
  
  ;; Checked addition: account.free + amount
  local.get 0
  i64.load offset=216
  local.get 12
  i64.add
  ;; ... (overflow check with precision handling)
  i64.store offset=216
  
  ;; Update total_issuance
  ;; ... (checked add to state offset 0-15)
  
  ;; Write account to storage
  local.get 1
  local.get 0
  i32.const 216
  i32.add
  call 28
  
  ;; Emit Endowed event
  local.get 0
  i32.const 456
  i32.add
  call 38               ;; emit_transfer_event variant
  ```
- **Precision Handling**:
  - `Exact`: Fails on overflow/ED violation
  - `BestEffort`: Returns partial amount on overflow, 0 on ED violation

##### 2.5 `decrease_balance(who: AccountId, amount: Balance, precision: Precision, preservation: Preservation, fortitude: Fortitude) -> Result<Balance>`
- **Selector**: `0xA194B221`
- **Handler**: Function 63, handler index 26
- **Wasm Flow**: 
  - Delegates to burn_from logic (function 61)
  - See section 3.2 below for detailed flow

---

#### 3. **Mutate Trait** (Balanced Transfer Operations)

The `Mutate` trait provides methods that maintain balance conservation (transfers, not minting).

##### 3.1 `transfer(source: AccountId, dest: AccountId, amount: Balance, preservation: Preservation) -> Result<Balance>`
- **Selector**: `0xCE8F142D`
- **Handler**: Function 63, handler index 5
- **Wasm Flow**:
  ```wasm
  ;; Get caller (enforced as source)
  local.get 0
  i32.const 456
  i32.add
  call 42               ;; get_caller_account_id
  
  ;; Verify caller = decoded source
  local.get 0
  i32.const 456
  i32.add
  local.get 1           ;; Decoded source AccountId
  call 44               ;; account_id_ne
  
  ;; If mismatch, return Err(NotAllowed)
  if
    i32.const 1
    i32.const 6
    call 49
  end
  
  ;; Delegate to transfer_with_checks
  local.get 0
  i32.const 456
  i32.add               ;; Result ptr
  local.get 0
  i32.const 88
  i32.add               ;; From AccountId (caller)
  local.get 1           ;; To AccountId (decoded)
  local.get amount_low
  local.get amount_high
  local.get preservation
  i32.const 1           ;; fortitude = Force
  call 61               ;; transfer_with_checks (func 61)
  
  ;; Check result
  local.get 0
  i32.load8_u offset=456
  if
    ;; Transfer failed
    i32.const 1
    local.get 0
    i32.const 456
    i32.add
    call 52             ;; return_result_error
  end
  
  ;; Success
  call 51               ;; return_ok_unit
  ```
- **Preservation Enforcement** (in function 61):
  ```wasm
  ;; Calculate reducible balance
  local.get 0
  i32.const 48
  i32.add
  local.get 1
  i64.load offset=32    ;; ED (low)
  local.get 1
  i32.const 40
  i32.add
  i64.load              ;; ED (high)
  local.get 2           ;; from AccountId
  local.get 5           ;; preservation
  call 47               ;; calculate_reducible_balance
  
  ;; Check if amount ≤ reducible
  local.get 3           ;; amount (low)
  local.get 0
  i64.load offset=48    ;; reducible (low)
  i64.le_u
  local.get 4           ;; amount (high)
  local.get 0
  i32.const 56
  i32.add
  i64.load              ;; reducible (high)
  i64.le_u
  local.get 4
  local.get 9
  i64.eq
  select
  i32.eqz
  if
    ;; Return Err(InsufficientBalance) or Err(Expendability)
    local.get 0
    i32.const 0         ;; or 3 based on reason
    i32.store8 offset=1
  end
  ```

##### 3.2 `burn_from(who: AccountId, amount: Balance, preservation: Preservation, precision: Precision, fortitude: Fortitude) -> Result<Balance>`
- **Selector**: `0x9EA394B1`
- **Handler**: Function 63, handler index 27
- **Wasm Flow**:
  ```wasm
  ;; Load account
  local.get 0
  i32.const 216
  i32.add
  local.get who
  call 46               ;; read_account_from_storage
  
  ;; Calculate reducible balance
  local.get 0
  i32.const 456
  i32.add               ;; Result ptr
  local.get amount_low
  local.get amount_high
  local.get who
  local.get preservation
  call 47               ;; calculate_reducible_balance (func 47)
  
  ;; Get reducible amount
  local.get 0
  i64.load offset=464   ;; reducible (high)
  local.get 0
  i64.load offset=456   ;; reducible (low)
  
  ;; Determine actual burn based on precision
  block
    local.get precision
    i32.eqz             ;; Exact?
    if
      ;; Check reducible ≥ amount
      local.get reducible_low
      local.get amount_low
      i64.lt_u
      if
        ;; Return appropriate error
        ;; ... (check if InsufficientBalance or Expendability)
        call 49
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
      select
      ;; ... (high 64 similarly)
    end
  end
  local.set actual_burn_low
  
  ;; Subtract from account.free
  local.get 0
  i64.load offset=216
  local.get actual_burn_low
  i64.sub
  i64.store offset=216
  
  ;; Update total_issuance (saturating sub)
  ;; ...
  
  ;; Handle dust if 0 < new_balance < ED
  local.get new_balance_low
  local.get 0
  i64.load offset=32    ;; ED
  i64.lt_u
  if
    ;; Call dust handler
    local.get 0
    i32.const 88
    i32.add             ;; Contract state
    local.get 0
    i32.const 216
    i32.add             ;; Account data
    local.get dust_ptr
    call 66             ;; check_deposit_feasibility
    drop
  end
  
  ;; Emit Burned event
  ;; ... (via seal_deposit_event)
  
  ;; Return actual burned amount
  local.get actual_burn_low
  local.get actual_burn_high
  call 50
  ```
- **Dust Handling** (in function 66):
  - If `dust_trap` is set (state offset 84 = 1), transfers dust to trap account
  - Otherwise burns dust and emits `DustLost` event

---

#### 4. **InspectHold Trait** (Reserved Balance Queries)

The `InspectHold` trait deals with reserved (held) balances that cannot be spent.

##### 4.1 `balance_on_hold(who: AccountId) -> Balance`
- **Selector**: `0xA1B8F1E6`
- **Handler**: Function 63, handler index 11
- **Wasm Flow**:
  ```wasm
  ;; Read account data
  local.get 0
  i32.const 216
  i32.add
  local.get 1           ;; AccountId ptr
  call 46
  
  ;; Return account.reserved field (offset +16 in AccountData)
  local.get 0
  i64.load offset=232   ;; reserved (low 64)
  local.get 0
  i32.const 240
  i32.add
  i64.load              ;; reserved (high 64)
  call 50
  ```
- **AccountData Layout** (48 bytes total):
  ```
  Offset  Field        Size
  +0      free         16 bytes (u128)
  +16     reserved     16 bytes (u128)
  +32     frozen       16 bytes (u128)
  ```

##### 4.2 `total_balance_on_hold() -> Balance`
- **Selector**: `0x33F3948D`
- **Handler**: Function 63, handler index 21
- **Wasm Flow**:
  ```wasm
  ;; Read cached total_reserved from state (offset 16-31)
  local.get 0
  i64.load offset=16    ;; total_reserved (low)
  local.get 0
  i32.const 24
  i32.add
  i64.load              ;; total_reserved (high)
  call 50
  ```
- **Note**: Returns pre-computed value from contract state

---

#### 5. **MutateHold Trait** (Reserved Balance Mutations)

The `MutateHold` trait provides methods to reserve and unreserve balances.

##### 5.1 `hold(who: AccountId, amount: Balance) -> Result<()>`
- **Selector**: `0xC1D8E627` (aliased as `reserve`)
- **Handler**: Function 63, handler index 22
- **Wasm Flow**:
  ```wasm
  ;; Load account
  local.get 0
  i32.const 216
  i32.add
  local.get who
  call 46
  
  ;; Calculate usable balance (free - frozen)
  local.get 0
  i64.load offset=216   ;; free (low)
  local.get 0
  i64.load offset=248   ;; frozen (low)
  i64.sub
  local.tee usable_low
  
  ;; Check if usable < amount
  local.get amount_low
  i64.lt_u
  if
    i32.const 1
    i32.const 3         ;; Err(LiquidityRestrictions)
    call 49
  end
  
  ;; Subtract from free
  local.get 0
  local.get 0
  i64.load offset=216
  local.get amount_low
  i64.sub
  i64.store offset=216
  
  ;; Add to reserved (checked)
  local.get 0
  i64.load offset=232   ;; reserved (low)
  local.get amount_low
  i64.add
  local.tee new_reserved_low
  
  ;; Overflow check
  local.get 0
  i64.load offset=232
  local.get new_reserved_low
  i64.gt_u
  if
    i32.const 1
    i32.const 4         ;; Err(Overflow)
    call 49
  end
  
  ;; Store new reserved
  local.get 0
  local.get new_reserved_low
  i64.store offset=232
  
  ;; Write to storage
  local.get who
  local.get 0
  i32.const 216
  i32.add
  call 28
  
  ;; Emit Reserved event
  ;; ... (via function 38)
  ```

##### 5.2 `release(who: AccountId, amount: Balance, precision: Precision) -> Result<Balance>`
- **Selector**: `0xF5A8B128` (aliased as `unreserve`)
- **Handler**: Function 63, handler index 23
- **Wasm Flow**:
  ```wasm
  ;; Load account
  local.get 0
  i32.const 216
  i32.add
  local.get who
  call 46
  
  ;; Calculate actual release amount
  local.get amount_low
  local.get 0
  i64.load offset=232   ;; reserved (low)
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
  i64.store offset=232
  
  ;; Add to free (checked)
  local.get 0
  i64.load offset=216
  local.get actual_low
  i64.add
  ;; ... (overflow check)
  i64.store offset=216
  
  ;; Write to storage
  call 28
  
  ;; Emit Unreserved event
  ;; ...
  
  ;; Return actual released amount
  local.get actual_low
  local.get actual_high
  call 50
  ```

---

#### 6. **InspectFreeze Trait** (Lock Inspection)

The `InspectFreeze` trait allows querying balance locks (frozen amounts).

##### 6.1 `balance_frozen(who: AccountId) -> Balance`
- **Selector**: `0x2F1A9DDC`
- **Handler**: Function 63, handler index 28
- **Wasm Flow**:
  ```wasm
  ;; Read account data
  local.get 0
  i32.const 216
  i32.add
  local.get who
  call 46
  
  ;; Return account.frozen field (offset +32 in AccountData)
  local.get 0
  i64.load offset=248   ;; frozen (low 64)
  local.get 0
  i32.const 256
  i32.add
  i64.load              ;; frozen (high 64)
  call 50
  ```

##### 6.2 `can_deposit(who: AccountId, amount: Balance, provenance: Provenance) -> DepositConsequence`
- **Selector**: `0xB3F881A9`
- **Handler**: Function 63, handler index 17
- **Wasm Flow**:
  ```wasm
  ;; Load account
  local.get 0
  i32.const 216
  i32.add
  local.get who
  call 46
  
  ;; Check for overflow in free balance
  local.get 0
  i64.load offset=216   ;; free (low)
  local.get amount_low
  i64.add
  local.tee new_free_low
  
  ;; Detect carry
  local.get 0
  i64.load offset=216
  local.get new_free_low
  i64.gt_u              ;; Overflow?
  if
    i32.const 4         ;; DepositConsequence::Overflow
    call 57             ;; encoder_write_byte
    call 51             ;; return
  end
  
  ;; Check total_issuance overflow
  local.get 0
  i64.load              ;; total_issuance (low)
  local.get amount_low
  i64.add
  ;; ... (similar overflow check)
  if
    i32.const 4
    ;; ... (encode and return)
  end
  
  ;; Check ED for new accounts (free = 0 initially)
  local.get 0
  i64.load offset=216
  local.get 0
  i32.const 224
  i32.add
  i64.load
  i64.or
  i64.eqz               ;; Is new account?
  if
    local.get new_free_low
    local.get 0
    i64.load offset=32  ;; ED (low)
    i64.lt_u
    if
      i32.const 2       ;; DepositConsequence::BelowMinimum
      ;; ... (encode and return)
    end
  end
  
  ;; Success
  i32.const 7           ;; DepositConsequence::Success
  ;; ... (encode and return)
  ```
- **DepositConsequence Enum**:
  - `0`: `Success`
  - `2`: `BelowMinimum`
  - `3`: `CannotCreate`
  - `4`: `Overflow`
  - `7`: Success (canonical encoding)

##### 6.3 `can_withdraw(who: AccountId, amount: Balance) -> WithdrawConsequence`
- **Selector**: `0xF7A8F3E1`
- **Handler**: Function 63, handler index 18
- **Wasm Flow**:
  ```wasm
  ;; Load account
  local.get 0
  i32.const 216
  i32.add
  local.get who
  call 46
  
  ;; Calculate usable balance (free - frozen)
  local.get 0
  i64.load offset=216   ;; free (low)
  local.get 0
  i64.load offset=248   ;; frozen (low)
  i64.sub
  local.tee usable_low
  
  ;; Check if usable < amount
  local.get amount_low
  i64.gt_u
  if
    i32.const 2         ;; WithdrawConsequence::BalanceLow
    ;; ... (encode and return)
  end
  
  ;; Calculate new balance
  local.get 0
  i64.load offset=216
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
    i64.load offset=32  ;; ED (low)
    i64.lt_u
    if
      ;; Return ReducedToZero(new_balance) - discriminant 3
      ;; ... (encode tuple with new_balance payload)
    end
  end
  
  ;; Success
  i32.const 7
  ;; ... (encode and return)
  ```
- **WithdrawConsequence Enum**:
  - `0`/`7`: `Success`
  - `2`: `BalanceLow`
  - `3`: `ReducedToZero(Balance)` (includes 16-byte u128 payload)
  - `4`: `WouldDie`

---

#### 7. **MutateFreeze Trait** (Lock Management)

The `MutateFreeze` trait provides methods to set and remove balance locks.

##### 7.1 `set_freeze(who: AccountId, id: [u8; 8], amount: Balance) -> Result<()>`
- **Selector**: `0xCD0F5A06` (aliased as `set_lock`)
- **Handler**: Function 63, handler index 32
- **Wasm Flow**:
  ```wasm
  ;; Read existing locks from storage
  local.get 0
  i32.const 456
  i32.add               ;; Result destination
  local.get who
  call 16               ;; encode_locks_to_storage (also reads)
  
  ;; Check if allocation succeeded
  local.get 0
  i32.load offset=456   ;; locks.capacity
  i32.const -2147483648
  i32.eq
  br_if error_path
  
  ;; Extract locks vector
  local.get 0
  i32.load offset=460   ;; locks.ptr
  local.get 0
  i32.load offset=464   ;; locks.len
  
  ;; Search for existing lock with matching ID
  ;; ... (linear search through 24-byte BalanceLock structs)
  
  ;; If not found:
  if not_found
    ;; Check max_locks limit (state offset 80)
    local.get locks_len
    local.get 0
    i32.load offset=80  ;; max_locks
    i32.ge_u
    if
      i32.const 1
      i32.const 5       ;; Err(TooManyLocks)
      call 49
    end
    
    ;; Build new lock struct (24 bytes)
    local.get 0
    i32.const 456
    i32.add
    local.get lock_id
    i64.store
    local.get 0
    local.get amount_low
    i64.store offset=464
    local.get 0
    local.get amount_high
    i64.store offset=472
    
    ;; Append to vector
    local.get 0
    i32.const 376
    i32.add             ;; vec metadata
    local.get 0
    i32.const 456
    i32.add             ;; new lock struct
    call 23             ;; vec_push_balance_lock
  end
  
  ;; If found: update existing lock amount at match offset
  else
    local.get match_offset
    local.get amount_low
    i64.store
    local.get match_offset
    i32.const 8
    i32.add
    local.get amount_high
    i64.store
  end
  
  ;; Recalculate max lock (frozen)
  ;; ... (iterate over locks, find maximum amount)
  local.get max_lock_low
  local.set frozen_low
  
  ;; Update account.frozen
  local.get 0
  local.get frozen_low
  i64.store offset=248
  
  ;; Write locks to storage
  local.get who
  local.get 0
  i32.load offset=460   ;; locks.ptr
  local.get 0
  i32.load offset=464   ;; locks.len
  call 24               ;; write_locks_to_storage
  
  ;; Write updated account
  local.get who
  local.get 0
  i32.const 216
  i32.add
  call 28
  
  ;; Emit Locked event if frozen increased
  ;; ...
  ```
- **BalanceLock Structure** (24 bytes):
  ```
  Offset  Field        Size       Notes
  +0      amount_low   8 bytes    u128 low 64 bits
  +8      amount_high  8 bytes    u128 high 64 bits
  +16     id           8 bytes    Lock identifier
  ```
- **Storage Key**: `BLAKE2(0x00010000 || AccountId)` (prefix 65536)

##### 7.2 `thaw(who: AccountId, id: [u8; 8]) -> Result<()>`
- **Selector**: `0x11A08D5C` (aliased as `remove_lock`)
- **Handler**: Function 63, handler index 33
- **Wasm Flow**:
  ```wasm
  ;; Read locks vector
  local.get 0
  i32.const 208
  i32.add
  local.get who
  call 16               ;; Read locks
  
  ;; Extract vector metadata
  local.get 0
  i32.load offset=212   ;; locks.ptr
  local.set current_lock
  local.get 0
  i32.load offset=216   ;; locks.len
  local.set remaining
  
  ;; Filter out matching lock (in-place retain)
  i32.const 0
  local.set new_len
  local.get current_lock
  local.set dst
  
  loop                  ;; Retain loop
    local.get remaining
    i32.eqz
    br_if exit_retain
    
    ;; Check if current lock ID matches
    local.get current_lock
    i32.const 16
    i32.add
    i64.load align=1    ;; lock.id (at offset +16)
    local.get target_id
    i64.ne              ;; Keep if ID doesn't match
    if
      ;; Copy to destination (may be same position)
      local.get dst
      local.get current_lock
      i32.const 24      ;; sizeof(BalanceLock)
      memory.copy
      
      local.get dst
      i32.const 24
      i32.add
      local.set dst
      
      local.get new_len
      i32.const 1
      i32.add
      local.set new_len
    end
    
    ;; Next lock
    local.get current_lock
    i32.const 24
    i32.add
    local.set current_lock
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
  i32.store offset=216
  
  ;; Recalculate frozen (max of remaining locks)
  ;; ... (iterate and find max)
  
  ;; Write updated locks (or clear storage if empty)
  local.get new_len
  i32.eqz
  if
    ;; Clear storage entry
    ;; ... (build key, call seal_clear_storage)
    local.get key_ptr
    local.get key_len
    call 4              ;; seal_clear_storage
  else
    ;; Write updated vector
    local.get who
    local.get 0
    i32.load offset=212 ;; locks.ptr
    local.get new_len
    call 24             ;; write_locks_to_storage
  end
  
  ;; Emit Unlocked event if frozen decreased
  ;; ...
  ```

---

#### 8. **Balanced Trait** (Imbalance-Tracking Operations)

The `Balanced` trait provides methods that return imbalance objects (credit/debt) for later settlement.

##### 8.1 `deposit(who: AccountId, amount: Balance, precision: Precision) -> Result<CreditImbalance>`
- **Selector**: `0x05C81D55`
- **Handler**: Function 63, handler index 6
- **Wasm Flow**:
  ```wasm
  ;; Same logic as increase_balance (handler 16)
  ;; ... (ED check, overflow check, update account)
  
  ;; Encode Result::Ok discriminant
  i32.const 0
  local.get encoder_ptr
  call 37               ;; encode_u32
  
  ;; Encode CreditImbalance struct (just the u128 amount)
  local.get actual_deposited_low
  local.get actual_deposited_high
  local.get encoder_ptr
  call 27               ;; encode_u128
  
  ;; Return encoded result
  local.get encoded_len
  call 55               ;; seal_return_wrapper
  ```
- **Note**: The contract doesn't maintain a separate imbalance registry; the imbalance is immediately encoded and returned

##### 8.2 `issue(amount: Balance) -> CreditImbalance`
- **Selector**: `0x8B3BEC3B` (actually creates `pair`)
- **Handler**: Function 63, handler index 0 (default case in dispatcher)
- **Wasm Flow**:
  ```wasm
  ;; Check overflow in total_issuance
  local.get 0
  i64.load              ;; total_issuance (low)
  local.get amount_low
  i64.add
  ;; ... (overflow check)
  if overflow
    i32.const 1
    i32.const 4         ;; Err(Overflow)
    call 49
  end
  
  ;; Encode Result::Ok discriminant
  i32.const 0
  call 37
  
  ;; Encode tuple (CreditImbalance, DebtImbalance)
  ;; Both have same amount value
  local.get amount_low
  local.get amount_high
  call 27               ;; Encode first u128
  
  local.get amount_low
  local.get amount_high
  call 27               ;; Encode second u128
  
  ;; Return
  call 55
  ```

##### 8.3 `rescind(amount: Balance) -> DebtImbalance`
- **Selector**: `0x55F85D0F`
- **Handler**: Function 63, handler index 29
- **Wasm Flow**: Similar to `issue`, but returns only `DebtImbalance` (single u128)

##### 8.4 `resolve(who: AccountId, credit: CreditImbalance) -> Result<()>`
- **Selector**: `0x06A7D814`
- **Handler**: Function 63, handler index 7
- **Wasm Flow**:
  ```wasm
  ;; Extract credit.amount from encoded parameter
  local.get 1           ;; Reader ptr
  call 22               ;; decode_u128
  
  local.get 0
  i64.load offset=result ;; credit amount (low)
  local.get 0
  i32.const result+8
  i64.load              ;; credit amount (high)
  
  ;; Delegate to increase_balance logic
  ;; ... (same as handler 16)
  
  ;; Return Ok(())
  call 51               ;; return_ok_unit
  ```
- **Note**: No authorization check in `resolve` (unlike `mint` which checks caller == owner)

##### 8.5 `settle(who: AccountId, debt: DebtImbalance, preservation: Preservation) -> Result<CreditImbalance>`
- **Selector**: `0xC8CB2133`
- **Handler**: Function 63, handler index 8
- **Wasm Flow**:
  ```wasm
  ;; Extract debt.amount
  ;; ... (decode u128)
  
  ;; Try to burn the debt amount
  local.get 0
  i32.const 456
  i32.add               ;; Result ptr
  local.get 0
  i32.const 88
  i32.add               ;; From AccountId (state)
  local.get who
  local.get debt_amount_low
  local.get debt_amount_high
  local.get preservation
  i32.const 1           ;; Precision::BestEffort
  call 61               ;; Delegates to transfer_with_checks/burn logic
  
  ;; Check if burn succeeded
  local.get 0
  i32.load8_u offset=456
  if
    ;; Failed - return full debt as CreditImbalance
    ;; ... (encode Result::Ok(CreditImbalance { debt_amount }))
  end
  
  ;; Calculate remaining debt (unburned portion)
  local.get debt_amount_low
  local.get 0
  i64.load offset=464   ;; burned amount (low)
  i64.sub
  local.tee remaining_low
  
  ;; Encode Result::Ok discriminant
  i32.const 0
  call 37
  
  ;; Encode CreditImbalance { remaining }
  local.get remaining_low
  local.get remaining_high
  call 27
  
  ;; Return
  call 55
  ```
- **Semantics**: Attempts to burn `debt.amount` from `who`, returns unburnable portion as `CreditImbalance`

---

### Summary Table: Trait Method to Wasm Handler Mapping

| Trait | Method | Selector | Handler Index | Key Functions |
|-------|--------|----------|---------------|---------------|
| **Inspect** | `total_issuance()` | `0x6AEA3206` | 1 | (state read) |
| | `minimum_balance()` | `0xA7EAE324` | 3 | (state read) |
| | `balance(who)` | `0x0F5C5E92` | 9 | 35, 46 |
| | `total_balance(who)` | `0x7A2095E3` | 10 | 46, saturating add |
| | `reducible_balance(...)` | `0x2E9A5C32` | 25 | 35, 58, 47 |
| **Unbalanced** | `write_balance(...)` | `0xDC9A5E14` | 24 | 46, 28, 66 |
| | `set_total_issuance(...)` | `0xF9A48F8E` | 19 | (state write) |
| | `increase_balance(...)` | `0xB2E13B27` | 16 | 46, 28, 38 |
| | `decrease_balance(...)` | `0xA194B221` | 26 | 47, 61, 28 |
| **Mutate** | `transfer(...)` | `0xCE8F142D` | 5 | 42, 44, 61, 28 |
| | `burn_from(...)` | `0x9EA394B1` | 27 | 47, 61, 66 |
| **InspectHold** | `balance_on_hold(who)` | `0xA1B8F1E6` | 11 | 46 (read reserved) |
| | `total_balance_on_hold()` | `0x33F3948D` | 21 | (state read offset 16) |
| **MutateHold** | `hold(...)` (reserve) | `0xC1D8E627` | 22 | 46, 28, 38 |
| | `release(...)` (unreserve) | `0xF5A8B128` | 23 | 46, 28, 38 |
| **InspectFreeze** | `balance_frozen(who)` | `0x2F1A9DDC` | 28 | 46 (read frozen) |
| | `can_deposit(...)` | `0xB3F881A9` | 17 | 46, overflow checks |
| | `can_withdraw(...)` | `0xF7A8F3E1` | 18 | 46, 47 |
| **MutateFreeze** | `set_freeze(...)` (set_lock) | `0xCD0F5A06` | 32 | 16, 23, 24 |
| | `thaw(...)` (remove_lock) | `0x11A08D5C` | 33 | 16, 24, memory ops |
| **Balanced** | `deposit(...)` | `0x05C81D55` | 6 | 46, 28, encoding |
| | `issue(...)` | `0x8B3BEC3B` | 0 | (pair creation) |
| | `rescind(...)` | `0x55F85D0F` | 29 | (state check) |
| | `resolve(...)` | `0x06A7D814` | 7 | 22, increase logic |
| | `settle(...)` | `0xC8CB2133` | 8 | 61, encoding |

---

### Parameter Decoding Patterns

#### **Pattern 1: Fixed-Size Parameters (AccountId, u128)**
```wasm
;; Example: transfer(to: AccountId, amount: Balance)
;; Input layout: [selector: 4] [to: 32] [amount: 16]

;; Decode AccountId via function 35
local.get 0
i32.const 208
i32.add               ;; Result destination (33 bytes: flag + AccountId)
local.get reader_ptr
call 35               ;; decode_account_id

;; Check success flag
local.get 0
i32.load8_u offset=208
br_if error_path

;; AccountId now at offset 209-240 (32 bytes)
local.get 0
i32.const 209
i32.add
local.set account_ptr

;; Decode u128 via function 22
local.get 0
i32.const 456
i32.add               ;; Result destination (24 bytes: flag + u128)
local.get reader_ptr
call 22               ;; decode_u128

;; Check success flag
local.get 0
i32.load offset=456
br_if error_path

;; u128 now at offset 464 (low) and 472 (high)
local.get 0
i64.load offset=464   ;; Low 64 bits
local.get 0
i32.const 472
i32.add
i64.load              ;; High 64 bits
```

#### **Pattern 2: Enum Parameters (Preservation, Precision, etc.)**
```wasm
;; Example: burn_from(..., precision: Precision)

;; Decode via function 59 (ternary enum) or 58 (Preservation)
local.get reader_ptr
call 59               ;; decode_ternary_enum
local.tee precision

;; Validate range
i32.const 3
i32.ge_u
if
  ;; Invalid discriminant
  call 53             ;; return_err
end

;; Use discriminant value (0-2)
local.get precision
i32.eqz               ;; Check if Exact (0)
```

**Enum Mappings**:
- **Preservation**: `0` = Expendable, `1` = Preserve, `2` = Protect
- **Precision**: `0` = Exact, `1` = BestEffort
- **Fortitude**: `0` = Polite, `1` = Force

#### **Pattern 3: Option<T> Parameters**
```wasm
;; Example: new_with_dust_trap(dust_trap: Option<AccountId>)

;; Decode via function 56
local.get 0
i32.const 208
i32.add               ;; Result destination
local.get reader_ptr
call 56               ;; decode_option_account_id_full

;; Check result discriminant
local.get 0
i32.load8_u offset=208
local.tee discriminant

;; Match discriminant
block
  block
    local.get discriminant
    br_table 0 1 2    ;; 0: None, 1: Some, 2: Error
  end
  
  ;; Case 0: None
  i32.const 0
  local.set is_some
  br exit_decode
end

;; Case 1: Some - AccountId at offset 209
local.get 0
i32.const 209
i32.add
local.set account_ptr
i32.const 1
local.set is_some

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
;; Function 38: emit_transfer_event
;; Event: Transfer { from: Option<AccountId>, to: Option<AccountId>, value: Balance }

;; Initialize encoder at offset 52
local.get 0
i64.const 16384
i64.store offset=56   ;; capacity
local.get 0
i32.const 66280       ;; Global buffer
i32.store offset=52

;; Encode topic count (2 for Transfer)
local.get 0
i32.const 52
i32.add
local.tee 1
i32.const 2
call 34               ;; encode_vec_length

;; Encode event signature topic
local.get 1
i32.const 65610       ;; "Transfer" constant address
call 30               ;; encode_event_topic (hashes and appends)

;; Build from/to topic hashes
local.get 0
i32.const 68
i32.add               ;; Topics buffer state
local.get 1           ;; Encoder
local.get 0           ;; from AccountId ptr
call 39               ;; build_event_topic_hash

;; Extract topics buffer for seal_deposit_event
local.get 0
i32.load offset=76    ;; Topics length
local.get 0
i32.load offset=72    ;; Topics ptr

;; Encode event data (from, to, value)
local.get 0           ;; from Option<AccountId>
local.get encoder
call 41               ;; encode_option_account_id

local.get 0
i32.const 33
i32.add               ;; to Option<AccountId>
local.get encoder
call 41

local.get value_low
local.get value_high
local.get encoder
call 27               ;; encode_u128 (value)

;; Emit event
local.get topics_ptr
local.get topics_len
local.get data_ptr
local.get data_len
call 2                ;; seal_deposit_event
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
