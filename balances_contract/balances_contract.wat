(module
  ;; ============================================================================
  ;; TYPE DEFINITIONS
  ;; ============================================================================

  ;; Type 0: Binary procedure (no return)
  ;; Used for: SCALE codec operations, memory copies, event emission setup
  ;; Parameters: (dest_ptr, src_ptr) -> void
  (type $type_binary_proc (;0;) (func (param i32 i32)))
  
  ;; Type 1: 3-parameter procedure (no return)
  ;; Used for: memory operations (fill/copy), hashing, error handling
  ;; Parameters: (dest, src, length) -> void
  (type $type_ternary_proc (;1;) (func (param i32 i32 i32)))
  
  ;; Type 2: Generic 3-parameter function returning i32
  ;; Used for: comparisons, memory operations, encoding/decoding operations
  ;; Parameters: (pointer/value, pointer/value, length/value) -> result/status
  (type $type_generic_3param_ret_i32 (;2;) (func (param i32 i32 i32) (result i32)))
  
  ;; Type 3: Binary function with i32 result
  ;; Used for: trait method implementations, equality checks, formatting operations
  ;; Parameters: (self_ptr, other_ptr) -> bool/status
  (type $type_binary_op_ret_i32 (;3;) (func (param i32 i32) (result i32)))
  
  ;; Type 4: Single parameter procedure
  ;; Used for: cleanup operations, panic handlers, initialization
  ;; Parameters: (ptr/value) -> void
  (type $type_unary_proc (;4;) (func (param i32)))
  
  ;; Type 5: Nullary procedure (no params, no return)
  ;; Used for: module initialization, empty handlers, finalization
  ;; Parameters: () -> void
  (type $type_nullary_proc (;5;) (func))
  
  ;; Type 6: Unary function with result
  ;; Used for: balance queries, type conversions, option unwrapping
  ;; Parameters: (value/ptr) -> result
  (type $type_unary_func_ret_i32 (;6;) (func (param i32) (result i32)))
  
  ;; Type 7: Storage operation with result
  ;; Used for: seal_get_storage, seal_set_storage, seal_clear_storage
  ;; Parameters: (key_ptr, key_len, value_ptr, value_len) -> status_code
  (type $type_storage_op_ret_i32 (;7;) (func (param i32 i32 i32 i32) (result i32)))
  
  ;; Type 8: 4-parameter procedure
  ;; Used for: seal_deposit_event, complex memory operations
  ;; Parameters: (ptr1, ptr2, len1, len2) -> void
  (type $type_quad_proc (;8;) (func (param i32 i32 i32 i32)))
  
  ;; Type 9: 128-bit value operation
  ;; Used for: Balance (u128) encoding, storage key generation
  ;; Parameters: (value_low_64, value_high_64, output_ptr) -> void
  (type $type_u128_operation (;9;) (func (param i64 i64 i32)))
  
  ;; Type 10: Nullary function with result
  ;; Used for: getters (total_issuance, active_issuance), status queries
  ;; Parameters: () -> value
  (type $type_nullary_func_ret_i32 (;10;) (func (result i32)))
  
  ;; Type 11: Complex balance operation
  ;; Used for: deposit/withdrawal with imbalances, multi-balance updates
  ;; Parameters: (account_ptr, amount_low, amount_high, flags, extra_ptr) -> void
  (type $type_balance_complex_op (;11;) (func (param i32 i64 i64 i32 i32)))
  
  ;; Type 12: 128-bit binary operation
  ;; Used for: u128 arithmetic (addition/subtraction), balance updates
  ;; Parameters: (value1_low, value1_high) -> void
  (type $type_u128_binary_op (;12;) (func (param i64 i64)))
  
  ;; Type 13: Transfer/withdrawal with 128-bit amounts
  ;; Used for: transfer operations, can_withdraw checks
  ;; Parameters: (account_ptr, flags, amount_low, amount_high) -> status
  (type $type_transfer_op_ret_i32 (;13;) (func (param i32 i32 i64 i64) (result i32)))
  
  ;; Type 14: Complex balance transfer
  ;; Used for: transfer_with_preservation, burn_from with all parameters
  ;; Parameters: (from_ptr, to_ptr, flags, amount_low, amount_high, preserve, precision) -> void
  (type $type_transfer_complex (;14;) (func (param i32 i32 i32 i64 i64 i32 i32)))
  
  ;; Type 15: Transfer check with result
  ;; Used for: can_deposit, can_withdraw with provenance tracking
  ;; Parameters: (account_ptr, metadata, flags, amount_low, amount_high, mode) -> consequence
  (type $type_transfer_check_ret_i32 (;15;) (func (param i32 i32 i32 i64 i64 i32) (result i32)))
  
  ;; Type 16: Balance update operation
  ;; Used for: increase_balance, decrease_balance with precision/fortitude
  ;; Parameters: (account_ptr, amount_low, amount_high, flags) -> void
  (type $type_balance_update (;16;) (func (param i32 i64 i64 i32)))

  ;; ============================================================================
  ;; IMPORT DECLARATIONS
  ;; ============================================================================

  ;; Import 0: Get value from contract storage (seal1 version with result code)
  ;; Returns: 0 on success, 1 if key not found, 2 on other errors
  ;; Used for: Reading AccountData, locks, and other persistent state
  ;; Parameters: (key_ptr, key_len, out_ptr, out_len_ptr) -> status_code
  (import "seal1" "get_storage" (func $seal_get_storage (;0;) (type 7)))
  
  ;; Import 1: Read the input data passed to the contract call
  ;; Reads the SCALE-encoded input buffer into contract memory
  ;; Used for: Decoding message selector and parameters
  ;; Parameters: (buf_ptr, buf_len_ptr) -> void
  (import "seal0" "input" (func $seal_input (;1;) (type 0)))
  
  ;; Import 2: Emit an event from the contract
  ;; Writes event data to the host for indexing (Transfer, Endowed, etc.)
  ;; Used for: Emitting all balance-related events
  ;; Parameters: (topics_ptr, topics_len, data_ptr, data_len) -> void
  (import "seal0" "deposit_event" (func $seal_deposit_event (;2;) (type 8)))
  
  ;; Import 3: Set/update a value in contract storage (seal2 version)
  ;; Returns: 0 if new key, size of old value if updating
  ;; Used for: Persisting AccountData, locks, and configuration
  ;; Parameters: (key_ptr, key_len, value_ptr, value_len) -> old_value_size
  (import "seal2" "set_storage" (func $seal_set_storage (;3;) (type 7)))
  
  ;; Import 4: Remove a key from contract storage (seal1 version)
  ;; Returns: 0 if key didn't exist, size of removed value otherwise
  ;; Used for: Cleaning up empty accounts, removing locks
  ;; Parameters: (key_ptr, key_len) -> old_value_size
  (import "seal1" "clear_storage" (func $seal_clear_storage (;4;) (type 3)))
  
  ;; Import 5: Return from contract execution with data
  ;; Terminates execution and returns SCALE-encoded result to caller
  ;; Used for: Returning query results and errors
  ;; Parameters: (flags, data_ptr, data_len) -> never_returns
  (import "seal0" "seal_return" (func $seal_return (;5;) (type 1)))
  
  ;; Import 6: Get the caller's AccountId
  ;; Writes the 32-byte AccountId of the message sender
  ;; Used for: Authentication, transfer source identification
  ;; Parameters: (output_ptr, output_len_ptr) -> void
  (import "seal0" "caller" (func $seal_caller (;6;) (type 0)))
  
  ;; Import 7: Get the value (balance) transferred with this call
  ;; Writes the 128-bit balance value sent with the message
  ;; Used for: Payable message handling
  ;; Parameters: (output_ptr, output_len_ptr) -> void
  (import "seal0" "value_transferred" (func $seal_value_transferred (;7;) (type 0)))
  
  ;; Import 8: Compute BLAKE2-256 hash
  ;; Hashes input data using BLAKE2b-256 algorithm
  ;; Used for: Generating storage keys for Mapping<K,V>
  ;; Parameters: (input_ptr, input_len, output_ptr) -> void
  (import "seal0" "hash_blake2_256" (func $seal_hash_blake2_256 (;8;) (type 1)))
  
  ;; Import 9: Linear memory shared between contract and host
  ;; Initial: 2 pages (128 KiB), Maximum: 16 pages (1 MiB)
  ;; Used for: All contract data, stack, heap allocations
  ;; Layout: [stack | heap | static data]
  (import "env" "memory" (memory (;0;) 2 16))

  ;; ============================================================================
  ;; LOW-LEVEL MEMORY OPERATIONS
  ;; ============================================================================

  ;; Function 9: Forward memory copy loop
  ;; Copies memory byte-by-byte in forward direction (low to high addresses)
  ;; Used when: source and destination don't overlap, or dest < src
  ;; Parameters: (dest, src, len) -> dest
  ;; Returns: Original destination pointer
  (func $memcpy_forward_loop (;9;) (type 2) (param i32 i32 i32) (result i32)
    (local i32)          ;; Local 3: loop counter
    loop (result i32)    ;; label = @1
      local.get 2        ;; len
      local.get 3        ;; counter
      i32.eq
      if (result i32)    ;; label = @2 - if counter == len, done
        local.get 0      ;; return dest
      else
        local.get 0
        local.get 3
        i32.add          ;; dest[counter]
        local.get 1
        local.get 3
        i32.add
        i32.load8_u      ;; src[counter]
        i32.store8       ;; dest[counter] = src[counter]
        local.get 3
        i32.const 1
        i32.add
        local.set 3      ;; counter++
        br 1 (;@1;)      ;; continue loop
      end
    end)

  ;; Function 10: Safe memory move (handles overlapping regions)
  ;; Chooses forward or backward copy based on pointer relationship
  ;; Used for: SCALE codec buffer management, vector operations
  ;; Parameters: (dest, src, len) -> dest
  ;; Returns: Destination pointer
  (func $memmove (;10;) (type 2) (param i32 i32 i32) (result i32)
    (local i32)          ;; Local 3: working pointer
    block  ;; label = @1
      local.get 0        ;; dest
      local.get 1        ;; src
      i32.le_u
      if  ;; label = @2 - if dest <= src (forward copy safe)
        ;; Forward copy loop
        local.get 0
        local.set 3
        loop  ;; label = @3
          local.get 2    ;; len
          i32.eqz
          br_if 2 (;@1;) ;; if len == 0, exit
          local.get 3
          local.get 1
          i32.load8_u
          i32.store8     ;; *dest++ = *src++
          local.get 3
          i32.const 1
          i32.add
          local.set 3
          local.get 1
          i32.const 1
          i32.add
          local.set 1
          local.get 2
          i32.const 1
          i32.sub
          local.set 2
          br 0 (;@3;)    ;; continue
        end
        unreachable
      end
      ;; Backward copy (dest > src, overlapping)
      local.get 0
      i32.const 1
      i32.sub
      local.set 3
      local.get 1
      i32.const 1
      i32.sub
      local.set 1
      loop  ;; label = @2
        local.get 2
        i32.eqz
        br_if 1 (;@1;)   ;; if len == 0, exit
        local.get 2
        local.get 3
        i32.add
        local.get 1
        local.get 2
        i32.add
        i32.load8_u
        i32.store8       ;; Copy from end backwards
        local.get 2
        i32.const 1
        i32.sub
        local.set 2
        br 0 (;@2;)      ;; continue
      end
      unreachable
    end
    local.get 0)         ;; return dest

  ;; Function 11: Memory fill loop
  ;; Fills memory region with a specific byte value
  ;; Used for: Zeroing buffers, initializing arrays
  ;; Parameters: (dest, fill_byte, len) -> dest
  ;; Returns: Destination pointer
  (func $memset_loop (;11;) (type 2) (param i32 i32 i32) (result i32)
    (local i32)          ;; Local 3: counter
    loop (result i32)    ;; label = @1
      local.get 2        ;; len
      local.get 3        ;; counter
      i32.eq
      if (result i32)    ;; label = @2
        local.get 0      ;; return dest
      else
        local.get 0
        local.get 3
        i32.add
        local.get 1      ;; fill_byte
        i32.store8       ;; dest[counter] = fill_byte
        local.get 3
        i32.const 1
        i32.add
        local.set 3      ;; counter++
        br 1 (;@1;)      ;; continue loop
      end
    end)

  ;; Function 12: Memory comparison (memcmp)
  ;; Compares two memory regions byte-by-byte
  ;; Used for: AccountId equality, storage key comparison
  ;; Parameters: (ptr1, ptr2, len) -> difference
  ;; Returns: 0 if equal, negative if ptr1 < ptr2, positive if ptr1 > ptr2
  (func $memcmp (;12;) (type 2) (param i32 i32 i32) (result i32)
    (local i32 i32)      ;; Local 3: byte1, Local 4: byte2
    loop  ;; label = @1
      local.get 2
      i32.eqz
      if  ;; label = @2 - if len == 0
        i32.const 0
        return           ;; regions are equal
      end
      local.get 2
      i32.const 1
      i32.sub
      local.set 2        ;; len--
      local.get 1
      i32.load8_u
      local.set 3        ;; byte2 = *ptr2
      local.get 0
      i32.load8_u
      local.set 4        ;; byte1 = *ptr1
      local.get 1
      i32.const 1
      i32.add
      local.set 1        ;; ptr2++
      local.get 0
      i32.const 1
      i32.add
      local.set 0        ;; ptr1++
      local.get 3
      local.get 4
      i32.eq             ;; if bytes equal
      br_if 0 (;@1;)     ;; continue loop
    end
    local.get 4          ;; byte1
    local.get 3          ;; byte2
    i32.sub)             ;; return difference

  ;; Function 13: Helper to validate exact memory copy length
  ;; Validates that source and destination lengths match
  ;; Used for: SCALE decoder safety checks
  ;; Parameters: (dest, src, expected_len, actual_len) -> void
  ;; Panics if: actual_len != expected_len
  (func $validate_exact_copy (;13;) (type 8) (param i32 i32 i32 i32)
    ;; Check if lengths match
    local.get 1          ;; actual_len
    local.get 3          ;; expected_len
    i32.eq
    if  ;; label = @1 - if equal, perform copy
      local.get 0        ;; dest
      local.get 2        ;; src
      local.get 1        ;; len
      call 9             ;; Use $memcpy_forward_loop
      drop
      return
    end
    unreachable)         ;; Panic on length mismatch

  ;; ============================================================================
  ;; SCALE CODEC - BUFFER READING
  ;; ============================================================================

  ;; Function 14: Read bytes from SCALE decode buffer
  ;; Consumes bytes from a decode cursor, checking bounds
  ;; Used for: Decoding message parameters, storage values
  ;; Parameters: (reader_state_ptr, output_ptr, bytes_to_read) -> success_flag
  ;; Returns: 0 on success, 1 on buffer underflow
  (func $scale_read_bytes (;14;) (type 2) (param i32 i32 i32) (result i32)
    (local i32)          ;; Local 3: result flag
    ;; Check if cursor has been advanced (special single-byte read mode)
    local.get 0
    i32.load8_u offset=4 ;; Check advanced flag
    local.set 3
    local.get 0
    i32.const 0
    i32.store8 offset=4  ;; Clear flag
    
    local.get 3
    i32.eqz
    if  ;; label = @1 - Normal read path
      local.get 0
      i32.load           ;; Get reader struct pointer
      local.get 1        ;; output_ptr
      local.get 2        ;; bytes_to_read
      call 15            ;; Perform bounded read
      return
    end
    
    ;; Single-byte cached read path
    local.get 1
    local.get 0
    i32.load8_u offset=5 ;; Read cached byte
    i32.store8           ;; Write to output
    
    local.get 0
    i32.load             ;; Get reader struct
    local.get 1
    i32.const 1
    i32.add              ;; Advance output by 1
    local.get 2
    i32.const 1
    i32.sub              ;; Reduce requested by 1
    call 15)             ;; Read remaining bytes

  ;; Function 15: Core bounded buffer read operation
  ;; Reads from buffer with bounds checking and cursor advancement
  ;; Used by: All SCALE decoding operations
  ;; Parameters: (reader_ptr, output_ptr, bytes_to_read) -> error_flag
  ;; Returns: 0 on success, 1 on underflow
  (func $bounded_buffer_read (;15;) (type 2) (param i32 i32 i32) (result i32)
    (local i32 i32)      ;; Locals for remaining bytes and current pointer
    
    ;; Check if enough data remaining
    local.get 0
    i32.load offset=4    ;; reader.remaining
    local.tee 3
    local.get 2          ;; bytes_to_read
    i32.lt_u
    local.tee 4          ;; underflow flag
    i32.eqz
    if  ;; label = @1 - if remaining >= bytes_to_read
      ;; Perform the copy
      local.get 1        ;; dest
      local.get 2        ;; expected_len
      local.get 0
      i32.load           ;; reader.ptr (src)
      local.tee 1
      local.get 2        ;; actual_len (remaining)
      call 13            ;; validate_exact_copy
      
      ;; Update reader state
      local.get 0
      local.get 3
      local.get 2
      i32.sub
      i32.store offset=4 ;; remaining -= bytes_to_read
      local.get 0
      local.get 1        ;; old ptr
      local.get 2
      i32.add
      i32.store          ;; ptr += bytes_to_read
    end
    
    local.get 4)         ;; return error flag

  ;; ============================================================================
  ;; SCALE ENCODING TO STORAGE
  ;; ============================================================================

  ;; Function 16: Encode and write Mapping<AccountId, Vec<BalanceLock>>
  ;; Encodes a vector of balance locks and writes to storage
  ;; Used for: Persisting account lock data in set_lock/remove_lock
  ;; Parameters: (result_ptr, locks_vec_ptr) -> void
  ;; Result: Stores encoded data info in result_ptr (ptr, len, capacity)
  (func $encode_locks_to_storage (;16;) (type 0) (param i32 i32)
    (local i32 i32 i32 i32 i32 i32 i64)
    global.get 0
    i32.const 128
    i32.sub
    local.tee 2          ;; Allocate 128-byte stack frame
    global.set 0
    
    ;; Copy vector metadata to stack (locks are [BalanceLock; N])
    local.get 2
    i32.const 36
    i32.add
    local.get 1
    i32.const 8
    i32.add
    i64.load align=1
    i64.store align=4
    local.get 2
    i32.const 44
    i32.add
    local.get 1
    i32.const 16
    i32.add
    i64.load align=1
    i64.store align=4
    local.get 2
    i32.const 52
    i32.add
    local.get 1
    i32.const 24
    i32.add
    i64.load align=1
    i64.store align=4
    local.get 2
    i32.const 65536      ;; Storage key prefix for locks
    i32.store offset=24
    local.get 2
    local.get 1
    i64.load align=1
    i64.store offset=28 align=4
    
    ;; Initialize encoder buffer at offset 104
    local.get 2
    i64.const 16384      ;; Buffer capacity
    i64.store offset=108 align=4
    local.get 2
    i32.const 66280      ;; Buffer start
    i32.store offset=104
    
    ;; Encode the storage key
    local.get 2
    i32.const 24
    i32.add
    local.get 2
    i32.const 104
    i32.add
    local.tee 5          ;; Save encoder pointer
    call 17              ;; encode_mapping_key
    
    block  ;; label = @1
      ;; Check encoder state (ptr should be >= used)
      local.get 2
      i32.load offset=108  ;; encoder.capacity (NOTE: field order!)
      local.tee 3
      local.get 2
      i32.load offset=112  ;; encoder.used
      local.tee 1
      i32.lt_u
      br_if 0 (;@1;)      ;; Exit if error
      
      local.get 2
      i32.load offset=104  ;; encoder.ptr
      local.set 4
      
      ;; Update encoder state for next operation
      local.get 2
      local.get 3
      local.get 1
      i32.sub
      local.tee 3          ;; remaining = capacity - used
      i32.store offset=104
      
      ;; Call seal_get_storage to read current value
      local.get 4          ;; key_ptr
      local.get 1          ;; key_len
      local.get 1
      local.get 4
      i32.add
      local.tee 4          ;; value_ptr (reuse buffer after key)
      local.get 5          ;; value_len_ptr
      call 0               ;; seal_get_storage
      local.set 1
      
      ;; Validate storage operation
      local.get 3
      local.get 2
      i32.load offset=104  ;; Check updated value
      local.tee 3
      i32.lt_u
      local.get 1
      i32.const 15
      i32.ge_u
      i32.or
      br_if 0 (;@1;)
      
      ;; Process result code
      local.get 0
      block (result i64)  ;; label = @2
        local.get 1
        i32.const 65906    ;; Result code lookup table
        i32.add
        i32.load8_u
        local.tee 1
        i32.const 3
        i32.eq
        if  ;; label = @3
          ;; KeyNotFound case
          i32.const -2147483648
          local.set 1
          i64.const 16     ;; Default capacity
          br 1 (;@2;)
        end
        
        local.get 1
        i32.const 16
        i32.ne
        br_if 1 (;@1;)    ;; Exit if not Success
        
        ;; Success: decode the value
        local.get 2
        local.get 3
        i32.store offset=64
        local.get 2
        local.get 4
        i32.store offset=60
        
        ;; Decode compact length prefix
        local.get 2
        i32.const 16
        i32.add
        local.get 2
        i32.const 60
        i32.add
        call 18            ;; Read first byte
        
        local.get 2
        i32.load8_u offset=16
        br_if 1 (;@1;)
        
        block  ;; label = @3
          block  ;; label = @4
            block  ;; label = @5
              block  ;; label = @6
                block  ;; label = @7
                  ;; Decode compact encoding mode
                  local.get 2
                  i32.load8_u offset=17
                  local.tee 1
                  i32.const 3
                  i32.and
                  i32.const 1
                  i32.sub
                  br_table 1 (;@6;) 2 (;@5;) 3 (;@4;) 0 (;@7;)
                end
                ;; Mode 3: single-byte direct encoding (0-63)
                local.get 1
                i32.const 252
                i32.and
                i32.const 2
                i32.shr_u
                local.set 3
                br 3 (;@3;)
              end
              ;; Mode 0: two-byte encoding (64-16383)
              local.get 2
              local.get 1
              i32.store8 offset=109
              local.get 2
              i32.const 1
              i32.store8 offset=108
              local.get 2
              local.get 2
              i32.const 60
              i32.add
              i32.store offset=104
              local.get 2
              i32.const 0
              i32.store16 offset=80
              local.get 2
              i32.const 104
              i32.add
              local.get 2
              i32.const 80
              i32.add
              i32.const 2
              call 14
              br_if 4 (;@1;)
              local.get 2
              i32.load16_u offset=80
              local.tee 1
              i32.const 255
              i32.le_u
              br_if 4 (;@1;)
              local.get 1
              i32.const 2
              i32.shr_u
              local.set 3
              br 2 (;@3;)
            end
            ;; Mode 1: four-byte encoding (16384-1073741823)
            local.get 2
            local.get 1
            i32.store8 offset=109
            local.get 2
            i32.const 1
            i32.store8 offset=108
            local.get 2
            local.get 2
            i32.const 60
            i32.add
            i32.store offset=104
            local.get 2
            i32.const 0
            i32.store offset=80
            local.get 2
            i32.const 104
            i32.add
            local.get 2
            i32.const 80
            i32.add
            i32.const 4
            call 14
            br_if 3 (;@1;)
            local.get 2
            i32.load offset=80
            local.tee 1
            i32.const 65536
            i32.lt_u
            br_if 3 (;@1;)
            local.get 1
            i32.const 2
            i32.shr_u
            local.set 3
            br 1 (;@3;)
          end
          ;; Mode 2: multi-byte encoding (>= 1073741824)
          local.get 1
          i32.const 4
          i32.ge_u
          br_if 2 (;@1;)
          local.get 2
          i32.const 8
          i32.add
          local.get 2
          i32.const 60
          i32.add
          call 19
          local.get 2
          i32.load offset=8
          br_if 2 (;@1;)
          local.get 2
          i32.load offset=12
          local.tee 3
          i32.const 1073741824
          i32.lt_u
          br_if 2 (;@1;)
        end
        
        ;; Initialize result vector for decoded locks
        i32.const 0
        local.set 1
        local.get 2
        i32.const 0
        i32.store offset=76
        local.get 2
        i64.const 34359738368  ;; capacity = 8, ptr = 16
        i64.store offset=68 align=4
        i32.const 682        ;; Growth factor
        local.set 4
        local.get 2
        i32.const 120
        i32.add
        local.set 7
        
        ;; Main decode loop
        loop  ;; label = @3
          local.get 3
          if  ;; label = @4
            block  ;; label = @5
              ;; Check if we need to grow the vector
              local.get 4
              local.get 3
              local.get 3
              local.get 4
              i32.gt_u
              select
              local.tee 4
              local.get 2
              i32.load offset=68  ;; vec.capacity
              local.tee 5
              local.get 1            ;; vec.len
              i32.sub
              i32.le_u
              br_if 0 (;@5;)
              
              ;; Grow vector capacity
              local.get 1
              local.get 1
              local.get 4
              i32.add
              local.tee 1
              i32.gt_u
              br_if 4 (;@1;)
              
              ;; Calculate size in bytes (24 bytes per lock)
              local.get 1
              i64.extend_i32_u
              i64.const 24
              i64.mul
              local.tee 8
              i64.const 32
              i64.shr_u
              i32.wrap_i64
              br_if 4 (;@1;)
              
              local.get 8
              i32.wrap_i64
              local.tee 6
              i32.const 2147483640
              i32.gt_u
              br_if 4 (;@1;)
              
              ;; Prepare reallocation parameters
              local.get 2
              local.get 5
              if (result i32)  ;; label = @6
                local.get 2
                local.get 2
                i32.load offset=72
                i32.store offset=104
                local.get 2
                local.get 5
                i32.const 24
                i32.mul
                i32.store offset=112
                i32.const 8
              else
                i32.const 0
              end
              i32.store offset=108
              
              ;; Reallocate
              local.get 2
              i32.const 80
              i32.add
              local.get 6
              local.get 2
              i32.const 104
              i32.add
              call 20
              
              local.get 2
              i32.load offset=84
              local.set 5
              local.get 2
              i32.load offset=80
              i32.eqz
              if  ;; label = @6
                ;; Success
                local.get 2
                local.get 1
                i32.store offset=68
                local.get 2
                local.get 5
                i32.store offset=72
                br 1 (;@5;)
              end
              
              ;; Allocation failure check
              local.get 5
              i32.const -2147483647
              i32.ne
              br_if 4 (;@1;)
            end
            
            ;; Decode one batch of locks
            local.get 4
            local.set 1
            loop  ;; label = @5
              local.get 1
              i32.eqz
              if  ;; label = @6
                ;; Finished batch
                local.get 3
                local.get 4
                i32.sub
                local.set 3
                local.get 2
                i32.load offset=76
                local.tee 1
                local.set 4
                br 3 (;@3;)
              end
              
              ;; Decode one BalanceLock
              ;; Read lock.id (8 bytes)
              local.get 2
              i32.const 60
              i32.add
              local.tee 5
              local.get 2
              i32.const 104
              i32.add
              local.tee 6
              call 21
              br_if 4 (;@1;)
              
              ;; Save lock.id
              local.get 2
              i64.load offset=104
              local.set 8
              
              ;; Read lock.amount (u128 = 16 bytes)
              local.get 6
              local.get 5
              call 22
              local.get 2
              i32.load offset=104
              br_if 4 (;@1;)
              
              ;; Copy decoded lock to temporary
              local.get 2
              local.get 2
              i64.load offset=112
              i64.store offset=80
              local.get 2
              local.get 8
              i64.store offset=96
              local.get 2
              local.get 7
              i64.load
              i64.store offset=88
              
              ;; Append to vector
              local.get 1
              i32.const 1
              i32.sub
              local.set 1
              local.get 2
              i32.const 68
              i32.add
              local.get 2
              i32.const 80
              i32.add
              call 23
              br 0 (;@5;)
            end
            unreachable
          end
        end
        
        ;; Validate final vector state
        local.get 2
        i32.load offset=68
        local.tee 1
        i32.const -2147483648
        i32.eq
        br_if 1 (;@1;)
        
        local.get 2
        i32.load offset=64  ;; Check additional state
        local.get 1
        i32.const -2147483647
        i32.eq
        i32.or
        br_if 1 (;@1;)
        
        ;; Load final vector data
        local.get 2
        i64.load offset=72 align=4
      end
      i64.store offset=4 align=4
      
      ;; Store result (capacity in first field)
      local.get 0
      local.get 1
      i32.store
      
      local.get 2
      i32.const 128
      i32.add
      global.set 0
      return
    end
    unreachable)

  ;; Function 17: Encode storage key for Mapping
  ;; Hashes the Mapping prefix + AccountId to generate storage key
  ;; Used for: All Mapping operations (accounts, locks)
  ;; Parameters: (key_data_ptr, encoder_ptr) -> void
  (func $encode_mapping_key (;17;) (type 0) (param i32 i32)
    local.get 0
    i32.load             ;; Load Mapping prefix
    i32.load
    local.get 1
    call 37              ;; Encode u32 prefix
    local.get 0
    i32.const 4
    i32.add
    local.get 1
    call 31)             ;; Encode AccountId (32 bytes)

  ;; Function 18: Decode Option-like discriminant byte
  ;; Reads a single byte and returns it with EOF flag
  ;; Used for: Option<T> decoding, enum discriminants
  ;; Parameters: (result_ptr, reader_ptr) -> void
  ;; Result: Stores (is_eof, value) at result_ptr
  (func $decode_byte (;18;) (type 0) (param i32 i32)
    (local i32 i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 2
    global.set 0
    local.get 2
    i32.const 0
    i32.store8 offset=15
    local.get 0
    local.get 1
    local.get 2
    i32.const 15
    i32.add
    i32.const 1
    call 15              ;; Try to read 1 byte
    local.tee 1
    if (result i32)      ;; label = @1 - if failed (EOF)
      i32.const 0
    else
      local.get 2
      i32.load8_u offset=15
    end
    i32.store8 offset=1  ;; Store byte value
    local.get 0
    local.get 1
    i32.store8           ;; Store EOF flag
    local.get 2
    i32.const 16
    i32.add
    global.set 0)

  ;; Function 19: Read 4-byte value from buffer
  ;; Reads u32 from decode buffer
  ;; Used for: Decoding length prefixes, discriminants
  ;; Parameters: (result_ptr, reader_ptr) -> void
  ;; Result: Stores (error_flag, value) at result_ptr
  (func $decode_u32 (;19;) (type 0) (param i32 i32)
    (local i32 i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 2
    global.set 0
    
    ;; Initialize output
    local.get 2
    i32.const 0
    i32.store offset=12
    
    block  ;; label = @1
      ;; Try to read 4 bytes
      local.get 1
      local.get 2
      i32.const 12
      i32.add
      i32.const 4
      call 15
      i32.eqz
      if  ;; label = @2
        local.get 2
        i32.load offset=12
        local.set 1
        br 1 (;@1;)
      end
      i32.const 1
      local.set 3
    end
    
    ;; Store result
    local.get 0
    local.get 1
    i32.store offset=4
    local.get 0
    local.get 3
    i32.store
    
    local.get 2
    i32.const 16
    i32.add
    global.set 0)

  ;; Function 20: Allocate or resize encoder buffer
  ;; Grows the encoding buffer when more space needed
  ;; Used for: Encoding large structures, vectors
  ;; Parameters: (result_ptr, new_size, realloc_params_ptr) -> void
  (func $encoder_buffer_resize (;20;) (type 1) (param i32 i32 i32)
    (local i32 i32 i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 3
    global.set 0
    
    block (result i32)  ;; label = @1
      local.get 2
      i32.load offset=4
      if  ;; label = @2
        local.get 2
        i32.load offset=8
        local.tee 4
        i32.eqz
        if  ;; label = @3
          ;; New allocation
          local.get 3
          i32.const 8
          i32.add
          local.get 1
          call 67
          local.get 3
          i32.load offset=8
          local.set 2
          local.get 3
          i32.load offset=12
          br 2 (;@1;)
        end
        
        ;; Reallocation
        local.get 2
        i32.load
        local.set 5
        block  ;; label = @3
          local.get 1
          call 68
          local.tee 2
          i32.eqz
          if  ;; label = @4
            i32.const 0
            local.set 2
            br 1 (;@3;)
          end
          local.get 2
          local.get 5
          local.get 4
          call 9
          drop
        end
        local.get 1
        br 1 (;@1;)
      end
      
      ;; Simple allocation
      local.get 3
      local.get 1
      call 67
      local.get 3
      i32.load
      local.set 2
      local.get 3
      i32.load offset=4
    end
    local.set 4
    
    ;; Store result
    local.get 0
    local.get 2
    i32.const 8
    local.get 2
    select
    i32.store offset=4
    local.get 0
    local.get 2
    i32.eqz
    i32.store
    local.get 0
    local.get 4
    local.get 1
    local.get 2
    select
    i32.store offset=8
    
    local.get 3
    i32.const 16
    i32.add
    global.set 0)

  ;; Function 21: Read 8 bytes from buffer (for lock IDs)
  ;; Reads fixed 8-byte value
  ;; Parameters: (reader_ptr, output_ptr) -> error_flag
  (func $read_8_bytes (;21;) (type 3) (param i32 i32) (result i32)
    ;; Zero the output first
    local.get 1
    i64.const 0
    i64.store align=1
    ;; Read 8 bytes
    local.get 0
    local.get 1
    i32.const 8
    call 15)

  ;; Function 22: Read 16 bytes (u128) from buffer
  ;; Reads 128-bit value for Balance amounts
  ;; Parameters: (result_ptr, reader_ptr) -> void
  ;; Result: Stores error flag and u128 value
  (func $decode_u128 (;22;) (type 0) (param i32 i32)
    (local i32 i32 i64)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 2
    global.set 0
    
    ;; Initialize 16-byte buffer
    local.get 2
    i32.const 8
    i32.add
    local.tee 3
    i64.const 0
    i64.store
    local.get 2
    i64.const 0
    i64.store
    
    block  ;; label = @1
      ;; Read 16 bytes
      local.get 1
      local.get 2
      i32.const 16
      call 15
      i32.eqz
      if  ;; label = @2
        ;; Success: copy to output
        local.get 0
        local.get 2
        i64.load
        i64.store offset=8
        local.get 0
        local.get 3
        i64.load
        i64.store offset=16
        br 1 (;@1;)
      end
      i64.const 1
      local.set 4
    end
    
    local.get 0
    local.get 4
    i64.store
    
    local.get 2
    i32.const 16
    i32.add
    global.set 0)

  ;; Function 23: Push BalanceLock to vector
  ;; Appends a 24-byte lock structure to locks vector
  ;; Used for: set_lock when adding new lock entry
  ;; Parameters: (vec_ptr, lock_struct_ptr) -> void
  (func $vec_push_balance_lock (;23;) (type 0) (param i32 i32)
    (local i32 i32 i32 i32 i32 i64)
    
    ;; Check if vector needs to grow
    local.get 0
    i32.load offset=8    ;; vec.len
    local.tee 6
    local.get 0
    i32.load            ;; vec.capacity
    i32.eq
    if  ;; label = @1 - if len == capacity
      ;; Grow vector
      global.get 0
      i32.const 32
      i32.sub
      local.tee 2
      global.set 0
      
      block  ;; label = @2
        block  ;; label = @3
          local.get 0
          i32.load
          local.tee 3
          i32.const -1
          i32.eq
          br_if 0 (;@3;)
          
          ;; Calculate new capacity (double or +1)
          i32.const 4
          local.get 3
          i32.const 1
          i32.shl
          local.tee 4
          local.get 3
          i32.const 1
          i32.add
          local.tee 5
          local.get 4
          local.get 5
          i32.gt_u
          select
          local.tee 4
          local.get 4
          i32.const 4
          i32.le_u
          select
          local.tee 4
          i64.extend_i32_u
          i64.const 24
          i64.mul
          local.tee 7
          i64.const 32
          i64.shr_u
          i32.wrap_i64
          br_if 0 (;@3;)
          
          local.get 7
          i32.wrap_i64
          local.tee 5
          i32.const 2147483640
          i32.gt_u
          br_if 0 (;@3;)
          
          local.get 2
          local.get 3
          if (result i32)  ;; label = @4
            local.get 2
            local.get 3
            i32.const 24
            i32.mul
            i32.store offset=28
            local.get 2
            local.get 0
            i32.load offset=4
            i32.store offset=20
            i32.const 8
          else
            i32.const 0
          end
          i32.store offset=24
          
          local.get 2
          i32.const 8
          i32.add
          local.get 5
          local.get 2
          i32.const 20
          i32.add
          call 20
          
          local.get 2
          i32.load offset=12
          local.set 3
          local.get 2
          i32.load offset=8
          i32.eqz
          if  ;; label = @4
            local.get 0
            local.get 4
            i32.store
            local.get 0
            local.get 3
            i32.store offset=4
            br 2 (;@2;)
          end
          
          local.get 3
          i32.const -2147483647
          i32.eq
          br_if 1 (;@2;)
        end
        unreachable
      end
      
      local.get 2
      i32.const 32
      i32.add
      global.set 0
    end
    
    ;; Append lock to vector (copy 24 bytes)
    local.get 0
    local.get 6
    i32.const 1
    i32.add
    i32.store offset=8   ;; len++
    
    local.get 0
    i32.load offset=4    ;; vec.ptr
    local.get 6
    i32.const 24
    i32.mul              ;; offset = index * 24
    i32.add
    local.tee 0
    local.get 1
    i64.load
    i64.store
    local.get 0
    i32.const 8
    i32.add
    local.get 1
    i32.const 8
    i32.add
    i64.load
    i64.store
    local.get 0
    i32.const 16
    i32.add
    local.get 1
    i32.const 16
    i32.add
    i64.load
    i64.store)

  ;; Function 24: Write Vec<BalanceLock> to storage
  ;; Encodes a vector of locks and persists to storage key
  ;; Used for: set_lock, remove_lock when updating account locks
  ;; Parameters: (account_id_ptr, locks_vec_ptr, vec_len) -> void
  (func $write_locks_to_storage (;24;) (type 1) (param i32 i32 i32)
    (local i32 i32 i32 i32)
    global.get 0
    i32.const 48
    i32.sub
    local.tee 3
    global.set 0
    
    ;; Copy AccountId to build storage key
    local.get 3
    i32.const 12
    i32.add
    local.get 0
    i32.const 8
    i32.add
    i64.load align=1
    i64.store align=4
    local.get 3
    i32.const 20
    i32.add
    local.get 0
    i32.const 16
    i32.add
    i64.load align=1
    i64.store align=4
    local.get 3
    i32.const 28
    i32.add
    local.get 0
    i32.const 24
    i32.add
    i64.load align=1
    i64.store align=4
    local.get 3
    i32.const 65536      ;; Locks mapping prefix
    i32.store
    local.get 3
    local.get 0
    i64.load align=1
    i64.store offset=4 align=4
    
    ;; Initialize encoder
    local.get 3
    i64.const 16384
    i64.store offset=40 align=4
    local.get 3
    i32.const 66280
    i32.store offset=36
    
    ;; Encode storage key
    local.get 3
    local.get 3
    i32.const 36
    i32.add
    local.tee 6
    call 17
    
    block  ;; label = @1
      local.get 3
      i32.load offset=40
      local.tee 0
      local.get 3
      i32.load offset=44
      local.tee 4
      i32.lt_u
      br_if 0 (;@1;)
      
      local.get 3
      i32.load offset=36
      local.set 5
      local.get 3
      i32.const 0
      i32.store offset=44
      local.get 3
      local.get 0
      local.get 4
      i32.sub
      i32.store offset=40
      local.get 3
      local.get 4
      local.get 5
      i32.add
      i32.store offset=36
      
      ;; Encode vector length
      local.get 2
      local.get 6
      call 25
      
      ;; Encode each lock (loop)
      local.get 2
      i32.const 24
      i32.mul
      local.set 0
      loop  ;; label = @2
        local.get 0
        if  ;; label = @3
          ;; Encode lock.id (8 bytes)
          local.get 3
          i32.const 36
          i32.add
          local.tee 2
          local.get 1
          i32.const 16
          i32.add
          i32.const 8
          call 26
          
          ;; Encode lock.amount (u128)
          local.get 1
          i64.load
          local.get 1
          i32.const 8
          i32.add
          i64.load
          local.get 2
          call 27
          
          local.get 0
          i32.const 24
          i32.sub
          local.set 0
          local.get 1
          i32.const 24
          i32.add
          local.set 1
          br 1 (;@2;)
        end
      end
      
      ;; Write to storage
      local.get 3
      i32.load offset=44
      local.tee 0
      local.get 3
      i32.load offset=40
      i32.gt_u
      br_if 0 (;@1;)
      
      local.get 5
      local.get 4
      local.get 3
      i32.load offset=36
      local.get 0
      call 3
      drop
      
      local.get 3
      i32.const 48
      i32.add
      global.set 0
      return
    end
    unreachable)

  ;; ============================================================================
  ;; SCALE ENCODING PRIMITIVES
  ;; ============================================================================

  ;; Function 25: Encode Compact<u32> (variable-length integer)
  ;; SCALE compact encoding: 0-63 = 1 byte, 64-16383 = 2 bytes, etc.
  ;; Used for: Vec lengths, enum discriminants
  ;; Parameters: (value, encoder_ptr) -> void
  (func $encode_compact_u32 (;25;) (type 0) (param i32 i32)
    (local i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 2
    global.set 0
    
    block  ;; label = @1
      ;; Single-byte mode (0-63)
      local.get 0
      i32.const 63
      i32.le_u
      if  ;; label = @2
        local.get 1
        local.get 0
        i32.const 2
        i32.shl
        call 57
        br 1 (;@1;)
      end
      
      ;; Two-byte mode (64-16383)
      local.get 0
      i32.const 16383
      i32.le_u
      if  ;; label = @2
        local.get 2
        local.get 0
        i32.const 2
        i32.shl
        i32.const 1
        i32.or
        i32.store16 offset=14
        local.get 1
        local.get 2
        i32.const 14
        i32.add
        i32.const 2
        call 26
        br 1 (;@1;)
      end
      
      ;; Four-byte mode
      local.get 0
      i32.const 1073741823
      i32.le_u
      if  ;; label = @2
        local.get 0
        i32.const 2
        i32.shl
        i32.const 2
        i32.or
        local.get 1
        call 37
        br 1 (;@1;)
      end
      
      ;; Big-integer mode
      local.get 1
      i32.const 3
      call 57
      local.get 0
      local.get 1
      call 37
    end
    
    local.get 2
    i32.const 16
    i32.add
    global.set 0)

  ;; Function 26: Write bytes to encoder buffer
  ;; Appends raw bytes to the encoding buffer with bounds checking
  ;; Used for: Encoding byte arrays, AccountIds, lock IDs
  ;; Parameters: (encoder_ptr, data_ptr, data_len) -> void
  (func $encoder_write_bytes (;26;) (type 1) (param i32 i32 i32)
    (local i32 i32)
    
    block  ;; label = @1
      ;; Calculate new position
      local.get 0
      i32.load offset=8    ;; encoder.used
      local.tee 3
      local.get 2          ;; data_len
      i32.add
      local.tee 4          ;; new_used
      local.get 3
      i32.lt_u
      br_if 0 (;@1;)       ;; Overflow check
      
      local.get 4
      local.get 0
      i32.load offset=4    ;; encoder.capacity
      i32.gt_u
      br_if 0 (;@1;)       ;; Capacity check
      
      ;; Copy data
      local.get 0
      i32.load             ;; encoder.ptr
      local.get 3
      i32.add
      local.get 2
      local.get 1
      local.get 2
      call 13              ;; validate_exact_copy
      
      ;; Update used count
      local.get 0
      local.get 4
      i32.store offset=8
      return
    end
    unreachable)

  ;; Function 27: Encode u128 (Balance) value
  ;; Writes 128-bit integer in little-endian format (16 bytes)
  ;; Used for: Encoding Balance fields
  ;; Parameters: (value_low_64, value_high_64, encoder_ptr) -> void
  (func $encode_u128 (;27;) (type 9) (param i64 i64 i32)
    (local i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 3
    global.set 0
    
    ;; Store u128 on stack
    local.get 3
    local.get 1
    i64.store offset=8
    local.get 3
    local.get 0
    i64.store
    
    ;; Write 16 bytes
    local.get 2
    local.get 3
    i32.const 16
    call 26
    
    local.get 3
    i32.const 16
    i32.add
    global.set 0)

  ;; Function 28: Write AccountData to storage
  ;; Encodes account balance data and persists via seal_set_storage
  ;; Used for: Updating account state after transfers, minting, burning
  ;; Parameters: (account_id_ptr, account_data_ptr) -> void
  (func $write_account_to_storage (;28;) (type 0) (param i32 i32)
    (local i32 i32 i32 i32)
    global.get 0
    i32.const 48
    i32.sub
    local.tee 2
    global.set 0
    
    ;; Build storage key
    local.get 2
    i32.const 12
    i32.add
    local.get 0
    i32.const 8
    i32.add
    i64.load align=1
    i64.store align=4
    local.get 2
    i32.const 20
    i32.add
    local.get 0
    i32.const 16
    i32.add
    i64.load align=1
    i64.store align=4
    local.get 2
    i32.const 28
    i32.add
    local.get 0
    i32.const 24
    i32.add
    i64.load align=1
    i64.store align=4
    local.get 2
    i32.const 65540      ;; Account mapping prefix
    i32.store
    local.get 2
    local.get 0
    i64.load align=1
    i64.store offset=4 align=4
    
    ;; Initialize encoder
    local.get 2
    i64.const 16384
    i64.store offset=40 align=4
    local.get 2
    i32.const 66280
    i32.store offset=36
    
    ;; Encode key
    local.get 2
    local.get 2
    i32.const 36
    i32.add
    local.tee 4
    call 17
    
    block  ;; label = @1
      local.get 2
      i32.load offset=40
      local.tee 5
      local.get 2
      i32.load offset=44
      local.tee 0
      i32.lt_u
      br_if 0 (;@1;)
      
      local.get 2
      i32.load offset=36
      local.set 3
      local.get 2
      i32.const 0
      i32.store offset=44
      local.get 2
      local.get 5
      local.get 0
      i32.sub
      i32.store offset=40
      local.get 2
      local.get 0
      local.get 3
      i32.add
      i32.store offset=36
      
      ;; Encode AccountData (3 × u128 = 48 bytes)
      local.get 1
      local.get 4
      call 29
      
      ;; Write to storage
      local.get 2
      i32.load offset=44
      local.tee 1
      local.get 2
      i32.load offset=40
      i32.gt_u
      br_if 0 (;@1;)
      
      local.get 3
      local.get 0
      local.get 2
      i32.load offset=36
      local.get 1
      call 3
      drop
      
      local.get 2
      i32.const 48
      i32.add
      global.set 0
      return
    end
    unreachable)

  ;; Function 29: Encode 3 u128 values (AccountData fields)
  ;; Writes free, reserved, frozen balances to encoder
  ;; Used for: AccountData encoding
  ;; Parameters: (account_data_ptr, encoder_ptr) -> void
  (func $encode_account_data (;29;) (type 0) (param i32 i32)
    ;; Encode free balance
    local.get 0
    i64.load
    local.get 0
    i32.const 8
    i32.add
    i64.load
    local.get 1
    call 27
    
    ;; Encode reserved balance
    local.get 0
    i64.load offset=16
    local.get 0
    i32.const 24
    i32.add
    i64.load
    local.get 1
    call 27
    
    ;; Encode frozen balance
    local.get 0
    i64.load offset=32
    local.get 0
    i32.const 40
    i32.add
    i64.load
    local.get 1
    call 27)

  ;; Function 30: Encode event topic (AccountId) to encoder
  ;; Encodes AccountId and hashes it to create event topic
  ;; Used for: Event emission - creating indexed topics for Transfer, Endowed, etc.
  ;; Parameters: (buffer_state_ptr, account_id_ptr) -> void
  ;; Process: AccountId -> SCALE encode -> BLAKE2-256 hash -> append to buffer
  (func $encode_event_topic (;30;) (type 0) (param i32 i32)
    (local i32 i32 i32 i32 i32)
    global.get 0
    i32.const 48
    i32.sub
    local.tee 2          ;; Local 2: stack frame
    global.set 0
    
    block  ;; label = @1
      ;; Extract remaining buffer space from encoder
      local.get 0
      i32.load offset=4    ;; buffer.capacity
      local.tee 4
      local.get 0
      i32.load offset=8    ;; buffer.used
      local.tee 3
      i32.lt_u
      br_if 0 (;@1;)      ;; Exit if used > capacity (error state)
      
      ;; Get buffer pointer
      local.get 0
      i32.load             ;; buffer.ptr
      local.set 5
      
      ;; Initialize temporary buffer state at offset 4
      local.get 2
      i32.const 0
      i32.store offset=12  ;; temp.used = 0
      local.get 2
      local.get 4
      local.get 3
      i32.sub
      local.tee 4          ;; remaining = capacity - used
      i32.store offset=8   ;; temp.capacity = remaining
      local.get 2
      local.get 3
      local.get 5
      i32.add
      local.tee 5          ;; temp.ptr = ptr + used
      i32.store offset=4
      
      ;; Encode the AccountId (32 bytes) into temporary buffer
      local.get 1          ;; account_id_ptr
      local.get 2
      i32.const 4
      i32.add
      local.tee 6          ;; temp buffer state ptr
      call 31              ;; encode_account_id
      
      ;; Check if encoding succeeded
      local.get 2
      i32.load offset=12   ;; bytes_written
      local.tee 1
      local.get 2
      i32.load offset=8    ;; capacity
      i32.gt_u
      br_if 0 (;@1;)
      
      ;; Hash the encoded AccountId to create 32-byte topic
      local.get 6
      local.get 2
      i32.load offset=4    ;; encoded data ptr
      local.get 1          ;; encoded data len (should be 32)
      call 32              ;; encode_storage_key_hash (BLAKE2-256)
      
      ;; Prepare to append hash to original encoder buffer
      local.get 2
      i32.const 0
      i32.store offset=44  ;; new temp.used = 0
      local.get 2
      local.get 4          ;; remaining capacity
      i32.store offset=40
      local.get 2
      local.get 5          ;; buffer position after first encoding
      i32.store offset=36
      
      ;; Write the 32-byte hash to original buffer
      local.get 6
      local.get 2
      i32.const 36
      i32.add
      call 31              ;; Write hash (32 bytes)
      
      ;; Calculate new used count for original buffer
      local.get 3          ;; old_used
      local.get 2
      i32.load offset=44   ;; bytes_written (should be 32)
      i32.add
      local.tee 1          ;; new_used
      local.get 3
      i32.lt_u
      br_if 0 (;@1;)      ;; Overflow check
      
      ;; Update original buffer's used count
      local.get 0
      local.get 1
      i32.store offset=8   ;; buffer.used = old_used + 32
      
      local.get 2
      i32.const 48
      i32.add
      global.set 0
      return
    end
    unreachable)

  ;; Function 31: Encode fixed 32-byte array (AccountId)
  ;; Writes AccountId without length prefix
  ;; Parameters: (account_id_ptr, encoder_ptr) -> void
  (func $encode_account_id (;31;) (type 0) (param i32 i32)
    local.get 1
    local.get 0
    i32.const 32
    call 26)

  ;; Function 32: Encode and hash value to storage key
  ;; Creates deterministic storage key using BLAKE2-256
  ;; Parameters: (encoder_ptr, key_data_ptr, key_len) -> void
  (func $encode_storage_key_hash (;32;) (type 1) (param i32 i32 i32)
    (local i32)
    global.get 0
    i32.const -64
    i32.add
    local.tee 3
    global.set 0
    
    ;; Prepare hash output buffer
    local.get 3
    i32.const 24
    i32.add
    i64.const 0
    i64.store
    local.get 3
    i32.const 16
    i32.add
    i64.const 0
    i64.store
    local.get 3
    i32.const 8
    i32.add
    i64.const 0
    i64.store
    local.get 3
    i64.const 0
    i64.store
    
    block  ;; label = @1
      ;; If len >= 33, hash it
      local.get 2
      i32.const 33
      i32.ge_u
      if  ;; label = @2
        ;; Hash the key
        local.get 3
        i32.const 56
        i32.add
        i64.const 0
        i64.store
        local.get 3
        i32.const 48
        i32.add
        i64.const 0
        i64.store
        local.get 3
        i32.const 40
        i32.add
        i64.const 0
        i64.store
        local.get 3
        i64.const 0
        i64.store offset=32
        
        local.get 1
        local.get 2
        local.get 3
        i32.const 32
        i32.add
        local.tee 1
        call 8           ;; seal_hash_blake2_256
        
        ;; Copy hash to output buffer
        local.get 3
        i32.const 32
        local.get 1
        i32.const 32
        call 13
        br 1 (;@1;)
      end
      
      ;; Direct copy if small enough
      local.get 3
      local.get 2
      local.get 1
      local.get 2
      call 13
    end
    
    ;; Write 32-byte result to encoder
    local.get 0
    local.get 3
    i64.load
    i64.store align=1
    local.get 0
    i32.const 24
    i32.add
    local.get 3
    i32.const 24
    i32.add
    i64.load
    i64.store align=1
    local.get 0
    i32.const 16
    i32.add
    local.get 3
    i32.const 16
    i32.add
    i64.load
    i64.store align=1
    local.get 0
    i32.const 8
    i32.add
    local.get 3
    i32.const 8
    i32.add
    i64.load
    i64.store align=1
    
    local.get 3
    i32.const -64
    i32.sub
    global.set 0)

  ;; Function 33: Encode None variant for Option<T>
  ;; Encodes discriminant byte and empty AccountId
  ;; Used for: Encoding None variants in event emission
  ;; Parameters: (encoder_ptr) -> void
  (func $encode_option_none (;33;) (type 4) (param i32)
    (local i32 i32 i32 i32 i32 i32 i32)
    global.get 0
    i32.const 48
    i32.sub
    local.tee 1
    global.set 0
    
    block  ;; label = @1
      local.get 0
      i32.load offset=4    ;; encoder.capacity
      local.tee 3
      local.get 0
      i32.load offset=8    ;; encoder.used
      local.tee 2
      i32.lt_u
      br_if 0 (;@1;)
      
      local.get 0
      i32.load             ;; encoder.ptr
      local.set 4
      local.get 1
      i32.const 0
      i32.store offset=12
      local.get 1
      local.get 3
      local.get 2
      i32.sub
      local.tee 3
      i32.store offset=8
      local.get 1
      local.get 2
      local.get 4
      i32.add
      local.tee 4
      i32.store offset=4
      
      ;; Write discriminant byte (0)
      local.get 1
      i32.const 0
      i32.store8 offset=36
      local.get 1
      i32.const 4
      i32.add
      local.tee 5
      local.get 1
      i32.const 36
      i32.add
      local.tee 6
      i32.const 1
      call 26
      
      local.get 1
      i32.load offset=12
      local.tee 7
      local.get 1
      i32.load offset=8
      i32.gt_u
      br_if 0 (;@1;)
      
      ;; Hash and encode empty AccountId
      local.get 5
      local.get 1
      i32.load offset=4
      local.get 7
      call 32
      
      local.get 1
      i32.const 0
      i32.store offset=44
      local.get 1
      local.get 3
      i32.store offset=40
      local.get 1
      local.get 4
      i32.store offset=36
      
      local.get 5
      local.get 6
      call 31
      
      local.get 2
      local.get 2
      local.get 1
      i32.load offset=44
      i32.add
      local.tee 2
      i32.gt_u
      br_if 0 (;@1;)
      
      local.get 0
      local.get 2
      i32.store offset=8
      
      local.get 1
      i32.const 48
      i32.add
      global.set 0
      return
    end
    unreachable)

  ;; Function 34: Encode Compact<u32> length prefix for vectors
  ;; Wrapper around compact encoding specifically for Vec lengths
  ;; Used for: Vec<BalanceLock>, Vec<Event> serialization
  ;; Parameters: (vec_len, encoder_ptr) -> void
  (func $encode_vec_length (;34;) (type 0) (param i32 i32)
    (local i32 i32 i32 i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 2
    global.set 0
    
    block  ;; label = @1
      ;; Get current encoder position for bounds checking
      local.get 0
      i32.load offset=4    ;; encoder.capacity
      local.tee 4
      local.get 0
      i32.load offset=8    ;; encoder.used
      local.tee 3
      i32.lt_u
      br_if 0 (;@1;)
      
      ;; Save buffer state
      local.get 0
      i32.load             ;; encoder.ptr
      local.set 5
      local.get 2
      i32.const 0
      i32.store offset=12  ;; temp.used = 0
      local.get 2
      local.get 4
      local.get 3
      i32.sub
      i32.store offset=8   ;; temp.capacity = remaining
      local.get 2
      local.get 3
      local.get 5
      i32.add
      i32.store offset=4   ;; temp.ptr = ptr + used
      
      ;; Encode the length as Compact<u32>
      local.get 1          ;; vec_len
      local.get 2
      i32.const 4
      i32.add
      call 25              ;; encode_compact_u32
      
      ;; Update encoder used count
      local.get 3          ;; old_used
      local.get 2
      i32.load offset=12   ;; bytes written by compact encoding
      i32.add
      local.tee 1          ;; new_used
      local.get 3
      i32.lt_u
      br_if 0 (;@1;)      ;; Overflow check
      
      local.get 0
      local.get 1
      i32.store offset=8   ;; encoder.used = new_used
      
      local.get 2
      i32.const 16
      i32.add
      global.set 0
      return
    end
    unreachable)

  ;; Function 35: Read 32-byte AccountId from buffer
  ;; Reads a fixed-size AccountId with success/EOF flag
  ;; Used for: Decoding AccountId parameters in messages
  ;; Parameters: (result_ptr, reader_ptr) -> void
  ;; Result: Stores (success_flag, AccountId[32]) at result_ptr
  (func $decode_account_id (;35;) (type 0) (param i32 i32)
    (local i32 i32 i32 i32)
    global.get 0
    i32.const 32
    i32.sub
    local.tee 2
    global.set 0
    
    ;; Initialize 32-byte buffer
    local.get 2
    i32.const 24
    i32.add
    local.tee 3
    i64.const 0
    i64.store
    local.get 2
    i32.const 16
    i32.add
    local.tee 4
    i64.const 0
    i64.store
    local.get 2
    i32.const 8
    i32.add
    local.tee 5
    i64.const 0
    i64.store
    local.get 2
    i64.const 0
    i64.store
    
    ;; Try to read 32 bytes
    local.get 0
    block (result i32)  ;; label = @1
      local.get 1
      local.get 2
      i32.const 32
      call 15
      i32.eqz
      if  ;; label = @2
        ;; Success: copy AccountId to result
        local.get 0
        local.get 2
        i64.load
        i64.store offset=1 align=1
        local.get 0
        i32.const 25
        i32.add
        local.get 3
        i64.load
        i64.store align=1
        local.get 0
        i32.const 17
        i32.add
        local.get 4
        i64.load
        i64.store align=1
        local.get 0
        i32.const 9
        i32.add
        local.get 5
        i64.load
        i64.store align=1
        i32.const 0        ;; success flag
        br 1 (;@1;)
      end
      i32.const 1          ;; error/EOF flag
    end
    i32.store8             ;; Store flag at offset 0
    
    local.get 2
    i32.const 32
    i32.add
    global.set 0)

  ;; Function 36: Read and decode Option<AccountId> with full structure
  ;; Decodes complex Option structure with nested data
  ;; Used for: Decoding optional account parameters in complex messages
  ;; Parameters: (result_ptr, reader_ptr) -> void
  ;; Result: Stores complete decoded structure (56 bytes) at result_ptr
  (func $decode_option_account_full (;36;) (type 0) (param i32 i32)
    (local i32)
    global.get 0
    i32.const -64
    i32.add
    local.tee 2
    global.set 0
    
    ;; Read AccountId (sets success flag at offset 7)
    local.get 2
    i32.const 7
    i32.add
    local.get 1
    call 35              ;; decode_account_id
    
    block  ;; label = @1
      local.get 2
      i32.load8_u offset=7  ;; Check success flag
      i32.eqz
      if  ;; label = @2
        ;; Read following u128 value
        local.get 2
        i32.const 40
        i32.add
        local.get 1
        call 22            ;; decode_u128
        
        local.get 2
        i32.load offset=40
        i32.eqz
        if  ;; label = @3
          ;; Success: copy all decoded data to result
          local.get 0
          local.get 2
          i64.load offset=48
          i64.store offset=40
          local.get 0
          local.get 2
          i64.load offset=8 align=1
          i64.store offset=8 align=1
          local.get 0
          i64.const 0
          i64.store            ;; success marker
          local.get 0
          local.get 2
          i32.const 56
          i32.add
          i64.load
          i64.store offset=48
          local.get 0
          i32.const 16
          i32.add
          local.get 2
          i32.const 16
          i32.add
          i64.load align=1
          i64.store align=1
          local.get 0
          i32.const 24
          i32.add
          local.get 2
          i32.const 24
          i32.add
          i64.load align=1
          i64.store align=1
          local.get 0
          i32.const 32
          i32.add
          local.get 2
          i32.const 32
          i32.add
          i64.load align=1
          i64.store align=1
          br 2 (;@1;)
        end
        ;; Decode error
        local.get 0
        i64.const 1
        i64.store
        br 1 (;@1;)
      end
      ;; Read error
      local.get 0
      i64.const 1
      i64.store
    end
    
    local.get 2
    i32.const -64
    i32.sub
    global.set 0)

  ;; Function 37: Encode u32 value to encoder
  ;; Writes 4-byte integer in little-endian format
  ;; Used for: Encoding counters, discriminants, Mapping prefixes
  ;; Parameters: (value_u32, encoder_ptr) -> void
  (func $encode_u32 (;37;) (type 0) (param i32 i32)
    (local i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 2
    global.set 0
    
    ;; Store u32 on stack
    local.get 2
    local.get 0
    i32.store offset=12
    
    ;; Write 4 bytes to encoder
    local.get 1
    local.get 2
    i32.const 12
    i32.add
    i32.const 4
    call 26
    
    local.get 2
    i32.const 16
    i32.add
    global.set 0)

  ;; Function 38: Emit Transfer event
  ;; Constructs and emits Transfer event
  ;; Parameters: (transfer_event_ptr) -> void
  (func $emit_transfer_event (;38;) (type 4) (param i32)
    (local i32 i32 i32 i32)
    global.get 0
    i32.const 80
    i32.sub
    local.tee 1
    global.set 0
    
    ;; Copy event data
    local.get 1
    local.get 0
    i32.const 48
    call 9
    local.tee 0
    i64.const 16384
    i64.store offset=56 align=4
    local.get 0
    i32.const 66280
    i32.store offset=52
    
    ;; Encode event type
    local.get 0
    local.get 0
    i32.store offset=64
    local.get 0
    i32.const 52
    i32.add
    local.tee 1
    i32.const 2
    call 34
    local.get 1
    i32.const 65610
    call 30
    
    ;; Build event buffer
    local.get 0
    i32.const 68
    i32.add
    local.tee 3
    local.get 1
    local.get 0
    i32.const -64
    i32.sub
    call 39
    
    block  ;; label = @1
      local.get 0
      i32.load offset=72
      local.tee 2
      local.get 0
      i32.load offset=76
      local.tee 1
      i32.lt_u
      br_if 0 (;@1;)
      
      local.get 0
      i32.load offset=68
      local.set 4
      local.get 0
      i32.const 0
      i32.store offset=76
      local.get 0
      local.get 2
      local.get 1
      i32.sub
      i32.store offset=72
      local.get 0
      local.get 1
      local.get 4
      i32.add
      i32.store offset=68
      
      ;; Encode event fields
      local.get 0
      local.get 3
      call 31
      local.get 0
      i64.load offset=32
      local.get 0
      i32.const 40
      i32.add
      i64.load
      local.get 3
      call 27
      
      ;; Emit
      local.get 0
      i32.load offset=76
      local.tee 2
      local.get 0
      i32.load offset=72
      i32.gt_u
      br_if 0 (;@1;)
      
      local.get 4
      local.get 1
      local.get 0
      i32.load offset=68
      local.get 2
      call 2
      
      local.get 0
      i32.const 80
      i32.add
      global.set 0
      return
    end
    unreachable)

  ;; Function 39: Build event topics buffer
  ;; Encodes AccountId, hashes it, appends to buffer (or writes None)
  ;; Parameters: (result_ptr, encoder_ptr, account_id_ptr) -> void
  (func $build_event_topic_hash (;39;) (type 1) (param i32 i32 i32)
    (local i32 i32 i32 i32 i32)
    global.get 0
    i32.const 48
    i32.sub
    local.tee 3
    global.set 0
    
    block  ;; label = @1
      block  ;; label = @2
        local.get 2
        if  ;; label = @3
          local.get 1
          i32.load offset=4
          local.tee 5
          local.get 1
          i32.load offset=8
          local.tee 4
          i32.lt_u
          br_if 2 (;@1;)
          
          local.get 1
          i32.load
          local.set 6
          local.get 3
          i32.const 0
          i32.store offset=12
          local.get 3
          local.get 5
          local.get 4
          i32.sub
          local.tee 5
          i32.store offset=8
          local.get 3
          local.get 4
          local.get 6
          i32.add
          local.tee 6
          i32.store offset=4
          
          local.get 2
          i32.load
          local.get 3
          i32.const 4
          i32.add
          local.tee 7
          call 31
          
          local.get 3
          i32.load offset=12
          local.tee 2
          local.get 3
          i32.load offset=8
          i32.gt_u
          br_if 2 (;@1;)
          
          local.get 7
          local.get 3
          i32.load offset=4
          local.get 2
          call 32
          
          local.get 3
          i32.const 0
          i32.store offset=44
          local.get 3
          local.get 5
          i32.store offset=40
          local.get 3
          local.get 6
          i32.store offset=36
          
          local.get 7
          local.get 3
          i32.const 36
          i32.add
          call 31
          
          local.get 4
          local.get 3
          i32.load offset=44
          i32.add
          local.tee 2
          local.get 4
          i32.lt_u
          br_if 2 (;@1;)
          local.get 1
          local.get 2
          i32.store offset=8
          br 1 (;@2;)
        end
        
        ;; None path
        local.get 1
        call 33
      end
      local.get 0
      local.get 1
      i64.load align=4
      i64.store align=4
      local.get 0
      i32.const 8
      i32.add
      local.get 1
      i32.const 8
      i32.add
      i32.load
      i32.store
      
      local.get 3
      i32.const 48
      i32.add
      global.set 0
      return
    end
    unreachable)

  ;; Function 40: Emit complex event (Transfer with 3 topics)
  ;; Constructs and emits event with 3 indexed topics
  ;; Parameters: (event_struct_ptr) -> void
  (func $emit_event_3_topics (;40;) (type 4) (param i32)
    (local i32 i32 i32)
    global.get 0
    i32.const 112
    i32.sub
    local.tee 1
    global.set 0
    
    ;; Copy event structure (88 bytes)
    local.get 1
    local.get 0
    i32.const 88
    call 9
    local.tee 0
    i64.const 16384
    i64.store offset=92 align=4
    local.get 0
    i32.const 66280
    i32.store offset=88
    
    ;; Encode topic count (3)
    local.get 0
    i32.const 88
    i32.add
    local.tee 1
    i32.const 3
    call 34
    
    ;; Encode topic 1 (event signature)
    local.get 1
    i32.const 65577
    call 30
    
    block  ;; label = @1
      ;; Check if topic 2 should be Some or None
      local.get 0
      i32.load8_u offset=16
      i32.const 1
      i32.eq
      if  ;; label = @2
        local.get 1
        local.get 0
        i32.const 17
        i32.add
        call 30
        br 1 (;@1;)
      end
      local.get 0
      i32.const 88
      i32.add
      call 33
    end
    
    block  ;; label = @1
      ;; Check if topic 3 should be Some or None
      local.get 0
      i32.load8_u offset=49
      i32.const 1
      i32.eq
      if  ;; label = @2
        local.get 0
        i32.const 88
        i32.add
        local.get 0
        i32.const 50
        i32.add
        call 30
        br 1 (;@1;)
      end
      local.get 0
      i32.const 88
      i32.add
      call 33
    end
    
    block  ;; label = @1
      local.get 0
      i32.load offset=92
      local.tee 2
      local.get 0
      i32.load offset=96
      local.tee 1
      i32.lt_u
      br_if 0 (;@1;)
      
      local.get 0
      i32.load offset=88
      local.set 3
      local.get 0
      i32.const 0
      i32.store offset=108
      local.get 0
      local.get 2
      local.get 1
      i32.sub
      i32.store offset=104
      local.get 0
      local.get 1
      local.get 3
      i32.add
      i32.store offset=100
      
      ;; Encode event data fields
      local.get 0
      i32.const 16
      i32.add
      local.get 0
      i32.const 100
      i32.add
      local.tee 2
      call 41
      local.get 0
      i32.const 49
      i32.add
      local.get 2
      call 41
      local.get 0
      i64.load
      local.get 0
      i32.const 8
      i32.add
      i64.load
      local.get 2
      call 27
      
      local.get 0
      i32.load offset=108
      local.tee 2
      local.get 0
      i32.load offset=104
      i32.gt_u
      br_if 0 (;@1;)
      
      ;; Emit event
      local.get 3
      local.get 1
      local.get 0
      i32.load offset=100
      local.get 2
      call 2
      
      local.get 0
      i32.const 112
      i32.add
      global.set 0
      return
    end
    unreachable)

  ;; Function 41: Encode Option<AccountId>
  ;; Writes Option discriminant + AccountId if Some
  ;; Parameters: (option_ptr, encoder_ptr) -> void
  (func $encode_option_account_id (;41;) (type 0) (param i32 i32)
    local.get 0
    i32.load8_u
    i32.eqz
    if  ;; label = @1
      local.get 1
      i32.const 0
      call 57
      return
    end
    
    local.get 1
    i32.const 1
    call 57
    local.get 0
    i32.const 1
    i32.add
    local.get 1
    call 31)

  ;; Function 42: Get caller AccountId from host
  ;; Retrieves the AccountId of the contract caller
  ;; Parameters: (output_buffer_ptr) -> void
  (func $get_caller_account_id (;42;) (type 4) (param i32)
    (local i32 i32 i32)
    global.get 0
    i32.const 48
    i32.sub
    local.tee 1
    global.set 0
    
    ;; Call seal_caller
    local.get 1
    i32.const 16384
    i32.store offset=4
    i32.const 66280
    local.get 1
    i32.const 4
    i32.add
    local.tee 2
    call 6
    
    block  ;; label = @1
      ;; Validate size
      local.get 1
      i32.load offset=4
      local.tee 3
      i32.const 16385
      i32.ge_u
      br_if 0 (;@1;)
      
      ;; Copy to output
      local.get 1
      local.get 3
      i32.store offset=44
      local.get 1
      i32.const 66280
      i32.store offset=40
      local.get 2
      local.get 1
      i32.const 40
      i32.add
      call 35
      
      local.get 1
      i32.load8_u offset=4
      i32.const 1
      i32.eq
      br_if 0 (;@1;)
      
      ;; Copy AccountId
      local.get 0
      local.get 1
      i64.load offset=6 align=1
      i64.store offset=1 align=1
      local.get 0
      i32.const 9
      i32.add
      local.get 1
      i32.const 14
      i32.add
      i64.load align=1
      i64.store align=1
      local.get 0
      i32.const 17
      i32.add
      local.get 1
      i32.const 22
      i32.add
      i64.load align=1
      i64.store align=1
      local.get 0
      i32.const 24
      i32.add
      local.get 1
      i32.const 29
      i32.add
      i64.load align=1
      i64.store align=1
      local.get 0
      local.get 1
      i32.load8_u offset=5
      i32.store8
      
      local.get 1
      i32.const 48
      i32.add
      global.set 0
      return
    end
    unreachable)

  ;; Function 43: Check if contract was paid
  ;; Reads value_transferred and checks if non-zero
  ;; Returns: 5 if no value, 4 if value sent
  (func $check_value_transferred (;43;) (type 10) (result i32)
    (local i32 i32 i64 i64)
    global.get 0
    i32.const 32
    i32.sub
    local.tee 0
    global.set 0
    
    ;; Read transferred value
    local.get 0
    i32.const 16
    i32.add
    local.tee 1
    i64.const 0
    i64.store
    local.get 0
    i64.const 0
    i64.store offset=8
    
    local.get 0
    i32.const 16
    i32.store offset=28
    local.get 0
    i32.const 8
    i32.add
    local.get 0
    i32.const 28
    i32.add
    call 7
    
    local.get 0
    i32.load offset=28
    i32.const 17
    i32.ge_u
    if  ;; label = @1
      unreachable
    end
    
    ;; Check if zero
    local.get 1
    i64.load
    local.set 2
    local.get 0
    i64.load offset=8
    local.set 3
    
    local.get 0
    i32.const 32
    i32.add
    global.set 0
    
    i32.const 5
    i32.const 4
    local.get 2
    local.get 3
    i64.or
    i64.eqz
    select)

  ;; Function 44: Compare two AccountIds (not equal)
  ;; Wrapper around memcmp for AccountId inequality
  ;; Parameters: (account_id1, account_id2) -> bool
  ;; Returns: 1 if different, 0 if equal
  (func $account_id_ne (;44;) (type 3) (param i32 i32) (result i32)
    local.get 0
    local.get 1
    call 45
    i32.const 1
    i32.xor)

  ;; Function 45: Compare two AccountIds (equal)
  ;; Wrapper around memcmp for AccountId equality
  ;; Parameters: (account_id1, account_id2) -> bool
  ;; Returns: 1 if equal, 0 if different
  (func $account_id_eq (;45;) (type 3) (param i32 i32) (result i32)
    local.get 0
    local.get 1
    i32.const 32
    call 12
    i32.eqz)

  ;; Function 46: Read AccountData from storage (internal helper)
  ;; Loads account balance data from contract storage, returns zeroed data if not found
  ;; Used for: All balance queries and modifications
  ;; Parameters: (result_ptr, account_id_ptr) -> void
  ;; Result: Writes 48-byte AccountData struct to result_ptr
  (func $read_account_from_storage (;46;) (type 0) (param i32 i32)
    (local i32 i32 i32 i32 i64 i64 i64 i64 i64)
    global.get 0
    i32.const 80
    i32.sub
    local.tee 2          ;; Allocate 80-byte stack frame
    global.set 0
    
    ;; Build storage key: copy AccountId (32 bytes) to stack at offset 16-48
    local.get 2
    i32.const 24
    i32.add
    local.get 1
    i32.const 8
    i32.add
    i64.load align=1
    i64.store align=4    ;; Copy bytes 8-15 of AccountId
    local.get 2
    i32.const 32
    i32.add
    local.get 1
    i32.const 16
    i32.add
    i64.load align=1
    i64.store align=4    ;; Copy bytes 16-23 of AccountId
    local.get 2
    i32.const 40
    i32.add
    local.get 1
    i32.const 24
    i32.add
    i64.load align=1
    i64.store align=4    ;; Copy bytes 24-31 of AccountId
    
    ;; Set Mapping prefix for accounts at offset 12
    local.get 2
    i32.const 65540      ;; Accounts mapping prefix
    i32.store offset=12
    local.get 2
    local.get 1
    i64.load align=1
    i64.store offset=16 align=4 ;; Copy bytes 0-7 of AccountId
    
    ;; Initialize encoder for storage key at offset 56
    local.get 2
    i64.const 16384      ;; capacity = 16384
    i64.store offset=60 align=4
    local.get 2
    i32.const 66280      ;; Global encoder buffer
    i32.store offset=56
    
    ;; Encode storage key (Mapping prefix + AccountId hash)
    local.get 2
    i32.const 12
    i32.add
    local.get 2
    i32.const 56
    i32.add
    local.tee 4          ;; Local 4: encoder ptr
    call 17              ;; encode_mapping_key
    
    block  ;; label = @1
      block  ;; label = @2
        block  ;; label = @3
          ;; Validate encoder state
          local.get 2
          i32.load offset=60   ;; encoder.capacity
          local.tee 3
          local.get 2
          i32.load offset=64   ;; encoder.used
          local.tee 1
          i32.lt_u
          br_if 0 (;@3;)
          
          local.get 2
          i32.load offset=56   ;; encoder.ptr
          local.set 5
          
          ;; Update encoder for seal_get_storage call
          local.get 2
          local.get 3
          local.get 1
          i32.sub
          local.tee 3          ;; remaining capacity
          i32.store offset=56
          
          ;; Call seal_get_storage
          local.get 5          ;; key_ptr
          local.get 1          ;; key_len
          local.get 1
          local.get 5
          i32.add
          local.tee 5          ;; value_ptr (after key in buffer)
          local.get 4          ;; value_len_ptr
          call 0               ;; seal_get_storage
          local.set 1
          
          ;; Validate result
          local.get 3
          local.get 2
          i32.load offset=56   ;; actual bytes written
          local.tee 3
          i32.lt_u
          local.get 1
          i32.const 15
          i32.ge_u
          i32.or
          br_if 0 (;@3;)
          
          ;; Decode result code
          local.get 1
          i32.const 65906      ;; Result code lookup table
          i32.add
          i32.load8_u
          local.tee 1
          i32.const 3
          i32.eq
          br_if 1 (;@2;)      ;; Jump to KeyNotFound handler
          
          local.get 1
          i32.const 16
          i32.ne
          br_if 0 (;@3;)      ;; Exit if not Success
          
          ;; Success: prepare to decode AccountData
          local.get 2
          local.get 3
          i32.store offset=52
          local.get 2
          local.get 5
          i32.store offset=48
          
          ;; Decode first u128 (free balance)
          local.get 4
          local.get 2
          i32.const 48
          i32.add
          local.tee 3
          call 22
          local.get 2
          i32.load offset=56
          br_if 0 (;@3;)
          
          local.get 2
          i32.const 72
          i32.add
          local.tee 1
          i64.load
          local.set 6        ;; free (high 64)
          local.get 2
          i64.load offset=64
          local.set 7        ;; free (low 64)
          
          ;; Decode second u128 (reserved balance)
          local.get 4
          local.get 3
          call 22
          local.get 2
          i32.load offset=56
          br_if 0 (;@3;)
          
          local.get 1
          i64.load
          local.set 8        ;; reserved (high 64)
          local.get 2
          i64.load offset=64
          local.set 9        ;; reserved (low 64)
          
          ;; Decode third u128 (frozen balance)
          local.get 4
          local.get 3
          call 22
          local.get 2
          i32.load offset=56
          br_if 0 (;@3;)
          
          ;; Validate all data consumed
          local.get 2
          i32.load offset=52
          br_if 0 (;@3;)
          
          ;; Load frozen balance
          local.get 2
          i64.load offset=64
          local.set 10       ;; frozen (low 64)
          
          ;; Store all fields in result (48 bytes total)
          local.get 0
          local.get 1
          i64.load
          i64.store offset=40  ;; frozen (high 64)
          local.get 0
          local.get 10
          i64.store offset=32  ;; frozen (low 64)
          local.get 0
          local.get 8
          i64.store offset=24  ;; reserved (high 64)
          local.get 0
          local.get 9
          i64.store offset=16  ;; reserved (low 64)
          local.get 0
          local.get 6
          i64.store offset=8   ;; free (high 64)
          local.get 0
          local.get 7
          i64.store            ;; free (low 64)
          br 2 (;@1;)
        end
        unreachable
      end
      
      ;; KeyNotFound path: return zeroed AccountData
      local.get 0
      i32.const 0
      i32.const 48
      call 11            ;; memset to zero
      drop
    end
    
    local.get 2
    i32.const 80
    i32.add
    global.set 0)

  ;; Function 47: Calculate reducible balance
  ;; Computes maximum balance that can be reduced
  ;; Parameters: (result_ptr, amount_low, amount_high, account_data_ptr, preserve_flag) -> void
  (func $calculate_reducible_balance (;47;) (type 11) (param i32 i64 i64 i32 i32)
    (local i64 i64 i64 i64 i32)
    global.get 0
    i32.const 48
    i32.sub
    local.tee 9
    global.set 0
    
    ;; Load account data
    local.get 9
    local.get 3
    call 46
    
    ;; Calculate free - frozen
    local.get 0
    i64.const 0
    i64.const 0
    local.get 9
    i32.const 8
    i32.add
    i64.load
    local.tee 6
    local.get 9
    i32.const 40
    i32.add
    i64.load
    i64.sub
    local.get 9
    i64.load
    local.tee 5
    local.get 9
    i64.load offset=32
    local.tee 8
    i64.lt_u
    i64.extend_i32_u
    i64.sub
    local.tee 7
    local.get 5
    local.get 5
    local.get 8
    i64.sub
    local.tee 5
    i64.lt_u
    local.get 6
    local.get 7
    i64.lt_u
    local.get 6
    local.get 7
    i64.eq
    select
    local.tee 3
    select
    local.tee 6
    local.get 2
    i64.sub
    i64.const 0
    local.get 5
    local.get 3
    select
    local.tee 2
    local.get 1
    i64.lt_u
    i64.extend_i32_u
    i64.sub
    local.tee 5
    local.get 2
    local.get 1
    i64.sub
    local.tee 1
    local.get 2
    i64.gt_u
    local.get 5
    local.get 6
    i64.gt_u
    local.get 5
    local.get 6
    i64.eq
    select
    local.tee 3
    select
    local.get 6
    local.get 4
    i32.const 255
    i32.and
    local.tee 4
    select
    i64.store offset=8
    
    local.get 0
    i64.const 0
    local.get 1
    local.get 3
    select
    local.get 2
    local.get 4
    select
    i64.store
    
    local.get 9
    i32.const 48
    i32.add
    global.set 0)

  ;; Function 48: Read 4-byte selector from input
  ;; Reads message selector (4 bytes)
  ;; Parameters: (reader_ptr, output_ptr) -> error_flag
  (func $read_selector (;48;) (type 3) (param i32 i32) (result i32)
    ;; Zero output
    local.get 1
    i32.const 0
    i32.store align=1
    ;; Read 4 bytes
    local.get 0
    local.get 1
    i32.const 4
    call 15)

  ;; Function 49: Encode Result and return
  ;; Encodes Result<(), Error> and calls seal_return
  ;; Parameters: (return_value_ptr, error_discriminant) -> never
  (func $encode_and_return_result (;49;) (type 0) (param i32 i32)
    (local i32)
    ;; Prepare return buffer
    i32.const 66280
    i32.const 0
    i32.store8
    
    i32.const 2
    local.set 2
    i32.const 66281
    local.get 1
    i32.const 255
    i32.and
    i32.const 7
    i32.ne
    if (result i32)  ;; label = @1
      i32.const 66282
      local.get 1
      i32.store8
      i32.const 3
      local.set 2
      i32.const 1
    else
      i32.const 0
    end
    i32.store8
    
    local.get 0
    local.get 2
    call 55
    unreachable)

  ;; Function 50: Return u128 value to caller
  ;; Encodes Result<u128> and returns
  ;; Parameters: (value_low, value_high) -> never
  (func $return_u128_result (;50;) (type 12) (param i64 i64)
    (local i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 2
    global.set 0
    
    ;; Encode Result::Ok + u128
    local.get 2
    i32.const 66280
    i32.store offset=4
    i32.const 66280
    i32.const 0
    i32.store8
    local.get 2
    i64.const 4294983680
    i64.store offset=8 align=4
    
    local.get 0
    local.get 1
    local.get 2
    i32.const 4
    i32.add
    call 27
    
    local.get 2
    i32.load offset=12
    local.tee 2
    i32.const 16385
    i32.ge_u
    if  ;; label = @1
      unreachable
    end
    
    i32.const 0
    local.get 2
    call 55
    unreachable)

  ;; Function 51: Return success (Ok(())) to caller
  ;; Shortcut for returning successful unit result
  ;; Parameters: () -> never
  (func $return_ok_unit (;51;) (type 5)
    i32.const 66280
    i32.const 0
    i32.store16 align=1
    i32.const 0
    i32.const 2
    call 55
    unreachable)

  ;; Function 52: Return error result
  ;; Encodes Result<Error> and returns
  ;; Parameters: (result_ptr, error_struct_ptr) -> never
  (func $return_result_error (;52;) (type 0) (param i32 i32)
    (local i32 i32 i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 2
    global.set 0
    
    local.get 2
    i32.const 16384
    i32.store offset=8
    local.get 2
    i32.const 66280
    i32.store offset=4
    
    i32.const 2
    local.set 3
    
    block  ;; label = @1
      block (result i32)  ;; label = @2
        local.get 1
        i32.load8_u
        local.tee 4
        i32.const 2
        i32.ne
        if  ;; label = @3
          i32.const 66280
          i32.const 0
          i32.store8
          
          local.get 4
          i32.const 1
          i32.and
          if  ;; label = @4
            i32.const 66281
            i32.const 1
            i32.store8
            local.get 1
            i32.load8_u offset=1
            local.set 1
            i32.const 3
            local.set 3
            i32.const 66282
            br 2 (;@2;)
          end
          
          local.get 2
          i32.const 2
          i32.store offset=12
          i32.const 66281
          i32.const 0
          i32.store8
          
          local.get 1
          i64.load offset=8
          local.get 1
          i32.const 16
          i32.add
          i64.load
          local.get 2
          i32.const 4
          i32.add
          call 27
          
          local.get 2
          i32.load offset=12
          local.tee 3
          i32.const 16385
          i32.lt_u
          br_if 2 (;@1;)
          unreachable
        end
        
        i32.const 1
        local.set 1
        i32.const 66280
        i32.const 1
        i32.store8
        i32.const 66281
      end
      local.get 1
      i32.store8
    end
    
    local.get 0
    local.get 3
    call 55
    unreachable)

  ;; Function 53: Return error (shortcut)
  ;; Returns generic error result
  ;; Parameters: () -> never
  (func $return_err (;53;) (type 5)
    i32.const 66280
    i32.const 257
    i32.store16 align=1
    i32.const 1
    i32.const 2
    call 55
    unreachable)

  ;; Function 54: Encode and return AccountData
  ;; Encodes full AccountData and returns
  ;; Parameters: (account_data_ptr) -> never
  (func $return_account_data (;54;) (type 4) (param i32)
    (local i32 i32 i32 i32 i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 1
    global.set 0
    
    ;; Initialize encoder
    local.get 1
    i64.const 16384
    i64.store offset=8 align=4
    local.get 1
    i32.const 66280
    i32.store offset=4
    
    ;; Encode Result::Ok discriminant
    i32.const 0
    local.get 1
    i32.const 4
    i32.add
    local.tee 2
    call 37
    
    block  ;; label = @1
      local.get 1
      i32.load offset=8
      local.tee 5
      local.get 1
      i32.load offset=12
      local.tee 3
      i32.lt_u
      br_if 0 (;@1;)
      
      local.get 1
      i32.load offset=4
      local.set 4
      local.get 1
      i32.const 0
      i32.store offset=12
      local.get 1
      local.get 5
      local.get 3
      i32.sub
      i32.store offset=8
      local.get 1
      local.get 3
      local.get 4
      i32.add
      i32.store offset=4
      
      ;; Encode AccountData
      local.get 0
      i64.load
      local.get 0
      i32.const 8
      i32.add
      i64.load
      local.get 2
      call 27
      
      local.get 0
      i64.load offset=16
      local.get 0
      i32.const 24
      i32.add
      i64.load
      local.get 2
      call 27
      
      local.get 0
      i64.load offset=32
      local.get 0
      i32.const 40
      i32.add
      i64.load
      local.get 2
      call 27
      
      ;; Encode additional fields
      local.get 0
      i32.load offset=80
      local.get 2
      call 37
      
      local.get 0
      i32.const 48
      i32.add
      local.get 2
      call 31
      
      local.get 0
      i32.const 84
      i32.add
      local.get 2
      call 41
      
      local.get 1
      i32.load offset=12
      local.tee 0
      local.get 1
      i32.load offset=8
      i32.gt_u
      br_if 0 (;@1;)
      
      local.get 4
      local.get 3
      local.get 1
      i32.load offset=4
      local.get 0
      call 3
      drop
      
      local.get 1
      i32.const 16
      i32.add
      global.set 0
      return
    end
    unreachable)

  ;; Function 55: seal_return wrapper
  ;; Calls seal_return to exit contract
  ;; Parameters: (flags, data_len) -> never
  (func $seal_return_wrapper (;55;) (type 0) (param i32 i32)
    local.get 0
    i32.const 66280
    local.get 1
    call 5
    unreachable)

  ;; Function 56: Decode Option<AccountId> from input buffer
  ;; Reads Option discriminant and AccountId if present
  ;; Parameters: (result_ptr, reader_ptr) -> void
  (func $decode_option_account_id_full (;56;) (type 0) (param i32 i32)
    (local i32 i32)
    global.get 0
    i32.const 48
    i32.sub
    local.tee 2
    global.set 0
    
    ;; Read discriminant
    local.get 2
    i32.const 8
    i32.add
    local.get 1
    call 18
    
    i32.const 2
    local.set 3
    
    block  ;; label = @1
      local.get 2
      i32.load8_u offset=8
      br_if 0 (;@1;)
      
      block  ;; label = @2
        block  ;; label = @3
          local.get 2
          i32.load8_u offset=9
          br_table 0 (;@3;) 1 (;@2;) 2 (;@1;)
        end
        i32.const 0
        local.set 3
        br 1 (;@1;)
      end
      
      ;; Read AccountId
      local.get 2
      i32.const 15
      i32.add
      local.get 1
      call 35
      local.get 2
      i32.load8_u offset=15
      br_if 0 (;@1;)
      
      local.get 0
      local.get 2
      i64.load offset=16 align=1
      i64.store offset=1 align=1
      local.get 0
      i32.const 25
      i32.add
      local.get 2
      i32.const 40
      i32.add
      i64.load align=1
      i64.store align=1
      local.get 0
      i32.const 17
      i32.add
      local.get 2
      i32.const 32
      i32.add
      i64.load align=1
      i64.store align=1
      local.get 0
      i32.const 9
      i32.add
      local.get 2
      i32.const 24
      i32.add
      i64.load align=1
      i64.store align=1
      i32.const 1
      local.set 3
    end
    
    local.get 0
    local.get 3
    i32.store8
    
    local.get 2
    i32.const 48
    i32.add
    global.set 0)

  ;; Function 57: Write single byte to encoder
  ;; Low-level encoder operation
  ;; Parameters: (encoder_ptr, byte_value) -> void
  (func $encoder_write_byte (;57;) (type 0) (param i32 i32)
    (local i32)
    local.get 0
    i32.load offset=8
    local.tee 2
    local.get 0
    i32.load offset=4
    i32.lt_u
    if  ;; label = @1
      local.get 0
      local.get 2
      i32.const 1
      i32.add
      i32.store offset=8
      local.get 0
      i32.load
      local.get 2
      i32.add
      local.get 1
      i32.store8
      return
    end
    unreachable)

  ;; Function 58: Decode Preservation enum
  ;; Reads enum discriminant (0-2)
  ;; Parameters: (reader_ptr) -> value
  (func $decode_preservation (;58;) (type 6) (param i32) (result i32)
    (local i32 i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 1
    global.set 0
    
    local.get 1
    i32.const 8
    i32.add
    local.get 0
    call 18
    
    local.get 1
    i32.load8_u offset=9
    local.set 0
    local.get 1
    i32.load8_u offset=8
    local.set 2
    
    local.get 1
    i32.const 16
    i32.add
    global.set 0
    
    i32.const 2
    i32.const 1
    i32.const 2
    local.get 0
    i32.const 1
    i32.eq
    select
    i32.const 0
    local.get 0
    select
    local.get 2
    select)

  ;; Function 59: Decode ternary enum (Precision/Fortitude)
  ;; Reads enum with 3 variants
  ;; Parameters: (reader_ptr) -> value
  (func $decode_ternary_enum (;59;) (type 6) (param i32) (result i32)
    (local i32 i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 1
    global.set 0
    
    local.get 1
    i32.const 8
    i32.add
    local.get 0
    call 18
    
    local.get 1
    i32.load8_u offset=9
    local.set 0
    local.get 1
    i32.load8_u offset=8
    local.set 2
    
    local.get 1
    i32.const 16
    i32.add
    global.set 0
    
    i32.const 3
    i32.const 3
    local.get 0
    local.get 0
    i32.const 3
    i32.ge_u
    select
    local.get 2
    select)

  ;; Function 60: Deposit into account with checks
  ;; Increases account balance with validation
  ;; Parameters: (account_data_ptr, flags, amount_low, amount_high) -> result_code
  (func $deposit_into_account (;60;) (type 13) (param i32 i32 i64 i64) (result i32)
    (local i32 i32 i32 i64 i64 i64 i64 i64 i64 i64)
    global.get 0
    i32.const 128
    i32.sub
    local.tee 4
    global.set 0
    
    ;; Get caller
    local.get 4
    call 42
    
    block  ;; label = @1
      ;; Check authorization
      local.get 4
      local.get 0
      i32.const 48
      i32.add
      call 44
      i32.eqz
      if  ;; label = @2
        i32.const 7
        local.set 5

        ;; Check if amount is zero
        local.get 2
        local.get 3
        i64.or
        i64.eqz
        br_if 1 (;@1;)
        i32.const 4
        local.set 5
        
        ;; Add to free balance
        local.get 0
        i64.load
        local.tee 7
        local.get 2
        i64.add
        local.tee 11
        local.get 7
        i64.lt_u
        local.tee 6
        local.get 6
        i64.extend_i32_u
        local.get 0
        i32.const 8
        i32.add
        i64.load
        local.tee 8
        local.get 3
        i64.add
        i64.add
        local.tee 7
        local.get 8
        i64.lt_u
        local.get 7
        local.get 8
        i64.eq
        select
        br_if 1 (;@1;)
        
        local.get 0
        local.get 11
        i64.store
        local.get 0
        local.get 7
        i64.store offset=8
        
        ;; Add to reserved
        local.get 0
        i64.load offset=16
        local.tee 8
        local.get 2
        i64.add
        local.tee 10
        local.get 8
        i64.lt_u
        local.tee 6
        local.get 6
        i64.extend_i32_u
        local.get 0
        i32.const 24
        i32.add
        i64.load
        local.tee 9
        local.get 3
        i64.add
        i64.add
        local.tee 8
        local.get 9
        i64.lt_u
        local.get 8
        local.get 9
        i64.eq
        select
        br_if 1 (;@1;)
        
        local.get 0
        local.get 10
        i64.store offset=16
        local.get 0
        local.get 8
        i64.store offset=24
        
        ;; Check existential deposit
        local.get 4
        i32.const 32
        i32.add
        local.get 1
        call 46
        
        block  ;; label = @2
          ;; If account already exists, skip ED check
          local.get 4
          i64.load offset=32
          local.tee 12
          local.get 4
          i32.const 40
          i32.add
          i64.load
          local.tee 9
          i64.or
          i64.const 0
          i64.ne
          br_if 0 (;@2;)
          
          ;; Check ED requirement
          local.get 0
          i64.load offset=32
          local.get 2
          i64.le_u
          local.get 0
          i32.const 40
          i32.add
          i64.load
          local.tee 13
          local.get 3
          i64.le_u
          local.get 3
          local.get 13
          i64.eq
          select
          br_if 0 (;@2;)
          
          ;; Revert changes
          local.get 0
          i64.const 0
          local.get 8
          local.get 3
          i64.sub
          local.get 2
          local.get 10
          i64.gt_u
          i64.extend_i32_u
          i64.sub
          local.tee 9
          local.get 10
          local.get 10
          local.get 2
          i64.sub
          local.tee 10
          i64.lt_u
          local.get 8
          local.get 9
          i64.lt_u
          local.get 8
          local.get 9
          i64.eq
          select
          local.tee 1
          select
          i64.store offset=24
          local.get 0
          i64.const 0
          local.get 10
          local.get 1
          select
          i64.store offset=16
          local.get 0
          i64.const 0
          local.get 7
          local.get 3
          i64.sub
          local.get 2
          local.get 11
          i64.gt_u
          i64.extend_i32_u
          i64.sub
          local.tee 3
          local.get 11
          local.get 2
          i64.sub
          local.tee 2
          local.get 11
          i64.gt_u
          local.get 3
          local.get 7
          i64.gt_u
          local.get 3
          local.get 7
          i64.eq
          select
          local.tee 1
          select
          i64.store offset=8
          local.get 0
          i64.const 0
          local.get 2
          local.get 1
          select
          i64.store
          i32.const 1
          local.set 5
          br 2 (;@1;)
        end
        
        ;; Check total overflow
        local.get 2
        local.get 12
        i64.add
        local.tee 7
        local.get 12
        i64.lt_u
        local.tee 0
        local.get 0
        i64.extend_i32_u
        local.get 3
        local.get 9
        i64.add
        i64.add
        local.tee 2
        local.get 9
        i64.lt_u
        local.get 2
        local.get 9
        i64.eq
        select
        i32.const 1
        i32.eq
        br_if 1 (;@1;)
        local.get 4
        local.get 7
        i64.store offset=32
        local.get 4
        local.get 2
        i64.store offset=40
        
        ;; Write updated account
        local.get 1
        local.get 4
        i32.const 32
        i32.add
        call 28
        
        ;; Emit Transfer event
        local.get 4
        i32.const 104
        i32.add
        local.get 1
        i32.const 24
        i32.add
        i64.load align=1
        i64.store
        local.get 4
        i32.const 96
        i32.add
        local.get 1
        i32.const 16
        i32.add
        i64.load align=1
        i64.store
        local.get 4
        i32.const 88
        i32.add
        local.get 1
        i32.const 8
        i32.add
        i64.load align=1
        i64.store
        local.get 4
        local.get 2
        i64.store offset=120
        local.get 4
        local.get 7
        i64.store offset=112
        local.get 4
        local.get 1
        i64.load align=1
        i64.store offset=80
        local.get 4
        i32.const 80
        i32.add
        call 38
        i32.const 7
        local.set 5
        br 1 (;@1;)
      end
      i32.const 6
      local.set 5
    end
    local.get 4
    i32.const 128
    i32.add
    global.set 0
    local.get 5)

  ;; Function 61: Transfer with preservation checks
  ;; Implements full transfer logic
  ;; Parameters: (result_ptr, from_ptr, to_ptr, amount_low, amount_high, preservation, fortitude) -> void
  (func $transfer_with_checks (;61;) (type 14) (param i32 i32 i32 i64 i64 i32 i32)
    (local i32 i32 i64 i64 i64 i64 i64 i64)
    global.get 0
    i32.const 128
    i32.sub
    local.tee 7
    global.set 0
    
    block  ;; label = @1
      ;; Check zero amount
      local.get 3
      local.get 4
      i64.or
      i64.eqz
      if  ;; label = @2
        local.get 0
        i64.const 0
        i64.store offset=16
        local.get 0
        i64.const 0
        i64.store offset=8
        local.get 0
        i32.const 0
        i32.store8
        br 1 (;@1;)
      end
      
      ;; Load sender account
      local.get 7
      local.get 2
      call 46
      
      ;; Calculate reducible balance
      local.get 7
      i32.const 48
      i32.add
      local.get 1
      i64.load offset=32
      local.tee 13
      local.get 1
      i32.const 40
      i32.add
      i64.load
      local.tee 11
      local.get 2
      local.get 5
      call 47
      
      local.get 7
      i32.const 56
      i32.add
      i64.load
      local.set 9
      local.get 7
      i64.load offset=48
      local.set 10
      
      ;; Perform transfer validation and execution
      block  ;; label = @2
        local.get 0
        block (result i32)  ;; label = @3
          block  ;; label = @4
            block  ;; label = @5
              block  ;; label = @6
                block  ;; label = @7
                  block  ;; label = @8
                    block  ;; label = @9
                      local.get 6
                      i32.eqz
                      if  ;; label = @10
                        local.get 3
                        local.get 10
                        i64.le_u
                        local.get 4
                        local.get 9
                        i64.le_u
                        local.get 4
                        local.get 9
                        i64.eq
                        select
                        br_if 1 (;@9;)
                        local.get 3
                        i64.const 0
                        local.get 7
                        i64.load
                        local.tee 3
                        local.get 7
                        i64.load offset=32
                        local.tee 10
                        i64.sub
                        local.tee 9
                        local.get 3
                        local.get 9
                        i64.lt_u
                        local.get 7
                        i32.const 8
                        i32.add
                        i64.load
                        local.tee 9
                        local.get 7
                        i32.const 40
                        i32.add
                        i64.load
                        i64.sub
                        local.get 3
                        local.get 10
                        i64.lt_u
                        i64.extend_i32_u
                        i64.sub
                        local.tee 3
                        local.get 9
                        i64.gt_u
                        local.get 3
                        local.get 9
                        i64.eq
                        select
                        local.tee 1
                        select
                        i64.gt_u
                        i64.const 0
                        local.get 3
                        local.get 1
                        select
                        local.tee 3
                        local.get 4
                        i64.lt_u
                        local.get 3
                        local.get 4
                        i64.eq
                        select
                        i32.eqz
                        br_if 2 (;@8;)
                        local.get 0
                        i32.const 0
                        i32.store8 offset=1
                        br 6 (;@4;)
                      end
                      local.get 9
                      local.get 10
                      i64.or
                      i64.eqz
                      br_if 2 (;@7;)
                      local.get 4
                      local.get 9
                      local.get 3
                      local.get 10
                      i64.lt_u
                      local.get 4
                      local.get 9
                      i64.lt_u
                      local.get 4
                      local.get 9
                      i64.eq
                      select
                      local.tee 5
                      select
                      local.set 4
                      local.get 3
                      local.get 10
                      local.get 5
                      select
                      local.set 3
                    end
                    local.get 7
                    i64.load
                    local.tee 10
                    local.get 3
                    i64.lt_u
                    local.tee 5
                    local.get 7
                    i32.const 8
                    i32.add
                    i64.load
                    local.tee 9
                    local.get 4
                    i64.lt_u
                    local.get 4
                    local.get 9
                    i64.eq
                    select
                    br_if 3 (;@5;)
                    local.get 7
                    local.get 10
                    local.get 3
                    i64.sub
                    local.tee 14
                    i64.store
                    local.get 7
                    local.get 9
                    local.get 4
                    i64.sub
                    local.get 5
                    i64.extend_i32_u
                    i64.sub
                    local.tee 12
                    i64.store offset=8
                    local.get 3
                    local.get 10
                    i64.xor
                    local.get 4
                    local.get 9
                    i64.xor
                    i64.or
                    i64.eqz
                    br_if 6 (;@2;)
                    local.get 13
                    local.get 14
                    i64.gt_u
                    local.get 11
                    local.get 12
                    i64.gt_u
                    local.get 11
                    local.get 12
                    i64.eq
                    select
                    br_if 2 (;@6;)
                    br 6 (;@2;)
                  end
                  local.get 0
                  i32.const 3
                  i32.store8 offset=1
                  br 3 (;@4;)
                end
                local.get 0
                i64.const 0
                i64.store offset=16
                local.get 0
                i64.const 0
                i64.store offset=8
                i32.const 0
                br 3 (;@3;)
              end
              local.get 1
              local.get 2
              local.get 7
              call 66
              i32.const 255
              i32.and
              local.tee 5
              i32.const 7
              i32.eq
              br_if 3 (;@2;)
              local.get 0
              local.get 5
              i32.store8 offset=1
              br 1 (;@4;)
            end
            local.get 0
            i32.const 0
            i32.store8 offset=1
          end
          i32.const 1
        end
        i32.store8
        br 1 (;@1;)
      end
      local.get 1
      i64.const 0
      local.get 1
      i64.load
      local.tee 9
      local.get 3
      i64.sub
      local.tee 10
      local.get 9
      local.get 10
      i64.lt_u
      local.get 1
      i32.const 8
      i32.add
      local.tee 5
      i64.load
      local.tee 10
      local.get 4
      i64.sub
      local.get 3
      local.get 9
      i64.gt_u
      i64.extend_i32_u
      i64.sub
      local.tee 9
      local.get 10
      i64.gt_u
      local.get 9
      local.get 10
      i64.eq
      select
      local.tee 6
      select
      i64.store
      local.get 5
      i64.const 0
      local.get 9
      local.get 6
      select
      i64.store
      local.get 1
      i64.const 0
      local.get 1
      i64.load offset=16
      local.tee 9
      local.get 3
      i64.sub
      local.tee 10
      local.get 9
      local.get 10
      i64.lt_u
      local.get 1
      i32.const 24
      i32.add
      local.tee 1
      i64.load
      local.tee 10
      local.get 4
      i64.sub
      local.get 3
      local.get 9
      i64.gt_u
      i64.extend_i32_u
      i64.sub
      local.tee 9
      local.get 10
      i64.gt_u
      local.get 9
      local.get 10
      i64.eq
      select
      local.tee 5
      select
      i64.store offset=16
      local.get 1
      i64.const 0
      local.get 9
      local.get 5
      select
      i64.store
      local.get 2
      local.get 7
      call 28
      local.get 7
      i32.const 72
      i32.add
      local.get 2
      i32.const 24
      i32.add
      i64.load align=1
      i64.store
      local.get 7
      i32.const -64
      i32.sub
      local.get 2
      i32.const 16
      i32.add
      i64.load align=1
      i64.store
      local.get 7
      i32.const 56
      i32.add
      local.get 2
      i32.const 8
      i32.add
      i64.load align=1
      i64.store
      local.get 7
      i64.const 16384
      i64.store offset=104 align=4
      local.get 7
      i32.const 66280
      i32.store offset=100
      local.get 7
      local.get 4
      i64.store offset=88
      local.get 7
      local.get 3
      i64.store offset=80
      local.get 7
      local.get 2
      i64.load align=1
      i64.store offset=48
      local.get 7
      local.get 7
      i32.const 48
      i32.add
      local.tee 8
      i32.store offset=112
      local.get 7
      i32.const 100
      i32.add
      local.tee 1
      i32.const 2
      call 34
      local.get 1
      i32.const 65808
      call 30
      local.get 7
      i32.const 116
      i32.add
      local.tee 6
      local.get 1
      local.get 7
      i32.const 112
      i32.add
      call 39
      block  ;; label = @2
        local.get 7
        i32.load offset=120
        local.tee 5
        local.get 7
        i32.load offset=124
        local.tee 1
        i32.lt_u
        br_if 0 (;@2;)
        local.get 7
        i32.load offset=116
        local.set 2
        local.get 7
        i32.const 0
        i32.store offset=124
        local.get 7
        local.get 5
        local.get 1
        i32.sub
        i32.store offset=120
        local.get 7
        local.get 1
        local.get 2
        i32.add
        i32.store offset=116
        local.get 8
        local.get 6
        call 31
        local.get 7
        i64.load offset=80
        local.get 7
        i32.const 88
        i32.add
        i64.load
        local.get 6
        call 27
        local.get 7
        i32.load offset=124
        local.tee 5
        local.get 7
        i32.load offset=120
        i32.gt_u
        br_if 0 (;@2;)
        local.get 2
        local.get 1
        local.get 7
        i32.load offset=116
        local.get 5
        call 2
        local.get 0
        local.get 4
        i64.store offset=16
        local.get 0
        local.get 3
        i64.store offset=8
        local.get 0
        i32.const 0
        i32.store8
        br 1 (;@1;)
      end
      unreachable
    end
    local.get 7
    i32.const 128
    i32.add
    global.set 0)

  ;; Function 62: Check if transfer is allowed
  ;; Validates balance operation
  ;; Parameters: (config_ptr, account_ptr, flags, amount_low, amount_high, mode) -> result
  (func $check_transfer_allowed (;62;) (type 15) (param i32 i32 i32 i64 i64 i32) (result i32)
    (local i32 i32 i64 i64 i64 i64 i64 i64 i64)
    global.get 0
    i32.const 192
    i32.sub
    local.tee 6
    global.set 0
    
    i32.const 7
    local.set 7
    
    block  ;; label = @1
      ;; Quick zero check
      local.get 3
      local.get 4
      i64.or
      i64.eqz
      br_if 0 (;@1;)
      
      block  ;; label = @2
        local.get 1
        local.get 2
        call 45
        i32.eqz
        if  ;; label = @3
          ;; Load accounts
          local.get 6
          i32.const 8
          i32.add
          local.get 1
          call 46
          
          local.get 6
          i32.const 56
          i32.add
          local.get 2
          call 46
          
          ;; Perform checks
          i64.const 0
          local.get 6
          i64.load offset=8
          local.tee 10
          local.get 6
          i64.load offset=40
          local.tee 9
          i64.sub
          local.tee 8
          local.get 8
          local.get 10
          i64.gt_u
          local.get 6
          i32.const 16
          i32.add
          i64.load
          local.tee 8
          local.get 6
          i32.const 48
          i32.add
          i64.load
          i64.sub
          local.get 9
          local.get 10
          i64.gt_u
          i64.extend_i32_u
          i64.sub
          local.tee 9
          local.get 8
          i64.gt_u
          local.get 8
          local.get 9
          i64.eq
          select
          local.tee 7
          select
          local.get 3
          i64.lt_u
          i64.const 0
          local.get 9
          local.get 7
          select
          local.tee 9
          local.get 4
          i64.lt_u
          local.get 4
          local.get 9
          i64.eq
          select
          i32.eqz
          br_if 1 (;@2;)
          i32.const 2
          local.set 7
          br 2 (;@1;)
        end
        local.get 6
        i32.const 129
        i32.add
        local.get 1
        i32.const 8
        i32.add
        i64.load align=1
        i64.store align=1
        local.get 6
        i32.const 137
        i32.add
        local.get 1
        i32.const 16
        i32.add
        i64.load align=1
        i64.store align=1
        local.get 6
        i32.const 145
        i32.add
        local.get 1
        i32.const 24
        i32.add
        i64.load align=1
        i64.store align=1
        local.get 6
        i32.const 162
        i32.add
        local.get 2
        i32.const 8
        i32.add
        i64.load align=1
        i64.store align=2
        local.get 6
        i32.const 170
        i32.add
        local.get 2
        i32.const 16
        i32.add
        i64.load align=1
        i64.store align=2
        local.get 6
        i32.const 178
        i32.add
        local.get 2
        i32.const 24
        i32.add
        i64.load align=1
        i64.store align=2
        local.get 6
        i32.const 1
        i32.store8 offset=120
        local.get 6
        i32.const 1
        i32.store8 offset=153
        local.get 6
        local.get 1
        i64.load align=1
        i64.store offset=121 align=1
        local.get 6
        local.get 2
        i64.load align=1
        i64.store offset=154 align=2
        local.get 6
        local.get 4
        i64.store offset=112
        local.get 6
        local.get 3
        i64.store offset=104
        local.get 6
        i32.const 104
        i32.add
        call 40
        br 1 (;@1;)
      end
      block  ;; label = @2
        block  ;; label = @3
          block  ;; label = @4
            local.get 5
            i32.const 255
            i32.and
            i32.eqz
            br_if 0 (;@4;)
            local.get 3
            local.get 10
            i64.gt_u
            local.tee 5
            local.get 4
            local.get 8
            i64.gt_u
            local.get 4
            local.get 8
            i64.eq
            select
            br_if 1 (;@3;)
            local.get 0
            i64.load offset=32
            local.get 10
            local.get 3
            i64.sub
            i64.gt_u
            local.get 8
            local.get 4
            i64.sub
            local.get 5
            i64.extend_i32_u
            i64.sub
            local.tee 9
            local.get 0
            i32.const 40
            i32.add
            i64.load
            local.tee 11
            i64.lt_u
            local.get 9
            local.get 11
            i64.eq
            select
            i32.eqz
            br_if 0 (;@4;)
            i32.const 3
            local.set 7
            br 3 (;@1;)
          end
          local.get 3
          local.get 10
          i64.gt_u
          local.tee 5
          local.get 4
          local.get 8
          i64.gt_u
          local.get 4
          local.get 8
          i64.eq
          select
          i32.eqz
          br_if 1 (;@2;)
        end
        i32.const 0
        local.set 7
        br 1 (;@1;)
      end
      local.get 6
      local.get 10
      local.get 3
      i64.sub
      local.tee 13
      i64.store offset=8
      local.get 6
      local.get 8
      local.get 4
      i64.sub
      local.get 5
      i64.extend_i32_u
      i64.sub
      local.tee 9
      i64.store offset=16
      local.get 6
      i64.load offset=56
      local.tee 11
      local.get 3
      i64.add
      local.tee 14
      local.get 11
      i64.lt_u
      local.tee 5
      local.get 5
      i64.extend_i32_u
      local.get 6
      i32.const -64
      i32.sub
      i64.load
      local.tee 11
      local.get 4
      i64.add
      i64.add
      local.tee 12
      local.get 11
      i64.lt_u
      local.get 11
      local.get 12
      i64.eq
      select
      if  ;; label = @2
        i32.const 4
        local.set 7
        br 1 (;@1;)
      end
      local.get 6
      local.get 14
      i64.store offset=56
      local.get 6
      local.get 12
      i64.store offset=64
      block  ;; label = @2
        local.get 3
        local.get 10
        i64.xor
        local.get 4
        local.get 8
        i64.xor
        i64.or
        i64.eqz
        br_if 0 (;@2;)
        local.get 13
        local.get 0
        i64.load offset=32
        i64.lt_u
        local.get 9
        local.get 0
        i32.const 40
        i32.add
        i64.load
        local.tee 8
        i64.lt_u
        local.get 8
        local.get 9
        i64.eq
        select
        i32.eqz
        br_if 0 (;@2;)
        local.get 0
        local.get 1
        local.get 6
        i32.const 8
        i32.add
        call 66
        i32.const 255
        i32.and
        local.tee 7
        i32.const 7
        i32.ne
        br_if 1 (;@1;)
      end
      local.get 1
      local.get 6
      i32.const 8
      i32.add
      call 28
      local.get 2
      local.get 6
      i32.const 56
      i32.add
      call 28
      ;; Emit event for transfer between different accounts
      local.get 6
      i32.const 129
      i32.add
      local.get 1
      i32.const 8
      i32.add
      i64.load align=1
      i64.store align=1
      local.get 6
      i32.const 137
      i32.add
      local.get 1
      i32.const 16
      i32.add
      i64.load align=1
      i64.store align=1
      local.get 6
      i32.const 145
      i32.add
      local.get 1
      i32.const 24
      i32.add
      i64.load align=1
      i64.store align=1
      local.get 6
      i32.const 162
      i32.add
      local.get 2
      i32.const 8
      i32.add
      i64.load align=1
      i64.store align=2
      local.get 6
      i32.const 170
      i32.add
      local.get 2
      i32.const 16
      i32.add
      i64.load align=1
      i64.store align=2
      local.get 6
      i32.const 178
      i32.add
      local.get 2
      i32.const 24
      i32.add
      i64.load align=1
      i64.store align=2
      local.get 6
      i32.const 1
      i32.store8 offset=120
      local.get 6
      i32.const 1
      i32.store8 offset=153
      local.get 6
      local.get 1
      i64.load align=1
      i64.store offset=121 align=1
      local.get 6
      local.get 2
      i64.load align=1
      i64.store offset=154 align=2
      local.get 6
      local.get 4
      i64.store offset=112
      local.get 6
      local.get 3
      i64.store offset=104
      local.get 6
      i32.const 104
      i32.add
      call 40
      i32.const 7
      local.set 7
    end
    local.get 6
    i32.const 192
    i32.add
    global.set 0
    local.get 7)

  ;; ============================================================================
  ;; MAIN CONTRACT DISPATCHER
  ;; ============================================================================

  ;; Function 63: Main contract call dispatcher
  ;; Decodes input selector and routes to handler
  ;; Parameters: () -> never
  (func $dispatch_call (;63;) (type 5)
    (local i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i64 i64 i64 i64 i64 i64 i64 i64 i64 i64)
    global.get 0
    i32.const 528
    i32.sub
    local.tee 0
    global.set 0
    block  ;; label = @1
      block  ;; label = @2
        block  ;; label = @3
          block  ;; label = @4
            block  ;; label = @5
              block  ;; label = @6
                block (result i32)  ;; label = @7
                  block (result i64)  ;; label = @8
                    block  ;; label = @9
                      block (result i32)  ;; label = @10
                        block  ;; label = @11
                          block  ;; label = @12
                            block  ;; label = @13
                              block (result i32)  ;; label = @14
                                block  ;; label = @15
                                  block  ;; label = @16
                                    call 43
                                    i32.const 255
                                    i32.and
                                    i32.const 5
                                    i32.ne
                                    br_if 0 (;@16;)
                                    local.get 0
                                    i32.const 16384
                                    i32.store offset=208
                                    i32.const 66280
                                    local.get 0
                                    i32.const 208
                                    i32.add
                                    local.tee 1
                                    call 1
                                    local.get 0
                                    i32.load offset=208
                                    local.tee 2
                                    i32.const 16385
                                    i32.ge_u
                                    br_if 0 (;@16;)
                                    local.get 0
                                    local.get 2
                                    i32.store offset=520
                                    local.get 0
                                    i32.const 66280
                                    i32.store offset=516
                                    block  ;; label = @17
                                      block  ;; label = @18
                                        block  ;; label = @19
                                          local.get 0
                                          i32.const 516
                                          i32.add
                                          local.get 1
                                          call 48
                                          br_if 0 (;@19;)
                                          local.get 0
                                          i32.load offset=208
                                          local.tee 1
                                          i32.const 24
                                          i32.shr_u
                                          local.set 3
                                          local.get 1
                                          i32.const 16
                                          i32.shr_u
                                          local.set 2
                                          local.get 1
                                          i32.const 8
                                          i32.shr_u
                                          local.set 4
                                          block  ;; label = @20
                                            block  ;; label = @21
                                              block  ;; label = @22
                                                block  ;; label = @23
                                                  block  ;; label = @24
                                                    block  ;; label = @25
                                                      block  ;; label = @26
                                                        block  ;; label = @27
                                                          block  ;; label = @28
                                                            block  ;; label = @29
                                                              block  ;; label = @30
                                                                block  ;; label = @31
                                                                  block  ;; label = @32
                                                                    block  ;; label = @33
                                                                      block  ;; label = @34
                                                                        block  ;; label = @35
                                                                          block  ;; label = @36
                                                                            block  ;; label = @37
                                                                              block  ;; label = @38
                                                                                block  ;; label = @39
                                                                                  block  ;; label = @40
                                                                                    block  ;; label = @41
                                                                                      block  ;; label = @42
                                                                                        block  ;; label = @43
                                                                                          block  ;; label = @44
                                                                                            block  ;; label = @45
                                                                                              block  ;; label = @46
                                                                                                block  ;; label = @47
                                                                                                  block  ;; label = @48
                                                                                                    block  ;; label = @49
                                                                                                      block  ;; label = @50
                                                                                                        block  ;; label = @51
                                                                                                          block  ;; label = @52
                                                                                                            local.get 1
                                                                                                            i32.const 255
                                                                                                            i32.and
                                                                                                            local.tee 1
                                                                                                            i32.const 200
                                                                                                            i32.sub
                                                                                                            br_table 25 (;@27;) 33 (;@19;) 33 (;@19;) 9 (;@43;) 33 (;@19;) 33 (;@19;) 1 (;@51;) 17 (;@35;) 0 (;@52;)
                                                                                                          end
                                                                                                          block  ;; label = @52
                                                                                                            local.get 1
                                                                                                            i32.const 243
                                                                                                            i32.sub
                                                                                                            br_table 5 (;@47;) 16 (;@36;) 33 (;@19;) 33 (;@19;) 12 (;@40;) 33 (;@19;) 10 (;@42;) 0 (;@52;)
                                                                                                          end
                                                                                                          block  ;; label = @52
                                                                                                            local.get 1
                                                                                                            i32.const 46
                                                                                                            i32.sub
                                                                                                            br_table 20 (;@32;) 33 (;@19;) 24 (;@28;) 33 (;@19;) 33 (;@19;) 15 (;@37;) 0 (;@52;)
                                                                                                          end
                                                                                                          block  ;; label = @52
                                                                                                            local.get 1
                                                                                                            i32.const 5
                                                                                                            i32.sub
                                                                                                            br_table 6 (;@46;) 11 (;@41;) 0 (;@52;)
                                                                                                          end
                                                                                                          block  ;; label = @52
                                                                                                            local.get 1
                                                                                                            i32.const 16
                                                                                                            i32.sub
                                                                                                            br_table 19 (;@33;) 28 (;@24;) 0 (;@52;)
                                                                                                          end
                                                                                                          block  ;; label = @52
                                                                                                            local.get 1
                                                                                                            i32.const 132
                                                                                                            i32.sub
                                                                                                            br_table 22 (;@30;) 7 (;@45;) 0 (;@52;)
                                                                                                          end
                                                                                                          block  ;; label = @52
                                                                                                            local.get 1
                                                                                                            i32.const 160
                                                                                                            i32.sub
                                                                                                            br_table 14 (;@38;) 4 (;@48;) 0 (;@52;)
                                                                                                          end
                                                                                                          block  ;; label = @52
                                                                                                            local.get 1
                                                                                                            i32.const 178
                                                                                                            i32.sub
                                                                                                            br_table 21 (;@31;) 33 (;@19;) 3 (;@49;) 0 (;@52;)
                                                                                                          end
                                                                                                          local.get 1
                                                                                                          i32.const 26
                                                                                                          i32.ne
                                                                                                          if  ;; label = @52
                                                                                                            local.get 1
                                                                                                            i32.const 39
                                                                                                            i32.eq
                                                                                                            br_if 18 (;@34;)
                                                                                                            block  ;; label = @53
                                                                                                              block  ;; label = @54
                                                                                                                local.get 1
                                                                                                                i32.const 59
                                                                                                                i32.ne
                                                                                                                if  ;; label = @55
                                                                                                                  local.get 1
                                                                                                                  i32.const 85
                                                                                                                  i32.eq
                                                                                                                  br_if 11 (;@44;)
                                                                                                                  local.get 1
                                                                                                                  i32.const 106
                                                                                                                  i32.eq
                                                                                                                  br_if 1 (;@54;)
                                                                                                                  local.get 1
                                                                                                                  i32.const 120
                                                                                                                  i32.eq
                                                                                                                  br_if 32 (;@23;)
                                                                                                                  local.get 1
                                                                                                                  i32.const 139
                                                                                                                  i32.eq
                                                                                                                  br_if 5 (;@50;)
                                                                                                                  local.get 1
                                                                                                                  i32.const 152
                                                                                                                  i32.eq
                                                                                                                  br_if 2 (;@53;)
                                                                                                                  local.get 1
                                                                                                                  i32.const 167
                                                                                                                  i32.eq
                                                                                                                  br_if 16 (;@39;)
                                                                                                                  local.get 1
                                                                                                                  i32.const 194
                                                                                                                  i32.eq
                                                                                                                  br_if 26 (;@29;)
                                                                                                                  local.get 1
                                                                                                                  i32.const 220
                                                                                                                  i32.eq
                                                                                                                  br_if 30 (;@25;)
                                                                                                                  local.get 1
                                                                                                                  i32.const 225
                                                                                                                  i32.eq
                                                                                                                  br_if 29 (;@26;)
                                                                                                                  local.get 1
                                                                                                                  i32.const 232
                                                                                                                  i32.ne
                                                                                                                  local.get 3
                                                                                                                  i32.const 31
                                                                                                                  i32.ne
                                                                                                                  i32.or
                                                                                                                  local.get 4
                                                                                                                  i32.const 255
                                                                                                                  i32.and
                                                                                                                  i32.const 150
                                                                                                                  i32.ne
                                                                                                                  local.get 2
                                                                                                                  i32.const 255
                                                                                                                  i32.and
                                                                                                                  i32.const 67
                                                                                                                  i32.ne
                                                                                                                  i32.or
                                                                                                                  i32.or
                                                                                                                  br_if 36 (;@19;)
                                                                                                                  local.get 0
                                                                                                                  i32.const 208
                                                                                                                  i32.add
                                                                                                                  local.get 0
                                                                                                                  i32.const 516
                                                                                                                  i32.add
                                                                                                                  local.tee 1
                                                                                                                  call 35
                                                                                                                  local.get 0
                                                                                                                  i32.load8_u offset=208
                                                                                                                  br_if 36 (;@19;)
                                                                                                                  local.get 0
                                                                                                                  i32.const 456
                                                                                                                  i32.add
                                                                                                                  local.get 1
                                                                                                                  call 22
                                                                                                                  local.get 0
                                                                                                                  i32.load offset=456
                                                                                                                  br_if 36 (;@19;)
                                                                                                                  local.get 0
                                                                                                                  i32.const 472
                                                                                                                  i32.add
                                                                                                                  i64.load
                                                                                                                  local.set 13
                                                                                                                  local.get 0
                                                                                                                  i64.load offset=464
                                                                                                                  local.set 14
                                                                                                                  local.get 1
                                                                                                                  call 58
                                                                                                                  i32.const 255
                                                                                                                  i32.and
                                                                                                                  local.tee 1
                                                                                                                  i32.const 2
                                                                                                                  i32.eq
                                                                                                                  br_if 36 (;@19;)
                                                                                                                  local.get 0
                                                                                                                  i32.const 400
                                                                                                                  i32.add
                                                                                                                  local.get 0
                                                                                                                  i32.const 233
                                                                                                                  i32.add
                                                                                                                  i32.load8_u
                                                                                                                  i32.store8
                                                                                                                  local.get 0
                                                                                                                  i32.const 103
                                                                                                                  i32.add
                                                                                                                  local.get 13
                                                                                                                  i64.store align=1
                                                                                                                  local.get 0
                                                                                                                  local.get 0
                                                                                                                  i64.load offset=225 align=1
                                                                                                                  i64.store offset=392
                                                                                                                  local.get 0
                                                                                                                  local.get 0
                                                                                                                  i32.load offset=234 align=1
                                                                                                                  i32.store offset=88
                                                                                                                  local.get 0
                                                                                                                  local.get 0
                                                                                                                  i32.const 237
                                                                                                                  i32.add
                                                                                                                  i32.load align=1
                                                                                                                  i32.store offset=91 align=1
                                                                                                                  local.get 0
                                                                                                                  local.get 14
                                                                                                                  i64.store offset=95 align=1
                                                                                                                  local.get 0
                                                                                                                  local.get 1
                                                                                                                  i32.store8 offset=111
                                                                                                                  local.get 0
                                                                                                                  i32.const 218
                                                                                                                  i32.add
                                                                                                                  i64.load32_u align=1
                                                                                                                  local.get 0
                                                                                                                  i32.const 224
                                                                                                                  i32.add
                                                                                                                  i64.load8_u
                                                                                                                  i64.const 48
                                                                                                                  i64.shl
                                                                                                                  local.get 0
                                                                                                                  i32.const 222
                                                                                                                  i32.add
                                                                                                                  i64.load16_u align=1
                                                                                                                  i64.const 32
                                                                                                                  i64.shl
                                                                                                                  i64.or
                                                                                                                  i64.or
                                                                                                                  local.set 14
                                                                                                                  local.get 0
                                                                                                                  i64.load offset=210 align=1
                                                                                                                  local.set 16
                                                                                                                  local.get 0
                                                                                                                  i32.load8_u offset=209
                                                                                                                  local.set 2
                                                                                                                  i32.const 18
                                                                                                                  local.set 3
                                                                                                                  br 38 (;@17;)
                                                                                                                end
                                                                                                                local.get 3
                                                                                                                i32.const 244
                                                                                                                i32.ne
                                                                                                                local.get 4
                                                                                                                i32.const 255
                                                                                                                i32.and
                                                                                                                i32.const 236
                                                                                                                i32.ne
                                                                                                                i32.or
                                                                                                                local.get 2
                                                                                                                i32.const 255
                                                                                                                i32.and
                                                                                                                i32.const 139
                                                                                                                i32.ne
                                                                                                                i32.or
                                                                                                                br_if 35 (;@19;)
                                                                                                                i32.const 0
                                                                                                                local.set 3
                                                                                                                br 37 (;@17;)
                                                                                                              end
                                                                                                              local.get 3
                                                                                                              i32.const 50
                                                                                                              i32.ne
                                                                                                              local.get 4
                                                                                                              i32.const 255
                                                                                                              i32.and
                                                                                                              i32.const 234
                                                                                                              i32.ne
                                                                                                              i32.or
                                                                                                              local.get 2
                                                                                                              i32.const 255
                                                                                                              i32.and
                                                                                                              i32.const 100
                                                                                                              i32.ne
                                                                                                              i32.or
                                                                                                              br_if 34 (;@19;)
                                                                                                              i32.const 1
                                                                                                              local.set 3
                                                                                                              br 36 (;@17;)
                                                                                                            end
                                                                                                            local.get 3
                                                                                                            i32.const 143
                                                                                                            i32.ne
                                                                                                            local.get 4
                                                                                                            i32.const 255
                                                                                                            i32.and
                                                                                                            i32.const 248
                                                                                                            i32.ne
                                                                                                            i32.or
                                                                                                            local.get 2
                                                                                                            i32.const 255
                                                                                                            i32.and
                                                                                                            i32.const 81
                                                                                                            i32.ne
                                                                                                            i32.or
                                                                                                            br_if 33 (;@19;)
                                                                                                            i32.const 2
                                                                                                            local.set 3
                                                                                                            br 35 (;@17;)
                                                                                                          end
                                                                                                          local.get 3
                                                                                                          i32.const 99
                                                                                                          i32.ne
                                                                                                          local.get 4
                                                                                                          i32.const 255
                                                                                                          i32.and
                                                                                                          i32.const 164
                                                                                                          i32.ne
                                                                                                          i32.or
                                                                                                          local.get 2
                                                                                                          i32.const 255
                                                                                                          i32.and
                                                                                                          i32.const 136
                                                                                                          i32.ne
                                                                                                          i32.or
                                                                                                          br_if 32 (;@19;)
                                                                                                          i32.const 3
                                                                                                          local.set 3
                                                                                                          br 34 (;@17;)
                                                                                                        end
                                                                                                        local.get 3
                                                                                                        i32.const 26
                                                                                                        i32.ne
                                                                                                        local.get 4
                                                                                                        i32.const 255
                                                                                                        i32.and
                                                                                                        i32.const 242
                                                                                                        i32.ne
                                                                                                        i32.or
                                                                                                        local.get 2
                                                                                                        i32.const 255
                                                                                                        i32.and
                                                                                                        i32.const 70
                                                                                                        i32.ne
                                                                                                        i32.or
                                                                                                        br_if 31 (;@19;)
                                                                                                        local.get 0
                                                                                                        i32.const 208
                                                                                                        i32.add
                                                                                                        local.get 0
                                                                                                        i32.const 516
                                                                                                        i32.add
                                                                                                        call 35
                                                                                                        local.get 0
                                                                                                        i32.load8_u offset=208
                                                                                                        br_if 31 (;@19;)
                                                                                                        i32.const 4
                                                                                                        local.set 3
                                                                                                        local.get 0
                                                                                                        i32.const 380
                                                                                                        i32.add
                                                                                                        local.get 0
                                                                                                        i32.const 215
                                                                                                        i32.add
                                                                                                        i32.load8_u
                                                                                                        i32.store8
                                                                                                        local.get 0
                                                                                                        i32.const 400
                                                                                                        i32.add
                                                                                                        local.get 0
                                                                                                        i32.const 240
                                                                                                        i32.add
                                                                                                        i32.load8_u
                                                                                                        i32.store8
                                                                                                        local.get 0
                                                                                                        local.get 0
                                                                                                        i32.load offset=211 align=1
                                                                                                        i32.store offset=376
                                                                                                        local.get 0
                                                                                                        local.get 0
                                                                                                        i64.load offset=232 align=1
                                                                                                        i64.store offset=392
                                                                                                        local.get 0
                                                                                                        i32.const 224
                                                                                                        i32.add
                                                                                                        i64.load align=1
                                                                                                        local.tee 13
                                                                                                        i64.const 56
                                                                                                        i64.shl
                                                                                                        local.get 0
                                                                                                        i64.load offset=216 align=1
                                                                                                        local.tee 15
                                                                                                        i64.const 8
                                                                                                        i64.shr_u
                                                                                                        i64.or
                                                                                                        local.set 16
                                                                                                        local.get 13
                                                                                                        i64.const 8
                                                                                                        i64.shr_u
                                                                                                        local.set 14
                                                                                                        local.get 0
                                                                                                        i32.load8_u offset=210
                                                                                                        local.set 4
                                                                                                        local.get 0
                                                                                                        i32.load8_u offset=209
                                                                                                        local.set 1
                                                                                                        local.get 15
                                                                                                        i32.wrap_i64
                                                                                                        local.set 2
                                                                                                        br 33 (;@17;)
                                                                                                      end
                                                                                                      local.get 3
                                                                                                      i32.const 20
                                                                                                      i32.ne
                                                                                                      local.get 4
                                                                                                      i32.const 255
                                                                                                      i32.and
                                                                                                      i32.const 45
                                                                                                      i32.ne
                                                                                                      i32.or
                                                                                                      local.get 2
                                                                                                      i32.const 255
                                                                                                      i32.and
                                                                                                      i32.const 143
                                                                                                      i32.ne
                                                                                                      i32.or
                                                                                                      br_if 30 (;@19;)
                                                                                                      local.get 0
                                                                                                      i32.const 208
                                                                                                      i32.add
                                                                                                      local.get 0
                                                                                                      i32.const 516
                                                                                                      i32.add
                                                                                                      call 35
                                                                                                      local.get 0
                                                                                                      i32.load8_u offset=208
                                                                                                      br_if 30 (;@19;)
                                                                                                      local.get 0
                                                                                                      i32.const 380
                                                                                                      i32.add
                                                                                                      local.get 0
                                                                                                      i32.const 215
                                                                                                      i32.add
                                                                                                      i32.load8_u
                                                                                                      i32.store8
                                                                                                      local.get 0
                                                                                                      i32.const 400
                                                                                                      i32.add
                                                                                                      local.get 0
                                                                                                      i32.const 240
                                                                                                      i32.add
                                                                                                      i32.load8_u
                                                                                                      i32.store8
                                                                                                      local.get 0
                                                                                                      local.get 0
                                                                                                      i32.load offset=211 align=1
                                                                                                      i32.store offset=376
                                                                                                      local.get 0
                                                                                                      local.get 0
                                                                                                      i64.load offset=232 align=1
                                                                                                      i64.store offset=392
                                                                                                      local.get 0
                                                                                                      i32.const 224
                                                                                                      i32.add
                                                                                                      i64.load align=1
                                                                                                      local.tee 13
                                                                                                      i64.const 56
                                                                                                      i64.shl
                                                                                                      local.get 0
                                                                                                      i64.load offset=216 align=1
                                                                                                      local.tee 15
                                                                                                      i64.const 8
                                                                                                      i64.shr_u
                                                                                                      i64.or
                                                                                                      local.set 16
                                                                                                      local.get 13
                                                                                                      i64.const 8
                                                                                                      i64.shr_u
                                                                                                      local.set 14
                                                                                                      local.get 0
                                                                                                      i32.load8_u offset=210
                                                                                                      local.set 4
                                                                                                      local.get 0
                                                                                                      i32.load8_u offset=209
                                                                                                      local.set 1
                                                                                                      local.get 15
                                                                                                      i32.wrap_i64
                                                                                                      local.set 2
                                                                                                      i32.const 5
                                                                                                      local.set 3
                                                                                                      br 32 (;@17;)
                                                                                                    end
                                                                                                    local.get 3
                                                                                                    i32.const 132
                                                                                                    i32.ne
                                                                                                    local.get 4
                                                                                                    i32.const 255
                                                                                                    i32.and
                                                                                                    i32.const 140
                                                                                                    i32.ne
                                                                                                    i32.or
                                                                                                    local.get 2
                                                                                                    i32.const 255
                                                                                                    i32.and
                                                                                                    i32.const 22
                                                                                                    i32.ne
                                                                                                    i32.or
                                                                                                    br_if 29 (;@19;)
                                                                                                    local.get 0
                                                                                                    i32.const 208
                                                                                                    i32.add
                                                                                                    local.get 0
                                                                                                    i32.const 516
                                                                                                    i32.add
                                                                                                    call 35
                                                                                                    local.get 0
                                                                                                    i32.load8_u offset=208
                                                                                                    br_if 29 (;@19;)
                                                                                                    local.get 0
                                                                                                    i32.const 380
                                                                                                    i32.add
                                                                                                    local.get 0
                                                                                                    i32.const 215
                                                                                                    i32.add
                                                                                                    i32.load8_u
                                                                                                    i32.store8
                                                                                                    local.get 0
                                                                                                    i32.const 400
                                                                                                    i32.add
                                                                                                    local.get 0
                                                                                                    i32.const 240
                                                                                                    i32.add
                                                                                                    i32.load8_u
                                                                                                    i32.store8
                                                                                                    local.get 0
                                                                                                    local.get 0
                                                                                                    i32.load offset=211 align=1
                                                                                                    i32.store offset=376
                                                                                                    local.get 0
                                                                                                    local.get 0
                                                                                                    i64.load offset=232 align=1
                                                                                                    i64.store offset=392
                                                                                                    local.get 0
                                                                                                    i32.const 224
                                                                                                    i32.add
                                                                                                    i64.load align=1
                                                                                                    local.tee 13
                                                                                                    i64.const 56
                                                                                                    i64.shl
                                                                                                    local.get 0
                                                                                                    i64.load offset=216 align=1
                                                                                                    local.tee 15
                                                                                                    i64.const 8
                                                                                                    i64.shr_u
                                                                                                    i64.or
                                                                                                    local.set 16
                                                                                                    local.get 13
                                                                                                    i64.const 8
                                                                                                    i64.shr_u
                                                                                                    local.set 14
                                                                                                    local.get 0
                                                                                                    i32.load8_u offset=210
                                                                                                    local.set 4
                                                                                                    local.get 0
                                                                                                    i32.load8_u offset=209
                                                                                                    local.set 1
                                                                                                    local.get 15
                                                                                                    i32.wrap_i64
                                                                                                    local.set 2
                                                                                                    i32.const 6
                                                                                                    local.set 3
                                                                                                    br 31 (;@17;)
                                                                                                  end
                                                                                                  local.get 3
                                                                                                  i32.const 143
                                                                                                  i32.ne
                                                                                                  local.get 4
                                                                                                  i32.const 255
                                                                                                  i32.and
                                                                                                  i32.const 148
                                                                                                  i32.ne
                                                                                                  i32.or
                                                                                                  local.get 2
                                                                                                  i32.const 255
                                                                                                  i32.and
                                                                                                  i32.const 163
                                                                                                  i32.ne
                                                                                                  i32.or
                                                                                                  br_if 28 (;@19;)
                                                                                                  local.get 0
                                                                                                  i32.const 208
                                                                                                  i32.add
                                                                                                  local.get 0
                                                                                                  i32.const 516
                                                                                                  i32.add
                                                                                                  call 35
                                                                                                  local.get 0
                                                                                                  i32.load8_u offset=208
                                                                                                  br_if 28 (;@19;)
                                                                                                  i32.const 7
                                                                                                  local.set 3
                                                                                                  local.get 0
                                                                                                  i32.const 380
                                                                                                  i32.add
                                                                                                  local.get 0
                                                                                                  i32.const 215
                                                                                                  i32.add
                                                                                                  i32.load8_u
                                                                                                  i32.store8
                                                                                                  local.get 0
                                                                                                  i32.const 400
                                                                                                  i32.add
                                                                                                  local.get 0
                                                                                                  i32.const 240
                                                                                                  i32.add
                                                                                                  i32.load8_u
                                                                                                  i32.store8
                                                                                                  local.get 0
                                                                                                  local.get 0
                                                                                                  i32.load offset=211 align=1
                                                                                                  i32.store offset=376
                                                                                                  local.get 0
                                                                                                  local.get 0
                                                                                                  i64.load offset=232 align=1
                                                                                                  i64.store offset=392
                                                                                                  local.get 0
                                                                                                  i32.const 224
                                                                                                  i32.add
                                                                                                  i64.load align=1
                                                                                                  local.tee 13
                                                                                                  i64.const 56
                                                                                                  i64.shl
                                                                                                  local.get 0
                                                                                                  i64.load offset=216 align=1
                                                                                                  local.tee 15
                                                                                                  i64.const 8
                                                                                                  i64.shr_u
                                                                                                  i64.or
                                                                                                  local.set 16
                                                                                                  local.get 13
                                                                                                  i64.const 8
                                                                                                  i64.shr_u
                                                                                                  local.set 14
                                                                                                  local.get 0
                                                                                                  i32.load8_u offset=210
                                                                                                  local.set 4
                                                                                                  local.get 0
                                                                                                  i32.load8_u offset=209
                                                                                                  local.set 1
                                                                                                  local.get 15
                                                                                                  i32.wrap_i64
                                                                                                  local.set 2
                                                                                                  br 30 (;@17;)
                                                                                                end
                                                                                                local.get 3
                                                                                                i32.const 96
                                                                                                i32.ne
                                                                                                local.get 4
                                                                                                i32.const 255
                                                                                                i32.and
                                                                                                i32.const 54
                                                                                                i32.ne
                                                                                                i32.or
                                                                                                local.get 2
                                                                                                i32.const 255
                                                                                                i32.and
                                                                                                i32.const 23
                                                                                                i32.ne
                                                                                                i32.or
                                                                                                br_if 27 (;@19;)
                                                                                                local.get 0
                                                                                                i32.const 208
                                                                                                i32.add
                                                                                                local.get 0
                                                                                                i32.const 516
                                                                                                i32.add
                                                                                                call 35
                                                                                                local.get 0
                                                                                                i32.load8_u offset=208
                                                                                                br_if 27 (;@19;)
                                                                                                local.get 0
                                                                                                i32.const 380
                                                                                                i32.add
                                                                                                local.get 0
                                                                                                i32.const 215
                                                                                                i32.add
                                                                                                i32.load8_u
                                                                                                i32.store8
                                                                                                i32.const 8
                                                                                                local.set 3
                                                                                                local.get 0
                                                                                                i32.const 400
                                                                                                i32.add
                                                                                                local.get 0
                                                                                                i32.const 240
                                                                                                i32.add
                                                                                                i32.load8_u
                                                                                                i32.store8
                                                                                                local.get 0
                                                                                                local.get 0
                                                                                                i32.load offset=211 align=1
                                                                                                i32.store offset=376
                                                                                                local.get 0
                                                                                                local.get 0
                                                                                                i64.load offset=232 align=1
                                                                                                i64.store offset=392
                                                                                                local.get 0
                                                                                                i32.const 224
                                                                                                i32.add
                                                                                                i64.load align=1
                                                                                                local.tee 13
                                                                                                i64.const 56
                                                                                                i64.shl
                                                                                                local.get 0
                                                                                                i64.load offset=216 align=1
                                                                                                local.tee 15
                                                                                                i64.const 8
                                                                                                i64.shr_u
                                                                                                i64.or
                                                                                                local.set 16
                                                                                                local.get 13
                                                                                                i64.const 8
                                                                                                i64.shr_u
                                                                                                local.set 14
                                                                                                local.get 0
                                                                                                i32.load8_u offset=210
                                                                                                local.set 4
                                                                                                local.get 0
                                                                                                i32.load8_u offset=209
                                                                                                local.set 1
                                                                                                local.get 15
                                                                                                i32.wrap_i64
                                                                                                local.set 2
                                                                                                br 29 (;@17;)
                                                                                              end
                                                                                              local.get 4
                                                                                              i32.const 255
                                                                                              i32.and
                                                                                              local.tee 1
                                                                                              i32.const 50
                                                                                              i32.eq
                                                                                              br_if 23 (;@22;)
                                                                                              local.get 1
                                                                                              i32.const 129
                                                                                              i32.ne
                                                                                              local.get 3
                                                                                              i32.const 179
                                                                                              i32.ne
                                                                                              i32.or
                                                                                              local.get 2
                                                                                              i32.const 255
                                                                                              i32.and
                                                                                              i32.const 248
                                                                                              i32.ne
                                                                                              i32.or
                                                                                              br_if 26 (;@19;)
                                                                                              local.get 0
                                                                                              i32.const 208
                                                                                              i32.add
                                                                                              local.get 0
                                                                                              i32.const 516
                                                                                              i32.add
                                                                                              local.tee 2
                                                                                              call 35
                                                                                              local.get 0
                                                                                              i32.load8_u offset=208
                                                                                              br_if 26 (;@19;)
                                                                                              local.get 0
                                                                                              i32.const 456
                                                                                              i32.add
                                                                                              local.get 2
                                                                                              call 22
                                                                                              local.get 0
                                                                                              i32.load offset=456
                                                                                              br_if 26 (;@19;)
                                                                                              local.get 0
                                                                                              i32.const 472
                                                                                              i32.add
                                                                                              i64.load
                                                                                              local.set 13
                                                                                              local.get 0
                                                                                              i64.load offset=464
                                                                                              local.set 14
                                                                                              local.get 2
                                                                                              call 58
                                                                                              i32.const 255
                                                                                              i32.and
                                                                                              local.tee 1
                                                                                              i32.const 2
                                                                                              i32.eq
                                                                                              br_if 26 (;@19;)
                                                                                              local.get 2
                                                                                              call 59
                                                                                              i32.const 255
                                                                                              i32.and
                                                                                              local.tee 3
                                                                                              i32.const 3
                                                                                              i32.eq
                                                                                              br_if 26 (;@19;)
                                                                                              local.get 2
                                                                                              call 58
                                                                                              i32.const 255
                                                                                              i32.and
                                                                                              local.tee 4
                                                                                              i32.const 2
                                                                                              i32.eq
                                                                                              br_if 26 (;@19;)
                                                                                              local.get 0
                                                                                              i32.const 400
                                                                                              i32.add
                                                                                              local.get 0
                                                                                              i32.const 233
                                                                                              i32.add
                                                                                              i32.load8_u
                                                                                              i32.store8
                                                                                              local.get 0
                                                                                              i32.const 103
                                                                                              i32.add
                                                                                              local.get 13
                                                                                              i64.store align=1
                                                                                              local.get 0
                                                                                              local.get 0
                                                                                              i64.load offset=225 align=1
                                                                                              i64.store offset=392
                                                                                              local.get 0
                                                                                              local.get 0
                                                                                              i32.load offset=234 align=1
                                                                                              i32.store offset=88
                                                                                              local.get 0
                                                                                              local.get 0
                                                                                              i32.const 237
                                                                                              i32.add
                                                                                              i32.load align=1
                                                                                              i32.store offset=91 align=1
                                                                                              local.get 0
                                                                                              local.get 14
                                                                                              i64.store offset=95 align=1
                                                                                              local.get 0
                                                                                              local.get 4
                                                                                              i32.store8 offset=113
                                                                                              local.get 0
                                                                                              local.get 3
                                                                                              i32.store8 offset=112
                                                                                              local.get 0
                                                                                              local.get 1
                                                                                              i32.store8 offset=111
                                                                                              local.get 0
                                                                                              i32.const 218
                                                                                              i32.add
                                                                                              i64.load32_u align=1
                                                                                              local.get 0
                                                                                              i32.const 224
                                                                                              i32.add
                                                                                              i64.load8_u
                                                                                              i64.const 48
                                                                                              i64.shl
                                                                                              local.get 0
                                                                                              i32.const 222
                                                                                              i32.add
                                                                                              i64.load16_u align=1
                                                                                              i64.const 32
                                                                                              i64.shl
                                                                                              i64.or
                                                                                              i64.or
                                                                                              local.set 14
                                                                                              local.get 0
                                                                                              i64.load offset=210 align=1
                                                                                              local.set 16
                                                                                              local.get 0
                                                                                              i32.load8_u offset=209
                                                                                              local.set 2
                                                                                              i32.const 17
                                                                                              local.set 3
                                                                                              br 28 (;@17;)
                                                                                            end
                                                                                            local.get 3
                                                                                            i32.const 56
                                                                                            i32.ne
                                                                                            local.get 4
                                                                                            i32.const 255
                                                                                            i32.and
                                                                                            i32.const 213
                                                                                            i32.ne
                                                                                            i32.or
                                                                                            local.get 2
                                                                                            i32.const 255
                                                                                            i32.and
                                                                                            i32.const 17
                                                                                            i32.ne
                                                                                            i32.or
                                                                                            br_if 25 (;@19;)
                                                                                            local.get 0
                                                                                            i32.const 208
                                                                                            i32.add
                                                                                            local.get 0
                                                                                            i32.const 516
                                                                                            i32.add
                                                                                            call 22
                                                                                            local.get 0
                                                                                            i32.load offset=208
                                                                                            br_if 25 (;@19;)
                                                                                            local.get 0
                                                                                            i32.const 224
                                                                                            i32.add
                                                                                            i64.load
                                                                                            local.tee 13
                                                                                            i64.const 56
                                                                                            i64.shl
                                                                                            local.get 0
                                                                                            i64.load offset=216
                                                                                            local.tee 15
                                                                                            i64.const 8
                                                                                            i64.shr_u
                                                                                            i64.or
                                                                                            local.set 16
                                                                                            local.get 13
                                                                                            i64.const 8
                                                                                            i64.shr_u
                                                                                            local.set 14
                                                                                            local.get 15
                                                                                            i32.wrap_i64
                                                                                            local.set 2
                                                                                            i32.const 10
                                                                                            local.set 3
                                                                                            br 27 (;@17;)
                                                                                          end
                                                                                          local.get 4
                                                                                          i32.const 255
                                                                                          i32.and
                                                                                          local.tee 1
                                                                                          i32.const 92
                                                                                          i32.eq
                                                                                          br_if 22 (;@21;)
                                                                                          local.get 1
                                                                                          i32.const 226
                                                                                          i32.ne
                                                                                          local.get 3
                                                                                          i32.const 33
                                                                                          i32.ne
                                                                                          i32.or
                                                                                          local.get 2
                                                                                          i32.const 255
                                                                                          i32.and
                                                                                          i32.const 178
                                                                                          i32.ne
                                                                                          i32.or
                                                                                          br_if 24 (;@19;)
                                                                                          local.get 0
                                                                                          i32.const 208
                                                                                          i32.add
                                                                                          local.get 0
                                                                                          i32.const 516
                                                                                          i32.add
                                                                                          local.tee 1
                                                                                          call 35
                                                                                          local.get 0
                                                                                          i32.load8_u offset=208
                                                                                          br_if 24 (;@19;)
                                                                                          local.get 1
                                                                                          local.get 0
                                                                                          i32.const 456
                                                                                          i32.add
                                                                                          call 21
                                                                                          br_if 24 (;@19;)
                                                                                          local.get 0
                                                                                          i32.const 380
                                                                                          i32.add
                                                                                          local.get 0
                                                                                          i32.const 215
                                                                                          i32.add
                                                                                          i32.load8_u
                                                                                          i32.store8
                                                                                          local.get 0
                                                                                          i32.const 400
                                                                                          i32.add
                                                                                          local.get 0
                                                                                          i32.const 240
                                                                                          i32.add
                                                                                          i32.load8_u
                                                                                          i32.store8
                                                                                          local.get 0
                                                                                          local.get 0
                                                                                          i32.load offset=211 align=1
                                                                                          i32.store offset=376
                                                                                          local.get 0
                                                                                          local.get 0
                                                                                          i64.load offset=232 align=1
                                                                                          i64.store offset=392
                                                                                          local.get 0
                                                                                          local.get 0
                                                                                          i64.load offset=456
                                                                                          i64.store offset=88
                                                                                          local.get 0
                                                                                          i32.const 224
                                                                                          i32.add
                                                                                          i64.load align=1
                                                                                          local.tee 13
                                                                                          i64.const 56
                                                                                          i64.shl
                                                                                          local.get 0
                                                                                          i64.load offset=216 align=1
                                                                                          local.tee 15
                                                                                          i64.const 8
                                                                                          i64.shr_u
                                                                                          i64.or
                                                                                          local.set 16
                                                                                          local.get 13
                                                                                          i64.const 8
                                                                                          i64.shr_u
                                                                                          local.set 14
                                                                                          local.get 0
                                                                                          i32.load8_u offset=209
                                                                                          local.set 1
                                                                                          local.get 0
                                                                                          i32.load8_u offset=210
                                                                                          local.set 4
                                                                                          local.get 15
                                                                                          i32.wrap_i64
                                                                                          local.set 2
                                                                                          i32.const 33
                                                                                          local.set 3
                                                                                          br 26 (;@17;)
                                                                                        end
                                                                                        local.get 3
                                                                                        i32.const 176
                                                                                        i32.ne
                                                                                        local.get 4
                                                                                        i32.const 255
                                                                                        i32.and
                                                                                        i32.const 177
                                                                                        i32.ne
                                                                                        i32.or
                                                                                        local.get 2
                                                                                        i32.const 255
                                                                                        i32.and
                                                                                        i32.const 230
                                                                                        i32.ne
                                                                                        i32.or
                                                                                        br_if 23 (;@19;)
                                                                                        local.get 0
                                                                                        i32.const 208
                                                                                        i32.add
                                                                                        local.get 0
                                                                                        i32.const 516
                                                                                        i32.add
                                                                                        local.tee 1
                                                                                        call 35
                                                                                        local.get 0
                                                                                        i32.load8_u offset=208
                                                                                        br_if 23 (;@19;)
                                                                                        local.get 0
                                                                                        i32.const 456
                                                                                        i32.add
                                                                                        local.get 1
                                                                                        call 22
                                                                                        local.get 0
                                                                                        i32.load offset=456
                                                                                        br_if 23 (;@19;)
                                                                                        local.get 0
                                                                                        i32.const 472
                                                                                        i32.add
                                                                                        i64.load
                                                                                        local.set 13
                                                                                        local.get 0
                                                                                        i64.load offset=464
                                                                                        local.set 14
                                                                                        local.get 1
                                                                                        call 59
                                                                                        i32.const 255
                                                                                        i32.and
                                                                                        local.tee 1
                                                                                        i32.const 3
                                                                                        i32.eq
                                                                                        br_if 23 (;@19;)
                                                                                        local.get 0
                                                                                        i32.const 400
                                                                                        i32.add
                                                                                        local.get 0
                                                                                        i32.const 233
                                                                                        i32.add
                                                                                        i32.load8_u
                                                                                        i32.store8
                                                                                        local.get 0
                                                                                        i32.const 103
                                                                                        i32.add
                                                                                        local.get 13
                                                                                        i64.store align=1
                                                                                        local.get 0
                                                                                        local.get 0
                                                                                        i64.load offset=225 align=1
                                                                                        i64.store offset=392
                                                                                        local.get 0
                                                                                        local.get 0
                                                                                        i32.load offset=234 align=1
                                                                                        i32.store offset=88
                                                                                        local.get 0
                                                                                        local.get 0
                                                                                        i32.const 237
                                                                                        i32.add
                                                                                        i32.load align=1
                                                                                        i32.store offset=91 align=1
                                                                                        local.get 0
                                                                                        local.get 14
                                                                                        i64.store offset=95 align=1
                                                                                        local.get 0
                                                                                        local.get 1
                                                                                        i32.store8 offset=111
                                                                                        local.get 0
                                                                                        i32.const 218
                                                                                        i32.add
                                                                                        i64.load32_u align=1
                                                                                        local.get 0
                                                                                        i32.const 224
                                                                                        i32.add
                                                                                        i64.load8_u
                                                                                        i64.const 48
                                                                                        i64.shl
                                                                                        local.get 0
                                                                                        i32.const 222
                                                                                        i32.add
                                                                                        i64.load16_u align=1
                                                                                        i64.const 32
                                                                                        i64.shl
                                                                                        i64.or
                                                                                        i64.or
                                                                                        local.set 14
                                                                                        local.get 0
                                                                                        i64.load offset=210 align=1
                                                                                        local.set 16
                                                                                        local.get 0
                                                                                        i32.load8_u offset=209
                                                                                        local.set 2
                                                                                        i32.const 12
                                                                                        local.set 3
                                                                                        br 25 (;@17;)
                                                                                      end
                                                                                      local.get 3
                                                                                      i32.const 149
                                                                                      i32.ne
                                                                                      local.get 4
                                                                                      i32.const 255
                                                                                      i32.and
                                                                                      i32.const 32
                                                                                      i32.ne
                                                                                      i32.or
                                                                                      local.get 2
                                                                                      i32.const 255
                                                                                      i32.and
                                                                                      i32.const 114
                                                                                      i32.ne
                                                                                      i32.or
                                                                                      br_if 22 (;@19;)
                                                                                      local.get 0
                                                                                      i32.const 208
                                                                                      i32.add
                                                                                      local.get 0
                                                                                      i32.const 516
                                                                                      i32.add
                                                                                      local.tee 2
                                                                                      call 35
                                                                                      local.get 0
                                                                                      i32.load8_u offset=208
                                                                                      br_if 22 (;@19;)
                                                                                      local.get 2
                                                                                      call 59
                                                                                      i32.const 255
                                                                                      i32.and
                                                                                      local.tee 1
                                                                                      i32.const 3
                                                                                      i32.eq
                                                                                      br_if 22 (;@19;)
                                                                                      local.get 2
                                                                                      call 58
                                                                                      i32.const 255
                                                                                      i32.and
                                                                                      local.tee 2
                                                                                      i32.const 2
                                                                                      i32.eq
                                                                                      br_if 22 (;@19;)
                                                                                      local.get 0
                                                                                      i32.const 380
                                                                                      i32.add
                                                                                      local.get 0
                                                                                      i32.const 214
                                                                                      i32.add
                                                                                      i32.load8_u
                                                                                      i32.store8
                                                                                      local.get 0
                                                                                      i32.const 400
                                                                                      i32.add
                                                                                      local.get 0
                                                                                      i32.const 239
                                                                                      i32.add
                                                                                      i32.load8_u
                                                                                      i32.store8
                                                                                      local.get 0
                                                                                      local.get 0
                                                                                      i32.load offset=210 align=1
                                                                                      i32.store offset=376
                                                                                      local.get 0
                                                                                      local.get 0
                                                                                      i64.load offset=231 align=1
                                                                                      i64.store offset=392
                                                                                      local.get 0
                                                                                      local.get 0
                                                                                      i32.load8_u offset=240
                                                                                      i32.store8 offset=88
                                                                                      local.get 0
                                                                                      local.get 2
                                                                                      i32.store8 offset=89
                                                                                      local.get 0
                                                                                      i32.const 223
                                                                                      i32.add
                                                                                      i64.load align=1
                                                                                      local.tee 13
                                                                                      i64.const 56
                                                                                      i64.shl
                                                                                      local.get 0
                                                                                      i64.load offset=215 align=1
                                                                                      local.tee 15
                                                                                      i64.const 8
                                                                                      i64.shr_u
                                                                                      i64.or
                                                                                      local.set 16
                                                                                      local.get 13
                                                                                      i64.const 8
                                                                                      i64.shr_u
                                                                                      local.set 14
                                                                                      local.get 0
                                                                                      i32.load8_u offset=209
                                                                                      local.set 4
                                                                                      local.get 15
                                                                                      i32.wrap_i64
                                                                                      local.set 2
                                                                                      i32.const 13
                                                                                      local.set 3
                                                                                      br 24 (;@17;)
                                                                                    end
                                                                                    local.get 3
                                                                                    i32.const 187
                                                                                    i32.ne
                                                                                    local.get 4
                                                                                    i32.const 255
                                                                                    i32.and
                                                                                    i32.const 19
                                                                                    i32.ne
                                                                                    i32.or
                                                                                    local.get 2
                                                                                    i32.const 255
                                                                                    i32.and
                                                                                    i32.const 78
                                                                                    i32.ne
                                                                                    i32.or
                                                                                    br_if 21 (;@19;)
                                                                                    local.get 0
                                                                                    i32.const 208
                                                                                    i32.add
                                                                                    local.get 0
                                                                                    i32.const 516
                                                                                    i32.add
                                                                                    local.tee 1
                                                                                    call 35
                                                                                    local.get 0
                                                                                    i32.load8_u offset=208
                                                                                    br_if 21 (;@19;)
                                                                                    local.get 0
                                                                                    i32.const 456
                                                                                    i32.add
                                                                                    local.get 1
                                                                                    call 22
                                                                                    local.get 0
                                                                                    i32.load offset=456
                                                                                    br_if 21 (;@19;)
                                                                                    local.get 0
                                                                                    i32.const 472
                                                                                    i32.add
                                                                                    i64.load
                                                                                    local.set 13
                                                                                    local.get 0
                                                                                    i64.load offset=464
                                                                                    local.set 14
                                                                                    local.get 0
                                                                                    i32.const 16
                                                                                    i32.add
                                                                                    local.get 1
                                                                                    call 18
                                                                                    local.get 0
                                                                                    i32.load8_u offset=16
                                                                                    br_if 21 (;@19;)
                                                                                    i32.const 1
                                                                                    i32.const 2
                                                                                    local.get 0
                                                                                    i32.load8_u offset=17
                                                                                    local.tee 1
                                                                                    i32.const 1
                                                                                    i32.eq
                                                                                    select
                                                                                    i32.const 0
                                                                                    local.get 1
                                                                                    select
                                                                                    local.tee 1
                                                                                    i32.const 2
                                                                                    i32.eq
                                                                                    br_if 21 (;@19;)
                                                                                    local.get 0
                                                                                    i32.const 400
                                                                                    i32.add
                                                                                    local.get 0
                                                                                    i32.const 233
                                                                                    i32.add
                                                                                    i32.load8_u
                                                                                    i32.store8
                                                                                    local.get 0
                                                                                    i32.const 103
                                                                                    i32.add
                                                                                    local.get 13
                                                                                    i64.store align=1
                                                                                    local.get 0
                                                                                    local.get 0
                                                                                    i64.load offset=225 align=1
                                                                                    i64.store offset=392
                                                                                    local.get 0
                                                                                    local.get 0
                                                                                    i32.load offset=234 align=1
                                                                                    i32.store offset=88
                                                                                    local.get 0
                                                                                    local.get 0
                                                                                    i32.const 237
                                                                                    i32.add
                                                                                    i32.load align=1
                                                                                    i32.store offset=91 align=1
                                                                                    local.get 0
                                                                                    local.get 14
                                                                                    i64.store offset=95 align=1
                                                                                    local.get 0
                                                                                    local.get 1
                                                                                    i32.store8 offset=111
                                                                                    i32.const 14
                                                                                    local.set 3
                                                                                    br 22 (;@18;)
                                                                                  end
                                                                                  local.get 3
                                                                                  i32.const 14
                                                                                  i32.ne
                                                                                  local.get 4
                                                                                  i32.const 255
                                                                                  i32.and
                                                                                  i32.const 161
                                                                                  i32.ne
                                                                                  i32.or
                                                                                  local.get 2
                                                                                  i32.const 255
                                                                                  i32.and
                                                                                  i32.const 144
                                                                                  i32.ne
                                                                                  i32.or
                                                                                  br_if 20 (;@19;)
                                                                                  local.get 0
                                                                                  i32.const 208
                                                                                  i32.add
                                                                                  local.get 0
                                                                                  i32.const 516
                                                                                  i32.add
                                                                                  call 36
                                                                                  local.get 0
                                                                                  i32.load offset=208
                                                                                  br_if 20 (;@19;)
                                                                                  local.get 0
                                                                                  i32.const 400
                                                                                  i32.add
                                                                                  local.get 0
                                                                                  i32.const 240
                                                                                  i32.add
                                                                                  i32.load8_u
                                                                                  i32.store8
                                                                                  local.get 0
                                                                                  i32.const 96
                                                                                  i32.add
                                                                                  local.get 0
                                                                                  i32.const 249
                                                                                  i32.add
                                                                                  i64.load align=1
                                                                                  i64.store
                                                                                  i32.const 15
                                                                                  local.set 3
                                                                                  local.get 0
                                                                                  i32.const 103
                                                                                  i32.add
                                                                                  local.get 0
                                                                                  i32.const 256
                                                                                  i32.add
                                                                                  i64.load align=1
                                                                                  i64.store align=1
                                                                                  local.get 0
                                                                                  local.get 0
                                                                                  i64.load offset=232
                                                                                  i64.store offset=392
                                                                                  local.get 0
                                                                                  local.get 0
                                                                                  i64.load offset=241 align=1
                                                                                  i64.store offset=88
                                                                                  local.get 0
                                                                                  i32.const 224
                                                                                  i32.add
                                                                                  i64.load
                                                                                  local.tee 13
                                                                                  i64.const 56
                                                                                  i64.shl
                                                                                  local.get 0
                                                                                  i64.load offset=216
                                                                                  local.tee 15
                                                                                  i64.const 8
                                                                                  i64.shr_u
                                                                                  i64.or
                                                                                  local.set 16
                                                                                  local.get 13
                                                                                  i64.const 8
                                                                                  i64.shr_u
                                                                                  local.set 14
                                                                                  local.get 15
                                                                                  i32.wrap_i64
                                                                                  local.set 2
                                                                                  br 22 (;@17;)
                                                                                end
                                                                                local.get 3
                                                                                i32.const 46
                                                                                i32.ne
                                                                                local.get 4
                                                                                i32.const 255
                                                                                i32.and
                                                                                i32.const 95
                                                                                i32.ne
                                                                                i32.or
                                                                                local.get 2
                                                                                i32.const 255
                                                                                i32.and
                                                                                i32.const 195
                                                                                i32.ne
                                                                                i32.or
                                                                                br_if 19 (;@19;)
                                                                                local.get 0
                                                                                i32.const 208
                                                                                i32.add
                                                                                local.get 0
                                                                                i32.const 516
                                                                                i32.add
                                                                                call 36
                                                                                local.get 0
                                                                                i32.load offset=208
                                                                                br_if 19 (;@19;)
                                                                                local.get 0
                                                                                i32.const 400
                                                                                i32.add
                                                                                local.get 0
                                                                                i32.const 240
                                                                                i32.add
                                                                                i32.load8_u
                                                                                i32.store8
                                                                                local.get 0
                                                                                i32.const 96
                                                                                i32.add
                                                                                local.get 0
                                                                                i32.const 249
                                                                                i32.add
                                                                                i64.load align=1
                                                                                i64.store
                                                                                local.get 0
                                                                                i32.const 103
                                                                                i32.add
                                                                                local.get 0
                                                                                i32.const 256
                                                                                i32.add
                                                                                i64.load align=1
                                                                                i64.store align=1
                                                                                local.get 0
                                                                                local.get 0
                                                                                i64.load offset=232
                                                                                i64.store offset=392
                                                                                local.get 0
                                                                                local.get 0
                                                                                i64.load offset=241 align=1
                                                                                i64.store offset=88
                                                                                i32.const 16
                                                                                local.set 3
                                                                                local.get 0
                                                                                i32.const 224
                                                                                i32.add
                                                                                i64.load
                                                                                local.tee 13
                                                                                i64.const 56
                                                                                i64.shl
                                                                                local.get 0
                                                                                i64.load offset=216
                                                                                local.tee 15
                                                                                i64.const 8
                                                                                i64.shr_u
                                                                                i64.or
                                                                                local.set 16
                                                                                local.get 13
                                                                                i64.const 8
                                                                                i64.shr_u
                                                                                local.set 14
                                                                                local.get 15
                                                                                i32.wrap_i64
                                                                                local.set 2
                                                                                br 21 (;@17;)
                                                                              end
                                                                              local.get 3
                                                                              i32.const 148
                                                                              i32.ne
                                                                              local.get 4
                                                                              i32.const 255
                                                                              i32.and
                                                                              i32.const 31
                                                                              i32.ne
                                                                              i32.or
                                                                              local.get 2
                                                                              i32.const 255
                                                                              i32.and
                                                                              i32.const 56
                                                                              i32.ne
                                                                              i32.or
                                                                              br_if 18 (;@19;)
                                                                              local.get 0
                                                                              i32.const 208
                                                                              i32.add
                                                                              local.get 0
                                                                              i32.const 516
                                                                              i32.add
                                                                              call 22
                                                                              local.get 0
                                                                              i32.load offset=208
                                                                              br_if 18 (;@19;)
                                                                              local.get 0
                                                                              i32.const 224
                                                                              i32.add
                                                                              i64.load
                                                                              local.tee 13
                                                                              i64.const 56
                                                                              i64.shl
                                                                              local.get 0
                                                                              i64.load offset=216
                                                                              local.tee 15
                                                                              i64.const 8
                                                                              i64.shr_u
                                                                              i64.or
                                                                              local.set 16
                                                                              local.get 13
                                                                              i64.const 8
                                                                              i64.shr_u
                                                                              local.set 14
                                                                              local.get 15
                                                                              i32.wrap_i64
                                                                              local.set 2
                                                                              i32.const 19
                                                                              local.set 3
                                                                              br 20 (;@17;)
                                                                            end
                                                                            local.get 3
                                                                            i32.const 165
                                                                            i32.ne
                                                                            local.get 4
                                                                            i32.const 255
                                                                            i32.and
                                                                            i32.const 157
                                                                            i32.ne
                                                                            i32.or
                                                                            local.get 2
                                                                            i32.const 255
                                                                            i32.and
                                                                            i32.const 178
                                                                            i32.ne
                                                                            i32.or
                                                                            br_if 17 (;@19;)
                                                                            local.get 0
                                                                            i32.const 208
                                                                            i32.add
                                                                            local.get 0
                                                                            i32.const 516
                                                                            i32.add
                                                                            call 22
                                                                            local.get 0
                                                                            i32.load offset=208
                                                                            br_if 17 (;@19;)
                                                                            local.get 0
                                                                            i32.const 224
                                                                            i32.add
                                                                            i64.load
                                                                            local.tee 13
                                                                            i64.const 56
                                                                            i64.shl
                                                                            local.get 0
                                                                            i64.load offset=216
                                                                            local.tee 15
                                                                            i64.const 8
                                                                            i64.shr_u
                                                                            i64.or
                                                                            local.set 16
                                                                            local.get 13
                                                                            i64.const 8
                                                                            i64.shr_u
                                                                            local.set 14
                                                                            local.get 15
                                                                            i32.wrap_i64
                                                                            local.set 2
                                                                            i32.const 20
                                                                            local.set 3
                                                                            br 19 (;@17;)
                                                                          end
                                                                          local.get 3
                                                                          i32.const 162
                                                                          i32.ne
                                                                          local.get 4
                                                                          i32.const 255
                                                                          i32.and
                                                                          i32.const 186
                                                                          i32.ne
                                                                          i32.or
                                                                          local.get 2
                                                                          i32.const 255
                                                                          i32.and
                                                                          i32.const 47
                                                                          i32.ne
                                                                          i32.or
                                                                          br_if 16 (;@19;)
                                                                          local.get 0
                                                                          i32.const 208
                                                                          i32.add
                                                                          local.get 0
                                                                          i32.const 516
                                                                          i32.add
                                                                          call 22
                                                                          local.get 0
                                                                          i32.load offset=208
                                                                          br_if 16 (;@19;)
                                                                          local.get 0
                                                                          i32.const 224
                                                                          i32.add
                                                                          i64.load
                                                                          local.tee 13
                                                                          i64.const 56
                                                                          i64.shl
                                                                          local.get 0
                                                                          i64.load offset=216
                                                                          local.tee 15
                                                                          i64.const 8
                                                                          i64.shr_u
                                                                          i64.or
                                                                          local.set 16
                                                                          local.get 13
                                                                          i64.const 8
                                                                          i64.shr_u
                                                                          local.set 14
                                                                          local.get 15
                                                                          i32.wrap_i64
                                                                          local.set 2
                                                                          i32.const 21
                                                                          local.set 3
                                                                          br 18 (;@17;)
                                                                        end
                                                                        local.get 3
                                                                        i32.const 162
                                                                        i32.ne
                                                                        local.get 4
                                                                        i32.const 255
                                                                        i32.and
                                                                        i32.const 221
                                                                        i32.ne
                                                                        i32.or
                                                                        local.get 2
                                                                        i32.const 255
                                                                        i32.and
                                                                        i32.const 154
                                                                        i32.ne
                                                                        i32.or
                                                                        br_if 15 (;@19;)
                                                                        local.get 0
                                                                        i32.const 208
                                                                        i32.add
                                                                        local.get 0
                                                                        i32.const 516
                                                                        i32.add
                                                                        call 36
                                                                        local.get 0
                                                                        i32.load offset=208
                                                                        br_if 15 (;@19;)
                                                                        local.get 0
                                                                        i32.const 400
                                                                        i32.add
                                                                        local.get 0
                                                                        i32.const 240
                                                                        i32.add
                                                                        i32.load8_u
                                                                        i32.store8
                                                                        local.get 0
                                                                        i32.const 96
                                                                        i32.add
                                                                        local.get 0
                                                                        i32.const 249
                                                                        i32.add
                                                                        i64.load align=1
                                                                        i64.store
                                                                        local.get 0
                                                                        i32.const 103
                                                                        i32.add
                                                                        local.get 0
                                                                        i32.const 256
                                                                        i32.add
                                                                        i64.load align=1
                                                                        i64.store align=1
                                                                        local.get 0
                                                                        local.get 0
                                                                        i64.load offset=232
                                                                        i64.store offset=392
                                                                        local.get 0
                                                                        local.get 0
                                                                        i64.load offset=241 align=1
                                                                        i64.store offset=88
                                                                        local.get 0
                                                                        i32.const 224
                                                                        i32.add
                                                                        i64.load
                                                                        local.tee 13
                                                                        i64.const 56
                                                                        i64.shl
                                                                        local.get 0
                                                                        i64.load offset=216
                                                                        local.tee 15
                                                                        i64.const 8
                                                                        i64.shr_u
                                                                        i64.or
                                                                        local.set 16
                                                                        local.get 13
                                                                        i64.const 8
                                                                        i64.shr_u
                                                                        local.set 14
                                                                        local.get 15
                                                                        i32.wrap_i64
                                                                        local.set 2
                                                                        i32.const 22
                                                                        local.set 3
                                                                        br 17 (;@17;)
                                                                      end
                                                                      local.get 3
                                                                      i32.const 187
                                                                      i32.ne
                                                                      local.get 4
                                                                      i32.const 255
                                                                      i32.and
                                                                      i32.const 33
                                                                      i32.ne
                                                                      i32.or
                                                                      local.get 2
                                                                      i32.const 255
                                                                      i32.and
                                                                      i32.const 43
                                                                      i32.ne
                                                                      i32.or
                                                                      br_if 14 (;@19;)
                                                                      local.get 0
                                                                      i32.const 208
                                                                      i32.add
                                                                      local.get 0
                                                                      i32.const 516
                                                                      i32.add
                                                                      local.tee 2
                                                                      call 35
                                                                      local.get 0
                                                                      i32.load8_u offset=208
                                                                      br_if 14 (;@19;)
                                                                      local.get 0
                                                                      i32.const 456
                                                                      i32.add
                                                                      local.get 2
                                                                      call 22
                                                                      local.get 0
                                                                      i32.load offset=456
                                                                      br_if 14 (;@19;)
                                                                      local.get 0
                                                                      i32.const 472
                                                                      i32.add
                                                                      i64.load
                                                                      local.set 13
                                                                      local.get 0
                                                                      i64.load offset=464
                                                                      local.set 14
                                                                      local.get 2
                                                                      call 59
                                                                      i32.const 255
                                                                      i32.and
                                                                      local.tee 1
                                                                      i32.const 3
                                                                      i32.eq
                                                                      br_if 14 (;@19;)
                                                                      local.get 2
                                                                      call 58
                                                                      i32.const 255
                                                                      i32.and
                                                                      local.tee 3
                                                                      i32.const 2
                                                                      i32.eq
                                                                      br_if 14 (;@19;)
                                                                      local.get 2
                                                                      call 58
                                                                      i32.const 255
                                                                      i32.and
                                                                      local.tee 4
                                                                      i32.const 2
                                                                      i32.eq
                                                                      br_if 14 (;@19;)
                                                                      local.get 0
                                                                      i32.const 400
                                                                      i32.add
                                                                      local.get 0
                                                                      i32.const 233
                                                                      i32.add
                                                                      i32.load8_u
                                                                      i32.store8
                                                                      local.get 0
                                                                      i32.const 103
                                                                      i32.add
                                                                      local.get 13
                                                                      i64.store align=1
                                                                      local.get 0
                                                                      local.get 0
                                                                      i64.load offset=225 align=1
                                                                      i64.store offset=392
                                                                      local.get 0
                                                                      local.get 0
                                                                      i32.load offset=234 align=1
                                                                      i32.store offset=88
                                                                      local.get 0
                                                                      local.get 0
                                                                      i32.const 237
                                                                      i32.add
                                                                      i32.load align=1
                                                                      i32.store offset=91 align=1
                                                                      local.get 0
                                                                      local.get 14
                                                                      i64.store offset=95 align=1
                                                                      local.get 0
                                                                      local.get 4
                                                                      i32.store8 offset=113
                                                                      local.get 0
                                                                      local.get 1
                                                                      i32.store8 offset=112
                                                                      local.get 0
                                                                      local.get 3
                                                                      i32.store8 offset=111
                                                                      local.get 0
                                                                      i32.const 218
                                                                      i32.add
                                                                      i64.load32_u align=1
                                                                      local.get 0
                                                                      i32.const 224
                                                                      i32.add
                                                                      i64.load8_u
                                                                      i64.const 48
                                                                      i64.shl
                                                                      local.get 0
                                                                      i32.const 222
                                                                      i32.add
                                                                      i64.load16_u align=1
                                                                      i64.const 32
                                                                      i64.shl
                                                                      i64.or
                                                                      i64.or
                                                                      local.set 14
                                                                      local.get 0
                                                                      i64.load offset=210 align=1
                                                                      local.set 16
                                                                      local.get 0
                                                                      i32.load8_u offset=209
                                                                      local.set 2
                                                                      i32.const 23
                                                                      local.set 3
                                                                      br 16 (;@17;)
                                                                    end
                                                                    local.get 3
                                                                    i32.const 17
                                                                    i32.ne
                                                                    local.get 4
                                                                    i32.const 255
                                                                    i32.and
                                                                    i32.const 146
                                                                    i32.ne
                                                                    i32.or
                                                                    local.get 2
                                                                    i32.const 255
                                                                    i32.and
                                                                    i32.const 220
                                                                    i32.ne
                                                                    i32.or
                                                                    br_if 13 (;@19;)
                                                                    local.get 0
                                                                    i32.const 208
                                                                    i32.add
                                                                    local.get 0
                                                                    i32.const 516
                                                                    i32.add
                                                                    call 36
                                                                    local.get 0
                                                                    i32.load offset=208
                                                                    br_if 13 (;@19;)
                                                                    local.get 0
                                                                    i32.const 400
                                                                    i32.add
                                                                    local.get 0
                                                                    i32.const 240
                                                                    i32.add
                                                                    i32.load8_u
                                                                    i32.store8
                                                                    local.get 0
                                                                    i32.const 96
                                                                    i32.add
                                                                    local.get 0
                                                                    i32.const 249
                                                                    i32.add
                                                                    i64.load align=1
                                                                    i64.store
                                                                    local.get 0
                                                                    i32.const 103
                                                                    i32.add
                                                                    local.get 0
                                                                    i32.const 256
                                                                    i32.add
                                                                    i64.load align=1
                                                                    i64.store align=1
                                                                    local.get 0
                                                                    local.get 0
                                                                    i64.load offset=232
                                                                    i64.store offset=392
                                                                    local.get 0
                                                                    local.get 0
                                                                    i64.load offset=241 align=1
                                                                    i64.store offset=88
                                                                    local.get 0
                                                                    i32.const 224
                                                                    i32.add
                                                                    i64.load
                                                                    local.tee 13
                                                                    i64.const 56
                                                                    i64.shl
                                                                    local.get 0
                                                                    i64.load offset=216
                                                                    local.tee 15
                                                                    i64.const 8
                                                                    i64.shr_u
                                                                    i64.or
                                                                    local.set 16
                                                                    local.get 13
                                                                    i64.const 8
                                                                    i64.shr_u
                                                                    local.set 14
                                                                    local.get 15
                                                                    i32.wrap_i64
                                                                    local.set 2
                                                                    i32.const 24
                                                                    local.set 3
                                                                    br 15 (;@17;)
                                                                  end
                                                                  local.get 3
                                                                  i32.const 183
                                                                  i32.ne
                                                                  local.get 4
                                                                  i32.const 255
                                                                  i32.and
                                                                  i32.const 81
                                                                  i32.ne
                                                                  i32.or
                                                                  local.get 2
                                                                  i32.const 255
                                                                  i32.and
                                                                  i32.const 188
                                                                  i32.ne
                                                                  i32.or
                                                                  br_if 12 (;@19;)
                                                                  local.get 0
                                                                  i32.const 208
                                                                  i32.add
                                                                  local.get 0
                                                                  i32.const 516
                                                                  i32.add
                                                                  call 36
                                                                  local.get 0
                                                                  i32.load offset=208
                                                                  br_if 12 (;@19;)
                                                                  local.get 0
                                                                  i32.const 400
                                                                  i32.add
                                                                  local.get 0
                                                                  i32.const 240
                                                                  i32.add
                                                                  i32.load8_u
                                                                  i32.store8
                                                                  local.get 0
                                                                  i32.const 96
                                                                  i32.add
                                                                  local.get 0
                                                                  i32.const 249
                                                                  i32.add
                                                                  i64.load align=1
                                                                  i64.store
                                                                  local.get 0
                                                                  i32.const 103
                                                                  i32.add
                                                                  local.get 0
                                                                  i32.const 256
                                                                  i32.add
                                                                  i64.load align=1
                                                                  i64.store align=1
                                                                  local.get 0
                                                                  local.get 0
                                                                  i64.load offset=232
                                                                  i64.store offset=392
                                                                  local.get 0
                                                                  local.get 0
                                                                  i64.load offset=241 align=1
                                                                  i64.store offset=88
                                                                  local.get 0
                                                                  i32.const 224
                                                                  i32.add
                                                                  i64.load
                                                                  local.tee 13
                                                                  i64.const 56
                                                                  i64.shl
                                                                  local.get 0
                                                                  i64.load offset=216
                                                                  local.tee 15
                                                                  i64.const 8
                                                                  i64.shr_u
                                                                  i64.or
                                                                  local.set 16
                                                                  local.get 13
                                                                  i64.const 8
                                                                  i64.shr_u
                                                                  local.set 14
                                                                  local.get 15
                                                                  i32.wrap_i64
                                                                  local.set 2
                                                                  i32.const 25
                                                                  local.set 3
                                                                  br 14 (;@17;)
                                                                end
                                                                local.get 3
                                                                i32.const 55
                                                                i32.ne
                                                                local.get 4
                                                                i32.const 255
                                                                i32.and
                                                                i32.const 165
                                                                i32.ne
                                                                i32.or
                                                                local.get 2
                                                                i32.const 255
                                                                i32.and
                                                                i32.const 93
                                                                i32.ne
                                                                i32.or
                                                                br_if 11 (;@19;)
                                                                local.get 0
                                                                i32.const 208
                                                                i32.add
                                                                local.get 0
                                                                i32.const 516
                                                                i32.add
                                                                call 36
                                                                local.get 0
                                                                i32.load offset=208
                                                                br_if 11 (;@19;)
                                                                local.get 0
                                                                i32.const 400
                                                                i32.add
                                                                local.get 0
                                                                i32.const 240
                                                                i32.add
                                                                i32.load8_u
                                                                i32.store8
                                                                local.get 0
                                                                i32.const 96
                                                                i32.add
                                                                local.get 0
                                                                i32.const 249
                                                                i32.add
                                                                i64.load align=1
                                                                i64.store
                                                                local.get 0
                                                                i32.const 103
                                                                i32.add
                                                                local.get 0
                                                                i32.const 256
                                                                i32.add
                                                                i64.load align=1
                                                                i64.store align=1
                                                                local.get 0
                                                                local.get 0
                                                                i64.load offset=232
                                                                i64.store offset=392
                                                                local.get 0
                                                                local.get 0
                                                                i64.load offset=241 align=1
                                                                i64.store offset=88
                                                                local.get 0
                                                                i32.const 224
                                                                i32.add
                                                                i64.load
                                                                local.tee 13
                                                                i64.const 56
                                                                i64.shl
                                                                local.get 0
                                                                i64.load offset=216
                                                                local.tee 15
                                                                i64.const 8
                                                                i64.shr_u
                                                                i64.or
                                                                local.set 16
                                                                local.get 13
                                                                i64.const 8
                                                                i64.shr_u
                                                                local.set 14
                                                                local.get 15
                                                                i32.wrap_i64
                                                                local.set 2
                                                                i32.const 26
                                                                local.set 3
                                                                br 13 (;@17;)
                                                              end
                                                              local.get 3
                                                              i32.const 161
                                                              i32.ne
                                                              local.get 4
                                                              i32.const 255
                                                              i32.and
                                                              i32.const 161
                                                              i32.ne
                                                              i32.or
                                                              local.get 2
                                                              i32.const 255
                                                              i32.and
                                                              i32.const 93
                                                              i32.ne
                                                              i32.or
                                                              br_if 10 (;@19;)
                                                              local.get 0
                                                              i32.const 208
                                                              i32.add
                                                              local.get 0
                                                              i32.const 516
                                                              i32.add
                                                              call 36
                                                              local.get 0
                                                              i32.load offset=208
                                                              br_if 10 (;@19;)
                                                              local.get 0
                                                              i32.const 400
                                                              i32.add
                                                              local.get 0
                                                              i32.const 240
                                                              i32.add
                                                              i32.load8_u
                                                              i32.store8
                                                              local.get 0
                                                              i32.const 96
                                                              i32.add
                                                              local.get 0
                                                              i32.const 249
                                                              i32.add
                                                              i64.load align=1
                                                              i64.store
                                                              local.get 0
                                                              i32.const 103
                                                              i32.add
                                                              local.get 0
                                                              i32.const 256
                                                              i32.add
                                                              i64.load align=1
                                                              i64.store align=1
                                                              local.get 0
                                                              local.get 0
                                                              i64.load offset=232
                                                              i64.store offset=392
                                                              local.get 0
                                                              local.get 0
                                                              i64.load offset=241 align=1
                                                              i64.store offset=88
                                                              local.get 0
                                                              i32.const 224
                                                              i32.add
                                                              i64.load
                                                              local.tee 13
                                                              i64.const 56
                                                              i64.shl
                                                              local.get 0
                                                              i64.load offset=216
                                                              local.tee 15
                                                              i64.const 8
                                                              i64.shr_u
                                                              i64.or
                                                              local.set 16
                                                              local.get 13
                                                              i64.const 8
                                                              i64.shr_u
                                                              local.set 14
                                                              local.get 15
                                                              i32.wrap_i64
                                                              local.set 2
                                                              i32.const 27
                                                              local.set 3
                                                              br 12 (;@17;)
                                                            end
                                                            local.get 3
                                                            i32.const 241
                                                            i32.ne
                                                            local.get 4
                                                            i32.const 255
                                                            i32.and
                                                            i32.const 129
                                                            i32.ne
                                                            i32.or
                                                            local.get 2
                                                            i32.const 255
                                                            i32.and
                                                            i32.const 51
                                                            i32.ne
                                                            i32.or
                                                            br_if 9 (;@19;)
                                                            local.get 0
                                                            i32.const 208
                                                            i32.add
                                                            local.get 0
                                                            i32.const 516
                                                            i32.add
                                                            call 36
                                                            local.get 0
                                                            i32.load offset=208
                                                            br_if 9 (;@19;)
                                                            local.get 0
                                                            i32.const 400
                                                            i32.add
                                                            local.get 0
                                                            i32.const 240
                                                            i32.add
                                                            i32.load8_u
                                                            i32.store8
                                                            local.get 0
                                                            i32.const 96
                                                            i32.add
                                                            local.get 0
                                                            i32.const 249
                                                            i32.add
                                                            i64.load align=1
                                                            i64.store
                                                            local.get 0
                                                            i32.const 103
                                                            i32.add
                                                            local.get 0
                                                            i32.const 256
                                                            i32.add
                                                            i64.load align=1
                                                            i64.store align=1
                                                            local.get 0
                                                            local.get 0
                                                            i64.load offset=232
                                                            i64.store offset=392
                                                            local.get 0
                                                            local.get 0
                                                            i64.load offset=241 align=1
                                                            i64.store offset=88
                                                            local.get 0
                                                            i32.const 224
                                                            i32.add
                                                            i64.load
                                                            local.tee 13
                                                            i64.const 56
                                                            i64.shl
                                                            local.get 0
                                                            i64.load offset=216
                                                            local.tee 15
                                                            i64.const 8
                                                            i64.shr_u
                                                            i64.or
                                                            local.set 16
                                                            local.get 13
                                                            i64.const 8
                                                            i64.shr_u
                                                            local.set 14
                                                            local.get 15
                                                            i32.wrap_i64
                                                            local.set 2
                                                            i32.const 28
                                                            local.set 3
                                                            br 11 (;@17;)
                                                          end
                                                          local.get 3
                                                          i32.const 217
                                                          i32.ne
                                                          local.get 4
                                                          i32.const 255
                                                          i32.and
                                                          i32.const 157
                                                          i32.ne
                                                          i32.or
                                                          local.get 2
                                                          i32.const 255
                                                          i32.and
                                                          i32.const 105
                                                          i32.ne
                                                          i32.or
                                                          br_if 8 (;@19;)
                                                          local.get 0
                                                          i32.const 208
                                                          i32.add
                                                          local.get 0
                                                          i32.const 516
                                                          i32.add
                                                          local.tee 1
                                                          call 35
                                                          local.get 0
                                                          i32.load8_u offset=208
                                                          br_if 8 (;@19;)
                                                          local.get 0
                                                          i32.const 456
                                                          i32.add
                                                          local.get 1
                                                          call 22
                                                          local.get 0
                                                          i32.load offset=456
                                                          br_if 8 (;@19;)
                                                          local.get 0
                                                          i32.const 472
                                                          i32.add
                                                          i64.load
                                                          local.set 13
                                                          local.get 0
                                                          i64.load offset=464
                                                          local.set 14
                                                          local.get 1
                                                          call 59
                                                          i32.const 255
                                                          i32.and
                                                          local.tee 1
                                                          i32.const 3
                                                          i32.eq
                                                          br_if 8 (;@19;)
                                                          local.get 0
                                                          i32.const 400
                                                          i32.add
                                                          local.get 0
                                                          i32.const 233
                                                          i32.add
                                                          i32.load8_u
                                                          i32.store8
                                                          local.get 0
                                                          i32.const 103
                                                          i32.add
                                                          local.get 13
                                                          i64.store align=1
                                                          local.get 0
                                                          local.get 0
                                                          i64.load offset=225 align=1
                                                          i64.store offset=392
                                                          local.get 0
                                                          local.get 0
                                                          i32.load offset=234 align=1
                                                          i32.store offset=88
                                                          i32.const 29
                                                          local.set 3
                                                          local.get 0
                                                          local.get 0
                                                          i32.const 237
                                                          i32.add
                                                          i32.load align=1
                                                          i32.store offset=91 align=1
                                                          local.get 0
                                                          local.get 14
                                                          i64.store offset=95 align=1
                                                          local.get 0
                                                          local.get 1
                                                          i32.store8 offset=111
                                                          br 9 (;@18;)
                                                        end
                                                        local.get 3
                                                        i32.const 159
                                                        i32.ne
                                                        local.get 4
                                                        i32.const 255
                                                        i32.and
                                                        i32.const 234
                                                        i32.ne
                                                        i32.or
                                                        local.get 2
                                                        i32.const 255
                                                        i32.and
                                                        i32.const 134
                                                        i32.ne
                                                        i32.or
                                                        br_if 7 (;@19;)
                                                        local.get 0
                                                        i32.const 208
                                                        i32.add
                                                        local.get 0
                                                        i32.const 516
                                                        i32.add
                                                        call 36
                                                        local.get 0
                                                        i32.load offset=208
                                                        br_if 7 (;@19;)
                                                        local.get 0
                                                        i32.const 400
                                                        i32.add
                                                        local.get 0
                                                        i32.const 240
                                                        i32.add
                                                        i32.load8_u
                                                        i32.store8
                                                        local.get 0
                                                        i32.const 96
                                                        i32.add
                                                        local.get 0
                                                        i32.const 249
                                                        i32.add
                                                        i64.load align=1
                                                        i64.store
                                                        local.get 0
                                                        i32.const 103
                                                        i32.add
                                                        local.get 0
                                                        i32.const 256
                                                        i32.add
                                                        i64.load align=1
                                                        i64.store align=1
                                                        local.get 0
                                                        local.get 0
                                                        i64.load offset=232
                                                        i64.store offset=392
                                                        local.get 0
                                                        local.get 0
                                                        i64.load offset=241 align=1
                                                        i64.store offset=88
                                                        local.get 0
                                                        i32.const 224
                                                        i32.add
                                                        i64.load
                                                        local.tee 13
                                                        i64.const 56
                                                        i64.shl
                                                        local.get 0
                                                        i64.load offset=216
                                                        local.tee 15
                                                        i64.const 8
                                                        i64.shr_u
                                                        i64.or
                                                        local.set 16
                                                        local.get 13
                                                        i64.const 8
                                                        i64.shr_u
                                                        local.set 14
                                                        local.get 15
                                                        i32.wrap_i64
                                                        local.set 2
                                                        i32.const 30
                                                        local.set 3
                                                        br 9 (;@17;)
                                                      end
                                                      local.get 3
                                                      i32.const 20
                                                      i32.ne
                                                      local.get 4
                                                      i32.const 255
                                                      i32.and
                                                      i32.const 128
                                                      i32.ne
                                                      i32.or
                                                      local.get 2
                                                      i32.const 255
                                                      i32.and
                                                      i32.const 106
                                                      i32.ne
                                                      i32.or
                                                      br_if 6 (;@19;)
                                                      local.get 0
                                                      i32.const 208
                                                      i32.add
                                                      local.get 0
                                                      i32.const 516
                                                      i32.add
                                                      call 36
                                                      local.get 0
                                                      i32.load offset=208
                                                      br_if 6 (;@19;)
                                                      local.get 0
                                                      i32.const 400
                                                      i32.add
                                                      local.get 0
                                                      i32.const 240
                                                      i32.add
                                                      i32.load8_u
                                                      i32.store8
                                                      local.get 0
                                                      i32.const 96
                                                      i32.add
                                                      local.get 0
                                                      i32.const 249
                                                      i32.add
                                                      i64.load align=1
                                                      i64.store
                                                      local.get 0
                                                      i32.const 103
                                                      i32.add
                                                      local.get 0
                                                      i32.const 256
                                                      i32.add
                                                      i64.load align=1
                                                      i64.store align=1
                                                      local.get 0
                                                      local.get 0
                                                      i64.load offset=232
                                                      i64.store offset=392
                                                      local.get 0
                                                      local.get 0
                                                      i64.load offset=241 align=1
                                                      i64.store offset=88
                                                      local.get 0
                                                      i32.const 224
                                                      i32.add
                                                      i64.load
                                                      local.tee 13
                                                      i64.const 56
                                                      i64.shl
                                                      local.get 0
                                                      i64.load offset=216
                                                      local.tee 15
                                                      i64.const 8
                                                      i64.shr_u
                                                      i64.or
                                                      local.set 16
                                                      local.get 13
                                                      i64.const 8
                                                      i64.shr_u
                                                      local.set 14
                                                      local.get 15
                                                      i32.wrap_i64
                                                      local.set 2
                                                      i32.const 31
                                                      local.set 3
                                                      br 8 (;@17;)
                                                    end
                                                    local.get 3
                                                    i32.const 199
                                                    i32.ne
                                                    local.get 4
                                                    i32.const 255
                                                    i32.and
                                                    i32.const 161
                                                    i32.ne
                                                    i32.or
                                                    local.get 2
                                                    i32.const 255
                                                    i32.and
                                                    i32.const 128
                                                    i32.ne
                                                    i32.or
                                                    br_if 5 (;@19;)
                                                    local.get 0
                                                    i32.const 208
                                                    i32.add
                                                    local.get 0
                                                    i32.const 516
                                                    i32.add
                                                    local.tee 2
                                                    call 35
                                                    local.get 0
                                                    i32.load8_u offset=208
                                                    br_if 5 (;@19;)
                                                    local.get 2
                                                    local.get 0
                                                    i32.const 456
                                                    i32.add
                                                    local.tee 3
                                                    call 21
                                                    br_if 5 (;@19;)
                                                    local.get 0
                                                    i64.load offset=456
                                                    local.set 13
                                                    local.get 3
                                                    local.get 2
                                                    call 22
                                                    local.get 0
                                                    i32.load offset=456
                                                    br_if 5 (;@19;)
                                                    local.get 0
                                                    i32.const 400
                                                    i32.add
                                                    local.get 0
                                                    i32.const 233
                                                    i32.add
                                                    i32.load8_u
                                                    i32.store8
                                                    local.get 0
                                                    local.get 0
                                                    i64.load offset=225 align=1
                                                    i64.store offset=392
                                                    local.get 0
                                                    local.get 0
                                                    i32.load offset=234 align=1
                                                    i32.store offset=88
                                                    local.get 0
                                                    local.get 0
                                                    i32.const 237
                                                    i32.add
                                                    i32.load align=1
                                                    i32.store offset=91 align=1
                                                    local.get 0
                                                    local.get 0
                                                    i64.load offset=464
                                                    i64.store offset=103 align=1
                                                    local.get 0
                                                    local.get 13
                                                    i64.store offset=95 align=1
                                                    local.get 0
                                                    local.get 0
                                                    i32.const 472
                                                    i32.add
                                                    i64.load
                                                    i64.store offset=111 align=1
                                                    local.get 0
                                                    i32.const 217
                                                    i32.add
                                                    i64.load align=1
                                                    local.tee 13
                                                    i64.const 56
                                                    i64.shl
                                                    local.get 0
                                                    i64.load offset=209 align=1
                                                    local.tee 15
                                                    i64.const 8
                                                    i64.shr_u
                                                    i64.or
                                                    local.set 16
                                                    local.get 13
                                                    i64.const 8
                                                    i64.shr_u
                                                    local.set 14
                                                    local.get 15
                                                    i32.wrap_i64
                                                    local.set 2
                                                    i32.const 32
                                                    local.set 3
                                                    br 7 (;@17;)
                                                  end
                                                  local.get 3
                                                  i32.const 169
                                                  i32.ne
                                                  local.get 4
                                                  i32.const 255
                                                  i32.and
                                                  i32.const 252
                                                  i32.ne
                                                  i32.or
                                                  br_if 4 (;@19;)
                                                  local.get 2
                                                  i32.const 255
                                                  i32.and
                                                  i32.const 229
                                                  i32.eq
                                                  br_if 3 (;@20;)
                                                  br 4 (;@19;)
                                                end
                                                local.get 3
                                                i32.const 15
                                                i32.ne
                                                local.get 4
                                                i32.const 255
                                                i32.and
                                                i32.const 85
                                                i32.ne
                                                i32.or
                                                local.get 2
                                                i32.const 255
                                                i32.and
                                                i32.const 253
                                                i32.ne
                                                i32.or
                                                br_if 3 (;@19;)
                                                i32.const 35
                                                local.set 3
                                                br 5 (;@17;)
                                              end
                                              local.get 3
                                              i32.const 100
                                              i32.ne
                                              local.get 2
                                              i32.const 255
                                              i32.and
                                              i32.const 146
                                              i32.ne
                                              i32.or
                                              br_if 2 (;@19;)
                                              local.get 0
                                              i32.const 208
                                              i32.add
                                              local.get 0
                                              i32.const 516
                                              i32.add
                                              call 35
                                              local.get 0
                                              i32.load8_u offset=208
                                              br_if 2 (;@19;)
                                              local.get 0
                                              i32.const 380
                                              i32.add
                                              local.get 0
                                              i32.const 215
                                              i32.add
                                              i32.load8_u
                                              i32.store8
                                              local.get 0
                                              i32.const 400
                                              i32.add
                                              local.get 0
                                              i32.const 240
                                              i32.add
                                              i32.load8_u
                                              i32.store8
                                              local.get 0
                                              local.get 0
                                              i32.load offset=211 align=1
                                              i32.store offset=376
                                              local.get 0
                                              local.get 0
                                              i64.load offset=232 align=1
                                              i64.store offset=392
                                              local.get 0
                                              i32.const 224
                                              i32.add
                                              i64.load align=1
                                              local.tee 13
                                              i64.const 56
                                              i64.shl
                                              local.get 0
                                              i64.load offset=216 align=1
                                              local.tee 15
                                              i64.const 8
                                              i64.shr_u
                                              i64.or
                                              local.set 16
                                              local.get 13
                                              i64.const 8
                                              i64.shr_u
                                              local.set 14
                                              local.get 0
                                              i32.load8_u offset=210
                                              local.set 4
                                              local.get 0
                                              i32.load8_u offset=209
                                              local.set 1
                                              local.get 15
                                              i32.wrap_i64
                                              local.set 2
                                              i32.const 9
                                              local.set 3
                                              br 4 (;@17;)
                                            end
                                            local.get 3
                                            i32.const 247
                                            i32.ne
                                            local.get 2
                                            i32.const 255
                                            i32.and
                                            i32.const 168
                                            i32.ne
                                            i32.or
                                            br_if 1 (;@19;)
                                            local.get 0
                                            i32.const 208
                                            i32.add
                                            local.get 0
                                            i32.const 516
                                            i32.add
                                            local.tee 2
                                            call 35
                                            local.get 0
                                            i32.load8_u offset=208
                                            br_if 1 (;@19;)
                                            local.get 0
                                            i32.const 456
                                            i32.add
                                            local.get 2
                                            call 22
                                            local.get 0
                                            i32.load offset=456
                                            i32.const 1
                                            i32.eq
                                            br_if 1 (;@19;)
                                            local.get 0
                                            i32.const 400
                                            i32.add
                                            local.get 0
                                            i32.const 233
                                            i32.add
                                            i32.load8_u
                                            i32.store8
                                            local.get 0
                                            i32.const 103
                                            i32.add
                                            local.get 0
                                            i32.const 472
                                            i32.add
                                            i64.load
                                            i64.store align=1
                                            local.get 0
                                            local.get 0
                                            i64.load offset=225 align=1
                                            i64.store offset=392
                                            local.get 0
                                            local.get 0
                                            i32.load offset=234 align=1
                                            i32.store offset=88
                                            local.get 0
                                            local.get 0
                                            i32.const 237
                                            i32.add
                                            i32.load align=1
                                            i32.store offset=91 align=1
                                            local.get 0
                                            local.get 0
                                            i64.load offset=464
                                            i64.store offset=95 align=1
                                            local.get 0
                                            i32.const 217
                                            i32.add
                                            i64.load align=1
                                            local.tee 13
                                            i64.const 56
                                            i64.shl
                                            local.get 0
                                            i64.load offset=209 align=1
                                            local.tee 15
                                            i64.const 8
                                            i64.shr_u
                                            i64.or
                                            local.set 16
                                            local.get 13
                                            i64.const 8
                                            i64.shr_u
                                            local.set 14
                                            local.get 15
                                            i32.wrap_i64
                                            local.set 2
                                            i32.const 11
                                            local.set 3
                                            br 3 (;@17;)
                                          end
                                          local.get 0
                                          i32.const 208
                                          i32.add
                                          local.get 0
                                          i32.const 516
                                          i32.add
                                          call 56
                                          local.get 0
                                          i32.load8_u offset=208
                                          local.tee 1
                                          i32.const 2
                                          i32.eq
                                          br_if 0 (;@19;)
                                          local.get 0
                                          i32.const 380
                                          i32.add
                                          local.get 0
                                          i32.const 214
                                          i32.add
                                          i32.load8_u
                                          i32.store8
                                          local.get 0
                                          i32.const 400
                                          i32.add
                                          local.get 0
                                          i32.const 239
                                          i32.add
                                          i32.load8_u
                                          i32.store8
                                          local.get 0
                                          local.get 0
                                          i32.load offset=210 align=1
                                          i32.store offset=376
                                          local.get 0
                                          local.get 0
                                          i64.load offset=231 align=1
                                          i64.store offset=392
                                          local.get 0
                                          local.get 0
                                          i32.load8_u offset=240
                                          i32.store8 offset=88
                                          local.get 0
                                          i32.const 223
                                          i32.add
                                          i64.load align=1
                                          local.tee 13
                                          i64.const 56
                                          i64.shl
                                          local.get 0
                                          i64.load offset=215 align=1
                                          local.tee 15
                                          i64.const 8
                                          i64.shr_u
                                          i64.or
                                          local.set 16
                                          local.get 13
                                          i64.const 8
                                          i64.shr_u
                                          local.set 14
                                          local.get 0
                                          i32.load8_u offset=209
                                          local.set 4
                                          local.get 15
                                          i32.wrap_i64
                                          local.set 2
                                          i32.const 34
                                          local.set 3
                                          br 2 (;@17;)
                                        end
                                        call 53
                                        unreachable
                                      end
                                      local.get 0
                                      i32.const 218
                                      i32.add
                                      i64.load32_u align=1
                                      local.get 0
                                      i32.const 224
                                      i32.add
                                      i64.load8_u
                                      i64.const 48
                                      i64.shl
                                      local.get 0
                                      i32.const 222
                                      i32.add
                                      i64.load16_u align=1
                                      i64.const 32
                                      i64.shl
                                      i64.or
                                      i64.or
                                      local.set 14
                                      local.get 0
                                      i64.load offset=210 align=1
                                      local.set 16
                                      local.get 0
                                      i32.load8_u offset=209
                                      local.set 2
                                    end
                                    local.get 0
                                    i32.const 56
                                    i32.add
                                    local.get 0
                                    i32.const 400
                                    i32.add
                                    local.tee 6
                                    i32.load8_u
                                    i32.store8
                                    local.get 0
                                    i32.const 65
                                    i32.add
                                    local.get 0
                                    i32.const 96
                                    i32.add
                                    i64.load
                                    i64.store align=1
                                    local.get 0
                                    i32.const 73
                                    i32.add
                                    local.get 0
                                    i32.const 104
                                    i32.add
                                    local.tee 5
                                    i64.load
                                    i64.store align=1
                                    local.get 0
                                    i32.const 80
                                    i32.add
                                    local.get 0
                                    i32.const 111
                                    i32.add
                                    i64.load align=1
                                    i64.store align=1
                                    local.get 0
                                    local.get 0
                                    i32.load offset=376
                                    i32.store offset=27 align=1
                                    local.get 0
                                    local.get 0
                                    i64.load offset=392
                                    i64.store offset=48
                                    local.get 0
                                    local.get 0
                                    i64.load offset=88
                                    i64.store offset=57 align=1
                                    local.get 0
                                    local.get 0
                                    i32.const 380
                                    i32.add
                                    i32.load8_u
                                    i32.store8 offset=31
                                    local.get 0
                                    local.get 14
                                    i64.const 8
                                    i64.shl
                                    local.get 16
                                    i64.const 56
                                    i64.shr_u
                                    i64.or
                                    local.tee 13
                                    i64.store offset=40
                                    local.get 0
                                    local.get 2
                                    i64.extend_i32_u
                                    i64.const 255
                                    i64.and
                                    local.get 16
                                    i64.const 8
                                    i64.shl
                                    i64.or
                                    local.tee 14
                                    i64.store offset=32
                                    local.get 0
                                    local.get 4
                                    i32.store8 offset=26
                                    local.get 0
                                    local.get 1
                                    i32.store8 offset=25
                                    local.get 0
                                    local.get 3
                                    i32.store8 offset=24
                                    local.get 0
                                    i64.const 16384
                                    i64.store offset=212 align=4
                                    local.get 0
                                    i32.const 66280
                                    i32.store offset=208
                                    i32.const 0
                                    local.get 0
                                    i32.const 208
                                    i32.add
                                    local.tee 4
                                    call 37
                                    local.get 0
                                    i32.load offset=212
                                    local.tee 7
                                    local.get 0
                                    i32.load offset=216
                                    local.tee 1
                                    i32.lt_u
                                    br_if 0 (;@16;)
                                    local.get 0
                                    i32.load offset=208
                                    local.set 2
                                    local.get 0
                                    local.get 7
                                    local.get 1
                                    i32.sub
                                    local.tee 7
                                    i32.store offset=208
                                    local.get 2
                                    local.get 1
                                    local.get 1
                                    local.get 2
                                    i32.add
                                    local.tee 2
                                    local.get 4
                                    call 0
                                    local.set 1
                                    local.get 7
                                    local.get 0
                                    i32.load offset=208
                                    local.tee 8
                                    i32.lt_u
                                    local.get 1
                                    i32.const 15
                                    i32.ge_u
                                    i32.or
                                    br_if 0 (;@16;)
                                    local.get 1
                                    i32.const 65906
                                    i32.add
                                    i32.load8_u
                                    local.tee 1
                                    i32.const 3
                                    i32.eq
                                    local.get 1
                                    i32.const 16
                                    i32.ne
                                    i32.or
                                    br_if 0 (;@16;)
                                    local.get 0
                                    local.get 8
                                    i32.store offset=520
                                    local.get 0
                                    local.get 2
                                    i32.store offset=516
                                    local.get 0
                                    i32.const 88
                                    i32.add
                                    local.tee 2
                                    local.get 0
                                    i32.const 516
                                    i32.add
                                    local.tee 1
                                    call 22
                                    local.get 0
                                    i32.load offset=88
                                    br_if 0 (;@16;)
                                    local.get 5
                                    i64.load
                                    local.set 15
                                    local.get 0
                                    i64.load offset=96
                                    local.set 18
                                    local.get 2
                                    local.get 1
                                    call 22
                                    local.get 0
                                    i32.load offset=88
                                    br_if 0 (;@16;)
                                    local.get 5
                                    i64.load
                                    local.set 16
                                    local.get 0
                                    i64.load offset=96
                                    local.set 17
                                    local.get 2
                                    local.get 1
                                    call 22
                                    local.get 0
                                    i32.load offset=88
                                    br_if 0 (;@16;)
                                    local.get 5
                                    i64.load
                                    local.set 19
                                    local.get 0
                                    i64.load offset=96
                                    local.set 20
                                    local.get 0
                                    i32.const 8
                                    i32.add
                                    local.get 1
                                    call 19
                                    local.get 0
                                    i32.load offset=8
                                    br_if 0 (;@16;)
                                    local.get 0
                                    i32.load offset=12
                                    local.set 7
                                    local.get 2
                                    local.get 1
                                    call 35
                                    local.get 0
                                    i32.load8_u offset=88
                                    br_if 0 (;@16;)
                                    local.get 0
                                    i32.const 480
                                    i32.add
                                    local.tee 5
                                    local.get 0
                                    i32.const 113
                                    i32.add
                                    local.tee 8
                                    i64.load align=1
                                    i64.store
                                    local.get 0
                                    i32.const 472
                                    i32.add
                                    local.tee 9
                                    local.get 0
                                    i32.const 105
                                    i32.add
                                    local.tee 10
                                    i64.load align=1
                                    i64.store
                                    local.get 0
                                    i32.const 464
                                    i32.add
                                    local.tee 11
                                    local.get 0
                                    i32.const 97
                                    i32.add
                                    local.tee 12
                                    i64.load align=1
                                    i64.store
                                    local.get 0
                                    local.get 0
                                    i64.load offset=89 align=1
                                    i64.store offset=456
                                    local.get 2
                                    local.get 1
                                    call 56
                                    local.get 0
                                    i32.load8_u offset=88
                                    local.tee 1
                                    i32.const 2
                                    i32.eq
                                    br_if 0 (;@16;)
                                    local.get 0
                                    i32.const 232
                                    i32.add
                                    local.get 8
                                    i64.load align=1
                                    i64.store
                                    local.get 0
                                    i32.const 224
                                    i32.add
                                    local.get 10
                                    i64.load align=1
                                    i64.store
                                    local.get 0
                                    i32.const 216
                                    i32.add
                                    local.get 12
                                    i64.load align=1
                                    i64.store
                                    local.get 6
                                    local.get 11
                                    i64.load
                                    i64.store
                                    local.get 0
                                    i32.const 408
                                    i32.add
                                    local.tee 8
                                    local.get 9
                                    i64.load
                                    i64.store
                                    local.get 0
                                    i32.const 416
                                    i32.add
                                    local.tee 9
                                    local.get 5
                                    i64.load
                                    i64.store
                                    local.get 0
                                    local.get 0
                                    i64.load offset=89 align=1
                                    i64.store offset=208
                                    local.get 0
                                    local.get 0
                                    i64.load offset=456
                                    i64.store offset=392
                                    local.get 0
                                    i32.load offset=520
                                    br_if 0 (;@16;)
                                    local.get 0
                                    i32.const 32
                                    i32.add
                                    local.set 2
                                    local.get 0
                                    i32.const 24
                                    i32.add
                                    i32.const 1
                                    i32.or
                                    local.set 5
                                    local.get 0
                                    i32.const 160
                                    i32.add
                                    local.get 9
                                    i64.load
                                    i64.store
                                    local.get 0
                                    i32.const 152
                                    i32.add
                                    local.get 8
                                    i64.load
                                    i64.store
                                    local.get 0
                                    i32.const 144
                                    i32.add
                                    local.get 6
                                    i64.load
                                    i64.store
                                    local.get 0
                                    local.get 0
                                    i64.load offset=392
                                    i64.store offset=136
                                    local.get 0
                                    i32.const 173
                                    i32.add
                                    local.get 4
                                    i32.const 35
                                    call 9
                                    drop
                                    local.get 0
                                    local.get 19
                                    i64.store offset=128
                                    local.get 0
                                    local.get 20
                                    i64.store offset=120
                                    local.get 0
                                    local.get 16
                                    i64.store offset=112
                                    local.get 0
                                    local.get 17
                                    i64.store offset=104
                                    local.get 0
                                    local.get 15
                                    i64.store offset=96
                                    local.get 0
                                    local.get 18
                                    i64.store offset=88
                                    local.get 0
                                    local.get 1
                                    i32.store8 offset=172
                                    local.get 0
                                    local.get 7
                                    i32.store offset=168
                                    local.get 0
                                    i32.const 172
                                    i32.add
                                    local.set 4
                                    local.get 0
                                    i32.const 136
                                    i32.add
                                    local.set 1
                                    block  ;; label = @17
                                      block  ;; label = @18
                                        block  ;; label = @19
                                          block  ;; label = @20
                                            block (result i32)  ;; label = @21
                                              block  ;; label = @22
                                                block (result i32)  ;; label = @23
                                                  block  ;; label = @24
                                                    block (result i32)  ;; label = @25
                                                      block  ;; label = @26
                                                        block  ;; label = @27
                                                          block  ;; label = @28
                                                            block  ;; label = @29
                                                              block  ;; label = @30
                                                                block  ;; label = @31
                                                                  block  ;; label = @32
                                                                    block  ;; label = @33
                                                                      block  ;; label = @34
                                                                        block  ;; label = @35
                                                                          block  ;; label = @36
                                                                            block  ;; label = @37
                                                                              block  ;; label = @38
                                                                                block  ;; label = @39
                                                                                  block  ;; label = @40
                                                                                    block  ;; label = @41
                                                                                      block  ;; label = @42
                                                                                        block  ;; label = @43
                                                                                          block  ;; label = @44
                                                                                            block  ;; label = @45
                                                                                              block  ;; label = @46
                                                                                                block  ;; label = @47
                                                                                                  block  ;; label = @48
                                                                                                    block  ;; label = @49
                                                                                                      block  ;; label = @50
                                                                                                        block  ;; label = @51
                                                                                                          block  ;; label = @52
                                                                                                            block  ;; label = @53
                                                                                                              block  ;; label = @54
                                                                                                                block  ;; label = @55
                                                                                                                  block  ;; label = @56
                                                                                                                    block  ;; label = @57
                                                                                                                      block  ;; label = @58
                                                                                                                        local.get 3
                                                                                                                        i32.const 1
                                                                                                                        i32.sub
                                                                                                                        br_table 1 (;@57;) 38 (;@20;) 38 (;@20;) 2 (;@56;) 52 (;@6;) 52 (;@6;) 3 (;@55;) 4 (;@54;) 5 (;@53;) 6 (;@52;) 7 (;@51;) 8 (;@50;) 9 (;@49;) 10 (;@48;) 11 (;@47;) 12 (;@46;) 13 (;@45;) 14 (;@44;) 15 (;@43;) 16 (;@42;) 17 (;@41;) 31 (;@27;) 18 (;@40;) 19 (;@39;) 20 (;@38;) 21 (;@37;) 30 (;@28;) 29 (;@29;) 28 (;@30;) 22 (;@36;) 23 (;@35;) 24 (;@34;) 25 (;@33;) 39 (;@19;) 27 (;@31;) 0 (;@58;)
                                                                                                                      end
                                                                                                                      local.get 18
                                                                                                                      local.get 15
                                                                                                                      call 50
                                                                                                                      unreachable
                                                                                                                    end
                                                                                                                    local.get 17
                                                                                                                    local.get 16
                                                                                                                    call 50
                                                                                                                    unreachable
                                                                                                                  end
                                                                                                                  global.get 0
                                                                                                                  i32.const 48
                                                                                                                  i32.sub
                                                                                                                  local.tee 1
                                                                                                                  global.set 0
                                                                                                                  local.get 1
                                                                                                                  i32.const 24
                                                                                                                  i32.add
                                                                                                                  local.get 5
                                                                                                                  i32.const 8
                                                                                                                  i32.add
                                                                                                                  i64.load align=1
                                                                                                                  i64.store align=4
                                                                                                                  local.get 1
                                                                                                                  i32.const 32
                                                                                                                  i32.add
                                                                                                                  local.get 5
                                                                                                                  i32.const 16
                                                                                                                  i32.add
                                                                                                                  i64.load align=1
                                                                                                                  i64.store align=4
                                                                                                                  local.get 1
                                                                                                                  i32.const 40
                                                                                                                  i32.add
                                                                                                                  local.get 5
                                                                                                                  i32.const 24
                                                                                                                  i32.add
                                                                                                                  i64.load align=1
                                                                                                                  i64.store align=4
                                                                                                                  local.get 1
                                                                                                                  local.get 0
                                                                                                                  i32.const 88
                                                                                                                  i32.add
                                                                                                                  i32.store offset=12
                                                                                                                  local.get 1
                                                                                                                  local.get 5
                                                                                                                  i64.load align=1
                                                                                                                  i64.store offset=16 align=4
                                                                                                                  local.get 0
                                                                                                                  i32.const 216
                                                                                                                  i32.add
                                                                                                                  local.get 1
                                                                                                                  i32.const 16
                                                                                                                  i32.add
                                                                                                                  call 46
                                                                                                                  local.get 1
                                                                                                                  i32.const 48
                                                                                                                  i32.add
                                                                                                                  global.set 0
                                                                                                                  local.get 0
                                                                                                                  i32.const 0
                                                                                                                  i32.store offset=208
                                                                                                                  global.get 0
                                                                                                                  i32.const 16
                                                                                                                  i32.sub
                                                                                                                  local.tee 1
                                                                                                                  global.set 0
                                                                                                                  local.get 1
                                                                                                                  i32.const 16384
                                                                                                                  i32.store offset=8
                                                                                                                  local.get 1
                                                                                                                  i32.const 66280
                                                                                                                  i32.store offset=4
                                                                                                                  block  ;; label = @56
                                                                                                                    local.get 0
                                                                                                                    i32.const 208
                                                                                                                    i32.add
                                                                                                                    local.tee 2
                                                                                                                    i32.load
                                                                                                                    i32.const 1
                                                                                                                    i32.eq
                                                                                                                    if  ;; label = @57
                                                                                                                      i32.const 66280
                                                                                                                      i32.const 257
                                                                                                                      i32.store16 align=1
                                                                                                                      i32.const 2
                                                                                                                      local.set 1
                                                                                                                      br 1 (;@56;)
                                                                                                                    end
                                                                                                                    local.get 1
                                                                                                                    i32.const 1
                                                                                                                    i32.store offset=12
                                                                                                                    i32.const 66280
                                                                                                                    i32.const 0
                                                                                                                    i32.store8
                                                                                                                    local.get 2
                                                                                                                    i32.const 8
                                                                                                                    i32.add
                                                                                                                    local.get 1
                                                                                                                    i32.const 4
                                                                                                                    i32.add
                                                                                                                    call 29
                                                                                                                    local.get 1
                                                                                                                    i32.load offset=12
                                                                                                                    local.tee 1
                                                                                                                    i32.const 16385
                                                                                                                    i32.lt_u
                                                                                                                    br_if 0 (;@56;)
                                                                                                                    unreachable
                                                                                                                  end
                                                                                                                  br 54 (;@1;)
                                                                                                                end
                                                                                                                global.get 0
                                                                                                                i32.const 96
                                                                                                                i32.sub
                                                                                                                local.tee 1
                                                                                                                global.set 0
                                                                                                                local.get 1
                                                                                                                i32.const 24
                                                                                                                i32.add
                                                                                                                local.get 5
                                                                                                                i32.const 8
                                                                                                                i32.add
                                                                                                                i64.load align=1
                                                                                                                i64.store align=4
                                                                                                                local.get 1
                                                                                                                i32.const 32
                                                                                                                i32.add
                                                                                                                local.get 5
                                                                                                                i32.const 16
                                                                                                                i32.add
                                                                                                                i64.load align=1
                                                                                                                i64.store align=4
                                                                                                                local.get 1
                                                                                                                i32.const 40
                                                                                                                i32.add
                                                                                                                local.get 5
                                                                                                                i32.const 24
                                                                                                                i32.add
                                                                                                                i64.load align=1
                                                                                                                i64.store align=4
                                                                                                                local.get 1
                                                                                                                local.get 0
                                                                                                                i32.const 88
                                                                                                                i32.add
                                                                                                                i32.store offset=12
                                                                                                                local.get 1
                                                                                                                local.get 5
                                                                                                                i64.load align=1
                                                                                                                i64.store offset=16 align=4
                                                                                                                local.get 1
                                                                                                                i32.const 48
                                                                                                                i32.add
                                                                                                                local.get 1
                                                                                                                i32.const 16
                                                                                                                i32.add
                                                                                                                call 46
                                                                                                                local.get 0
                                                                                                                i32.const 216
                                                                                                                i32.add
                                                                                                                local.tee 2
                                                                                                                local.get 1
                                                                                                                i32.const 72
                                                                                                                i32.add
                                                                                                                i64.load
                                                                                                                i64.store offset=8
                                                                                                                local.get 2
                                                                                                                local.get 1
                                                                                                                i64.load offset=64
                                                                                                                i64.store
                                                                                                                local.get 1
                                                                                                                i32.const 96
                                                                                                                i32.add
                                                                                                                global.set 0
                                                                                                                br 49 (;@5;)
                                                                                                              end
                                                                                                              global.get 0
                                                                                                              i32.const 96
                                                                                                              i32.sub
                                                                                                              local.tee 1
                                                                                                              global.set 0
                                                                                                              local.get 1
                                                                                                              i32.const 24
                                                                                                              i32.add
                                                                                                              local.get 5
                                                                                                              i32.const 8
                                                                                                              i32.add
                                                                                                              i64.load align=1
                                                                                                              i64.store align=4
                                                                                                              local.get 1
                                                                                                              i32.const 32
                                                                                                              i32.add
                                                                                                              local.get 5
                                                                                                              i32.const 16
                                                                                                              i32.add
                                                                                                              i64.load align=1
                                                                                                              i64.store align=4
                                                                                                              local.get 1
                                                                                                              i32.const 40
                                                                                                              i32.add
                                                                                                              local.get 5
                                                                                                              i32.const 24
                                                                                                              i32.add
                                                                                                              i64.load align=1
                                                                                                              i64.store align=4
                                                                                                              local.get 1
                                                                                                              local.get 0
                                                                                                              i32.const 88
                                                                                                              i32.add
                                                                                                              i32.store offset=12
                                                                                                              local.get 1
                                                                                                              local.get 5
                                                                                                              i64.load align=1
                                                                                                              i64.store offset=16 align=4
                                                                                                              local.get 1
                                                                                                              i32.const 48
                                                                                                              i32.add
                                                                                                              local.get 1
                                                                                                              i32.const 16
                                                                                                              i32.add
                                                                                                              call 46
                                                                                                              local.get 0
                                                                                                              i32.const 216
                                                                                                              i32.add
                                                                                                              local.tee 2
                                                                                                              i64.const -1
                                                                                                              local.get 1
                                                                                                              i64.load offset=48
                                                                                                              local.tee 13
                                                                                                              local.get 1
                                                                                                              i64.load offset=64
                                                                                                              i64.add
                                                                                                              local.tee 16
                                                                                                              local.get 13
                                                                                                              i64.lt_u
                                                                                                              local.tee 3
                                                                                                              i64.extend_i32_u
                                                                                                              local.get 1
                                                                                                              i32.const 56
                                                                                                              i32.add
                                                                                                              i64.load
                                                                                                              local.tee 13
                                                                                                              local.get 1
                                                                                                              i32.const 72
                                                                                                              i32.add
                                                                                                              i64.load
                                                                                                              i64.add
                                                                                                              i64.add
                                                                                                              local.tee 14
                                                                                                              local.get 3
                                                                                                              local.get 13
                                                                                                              local.get 14
                                                                                                              i64.gt_u
                                                                                                              local.get 13
                                                                                                              local.get 14
                                                                                                              i64.eq
                                                                                                              select
                                                                                                              local.tee 3
                                                                                                              select
                                                                                                              i64.store offset=8
                                                                                                              local.get 2
                                                                                                              i64.const -1
                                                                                                              local.get 16
                                                                                                              local.get 3
                                                                                                              select
                                                                                                              i64.store
                                                                                                              local.get 1
                                                                                                              i32.const 96
                                                                                                              i32.add
                                                                                                              global.set 0
                                                                                                              br 48 (;@5;)
                                                                                                            end
                                                                                                            global.get 0
                                                                                                            i32.const 96
                                                                                                            i32.sub
                                                                                                            local.tee 1
                                                                                                            global.set 0
                                                                                                            local.get 1
                                                                                                            i32.const 24
                                                                                                            i32.add
                                                                                                            local.get 5
                                                                                                            i32.const 8
                                                                                                            i32.add
                                                                                                            i64.load align=1
                                                                                                            i64.store align=4
                                                                                                            local.get 1
                                                                                                            i32.const 32
                                                                                                            i32.add
                                                                                                            local.get 5
                                                                                                            i32.const 16
                                                                                                            i32.add
                                                                                                            i64.load align=1
                                                                                                            i64.store align=4
                                                                                                            local.get 1
                                                                                                            i32.const 40
                                                                                                            i32.add
                                                                                                            local.get 5
                                                                                                            i32.const 24
                                                                                                            i32.add
                                                                                                            i64.load align=1
                                                                                                            i64.store align=4
                                                                                                            local.get 1
                                                                                                            local.get 0
                                                                                                            i32.const 88
                                                                                                            i32.add
                                                                                                            i32.store offset=12
                                                                                                            local.get 1
                                                                                                            local.get 5
                                                                                                            i64.load align=1
                                                                                                            i64.store offset=16 align=4
                                                                                                            local.get 1
                                                                                                            i32.const 48
                                                                                                            i32.add
                                                                                                            local.get 1
                                                                                                            i32.const 16
                                                                                                            i32.add
                                                                                                            call 46
                                                                                                            local.get 0
                                                                                                            i32.const 216
                                                                                                            i32.add
                                                                                                            local.tee 2
                                                                                                            i64.const 0
                                                                                                            local.get 1
                                                                                                            i32.const 56
                                                                                                            i32.add
                                                                                                            i64.load
                                                                                                            local.tee 13
                                                                                                            local.get 1
                                                                                                            i32.const 88
                                                                                                            i32.add
                                                                                                            i64.load
                                                                                                            i64.sub
                                                                                                            local.get 1
                                                                                                            i64.load offset=48
                                                                                                            local.tee 14
                                                                                                            local.get 1
                                                                                                            i64.load offset=80
                                                                                                            local.tee 15
                                                                                                            i64.lt_u
                                                                                                            i64.extend_i32_u
                                                                                                            i64.sub
                                                                                                            local.tee 16
                                                                                                            local.get 14
                                                                                                            local.get 14
                                                                                                            local.get 15
                                                                                                            i64.sub
                                                                                                            local.tee 15
                                                                                                            i64.lt_u
                                                                                                            local.get 13
                                                                                                            local.get 16
                                                                                                            i64.lt_u
                                                                                                            local.get 13
                                                                                                            local.get 16
                                                                                                            i64.eq
                                                                                                            select
                                                                                                            local.tee 3
                                                                                                            select
                                                                                                            i64.store offset=8
                                                                                                            local.get 2
                                                                                                            i64.const 0
                                                                                                            local.get 15
                                                                                                            local.get 3
                                                                                                            select
                                                                                                            i64.store
                                                                                                            local.get 1
                                                                                                            i32.const 96
                                                                                                            i32.add
                                                                                                            global.set 0
                                                                                                            br 47 (;@5;)
                                                                                                          end
                                                                                                          local.get 0
                                                                                                          local.get 14
                                                                                                          i64.store offset=232
                                                                                                          local.get 0
                                                                                                          local.get 14
                                                                                                          i64.store offset=216
                                                                                                          local.get 0
                                                                                                          i32.const 4
                                                                                                          i32.store8 offset=209
                                                                                                          local.get 0
                                                                                                          block (result i32)  ;; label = @52
                                                                                                            local.get 13
                                                                                                            local.get 14
                                                                                                            i64.or
                                                                                                            i64.eqz
                                                                                                            i32.eqz
                                                                                                            if  ;; label = @53
                                                                                                              i32.const 1
                                                                                                              local.get 14
                                                                                                              local.get 18
                                                                                                              i64.add
                                                                                                              local.get 18
                                                                                                              i64.lt_u
                                                                                                              local.tee 1
                                                                                                              local.get 1
                                                                                                              i64.extend_i32_u
                                                                                                              local.get 13
                                                                                                              local.get 15
                                                                                                              i64.add
                                                                                                              i64.add
                                                                                                              local.tee 14
                                                                                                              local.get 15
                                                                                                              i64.lt_u
                                                                                                              local.get 14
                                                                                                              local.get 15
                                                                                                              i64.eq
                                                                                                              select
                                                                                                              br_if 1 (;@52;)
                                                                                                              drop
                                                                                                            end
                                                                                                            i32.const 0
                                                                                                          end
                                                                                                          local.tee 1
                                                                                                          i32.store8 offset=208
                                                                                                          local.get 0
                                                                                                          local.get 13
                                                                                                          i64.store offset=240
                                                                                                          local.get 0
                                                                                                          local.get 13
                                                                                                          i64.store offset=224
                                                                                                          global.get 0
                                                                                                          i32.const 16
                                                                                                          i32.sub
                                                                                                          local.tee 2
                                                                                                          global.set 0
                                                                                                          local.get 2
                                                                                                          i32.const 16384
                                                                                                          i32.store offset=8
                                                                                                          local.get 2
                                                                                                          i32.const 66280
                                                                                                          i32.store offset=4
                                                                                                          i32.const 2
                                                                                                          local.set 3
                                                                                                          block  ;; label = @52
                                                                                                            block (result i32)  ;; label = @53
                                                                                                              local.get 0
                                                                                                              i32.const 208
                                                                                                              i32.add
                                                                                                              local.tee 0
                                                                                                              i32.load8_u
                                                                                                              local.tee 4
                                                                                                              i32.const 2
                                                                                                              i32.ne
                                                                                                              if  ;; label = @54
                                                                                                                i32.const 66280
                                                                                                                i32.const 0
                                                                                                                i32.store8
                                                                                                                local.get 4
                                                                                                                i32.const 1
                                                                                                                i32.and
                                                                                                                if  ;; label = @55
                                                                                                                  i32.const 66281
                                                                                                                  i32.const 1
                                                                                                                  i32.store8
                                                                                                                  local.get 0
                                                                                                                  i32.load8_u offset=1
                                                                                                                  local.set 2
                                                                                                                  i32.const 3
                                                                                                                  local.set 3
                                                                                                                  i32.const 66282
                                                                                                                  br 2 (;@53;)
                                                                                                                end
                                                                                                                local.get 2
                                                                                                                i32.const 2
                                                                                                                i32.store offset=12
                                                                                                                i32.const 66281
                                                                                                                i32.const 0
                                                                                                                i32.store8
                                                                                                                local.get 0
                                                                                                                i64.load offset=8
                                                                                                                local.get 0
                                                                                                                i32.const 16
                                                                                                                i32.add
                                                                                                                i64.load
                                                                                                                local.get 2
                                                                                                                i32.const 4
                                                                                                                i32.add
                                                                                                                local.tee 3
                                                                                                                call 27
                                                                                                                local.get 0
                                                                                                                i64.load offset=24
                                                                                                                local.get 0
                                                                                                                i32.const 32
                                                                                                                i32.add
                                                                                                                i64.load
                                                                                                                local.get 3
                                                                                                                call 27
                                                                                                                local.get 2
                                                                                                                i32.load offset=12
                                                                                                                local.tee 3
                                                                                                                i32.const 16385
                                                                                                                i32.lt_u
                                                                                                                br_if 2 (;@52;)
                                                                                                                unreachable
                                                                                                              end
                                                                                                              i32.const 1
                                                                                                              local.set 2
                                                                                                              i32.const 66280
                                                                                                              i32.const 1
                                                                                                              i32.store8
                                                                                                              i32.const 66281
                                                                                                            end
                                                                                                            local.get 2
                                                                                                            i32.store8
                                                                                                          end
                                                                                                          local.get 1
                                                                                                          local.get 3
                                                                                                          call 55
                                                                                                          unreachable
                                                                                                        end
                                                                                                        local.get 0
                                                                                                        i32.const 216
                                                                                                        i32.add
                                                                                                        local.get 2
                                                                                                        i32.const 48
                                                                                                        call 9
                                                                                                        local.set 1
                                                                                                        local.get 0
                                                                                                        i32.const 256
                                                                                                        i32.add
                                                                                                        i64.load
                                                                                                        local.set 13
                                                                                                        local.get 0
                                                                                                        i64.load offset=248
                                                                                                        local.set 14
                                                                                                        local.get 0
                                                                                                        local.get 0
                                                                                                        i32.const 88
                                                                                                        i32.add
                                                                                                        local.tee 2
                                                                                                        i32.store offset=208
                                                                                                        block (result i32)  ;; label = @51
                                                                                                          local.get 13
                                                                                                          local.get 14
                                                                                                          i64.or
                                                                                                          i64.eqz
                                                                                                          i32.eqz
                                                                                                          if  ;; label = @52
                                                                                                            i32.const 1
                                                                                                            local.get 2
                                                                                                            local.get 1
                                                                                                            local.get 14
                                                                                                            local.get 13
                                                                                                            call 60
                                                                                                            i32.const 255
                                                                                                            i32.and
                                                                                                            local.tee 3
                                                                                                            i32.const 7
                                                                                                            i32.ne
                                                                                                            br_if 1 (;@51;)
                                                                                                            drop
                                                                                                          end
                                                                                                          local.get 0
                                                                                                          i32.const 208
                                                                                                          i32.add
                                                                                                          local.tee 1
                                                                                                          local.get 0
                                                                                                          i32.const 88
                                                                                                          i32.add
                                                                                                          i32.const 120
                                                                                                          call 9
                                                                                                          drop
                                                                                                          local.get 1
                                                                                                          call 54
                                                                                                          i32.const 7
                                                                                                          local.set 3
                                                                                                          i32.const 0
                                                                                                        end
                                                                                                        local.get 3
                                                                                                        call 49
                                                                                                        unreachable
                                                                                                      end
                                                                                                      local.get 0
                                                                                                      i32.const 216
                                                                                                      i32.add
                                                                                                      local.get 2
                                                                                                      i32.const 56
                                                                                                      call 9
                                                                                                      local.set 3
                                                                                                      local.get 0
                                                                                                      i32.const 256
                                                                                                      i32.add
                                                                                                      i64.load
                                                                                                      local.set 13
                                                                                                      local.get 0
                                                                                                      i64.load offset=248
                                                                                                      local.set 14
                                                                                                      local.get 0
                                                                                                      local.get 0
                                                                                                      i32.const 88
                                                                                                      i32.add
                                                                                                      local.tee 2
                                                                                                      i32.store offset=208
                                                                                                      i64.const 0
                                                                                                      local.set 15
                                                                                                      i64.const 0
                                                                                                      local.set 17
                                                                                                      block  ;; label = @50
                                                                                                        block  ;; label = @51
                                                                                                          local.get 13
                                                                                                          local.get 14
                                                                                                          i64.or
                                                                                                          i64.eqz
                                                                                                          i32.eqz
                                                                                                          if  ;; label = @52
                                                                                                            i32.const 1
                                                                                                            local.set 1
                                                                                                            local.get 0
                                                                                                            i32.const 456
                                                                                                            i32.add
                                                                                                            local.get 2
                                                                                                            local.get 3
                                                                                                            local.get 14
                                                                                                            local.get 13
                                                                                                            local.get 0
                                                                                                            i32.load8_u offset=264
                                                                                                            i32.const 1
                                                                                                            call 61
                                                                                                            local.get 0
                                                                                                            i32.load8_u offset=456
                                                                                                            br_if 1 (;@51;)
                                                                                                            i64.const 0
                                                                                                            local.get 13
                                                                                                            local.get 0
                                                                                                            i32.const 472
                                                                                                            i32.add
                                                                                                            i64.load
                                                                                                            i64.sub
                                                                                                            local.get 14
                                                                                                            local.get 0
                                                                                                            i64.load offset=464
                                                                                                            local.tee 15
                                                                                                            i64.lt_u
                                                                                                            i64.extend_i32_u
                                                                                                            i64.sub
                                                                                                            local.tee 16
                                                                                                            local.get 14
                                                                                                            local.get 14
                                                                                                            local.get 15
                                                                                                            i64.sub
                                                                                                            local.tee 15
                                                                                                            i64.lt_u
                                                                                                            local.get 13
                                                                                                            local.get 16
                                                                                                            i64.lt_u
                                                                                                            local.get 13
                                                                                                            local.get 16
                                                                                                            i64.eq
                                                                                                            select
                                                                                                            local.tee 1
                                                                                                            select
                                                                                                            local.set 17
                                                                                                            i64.const 0
                                                                                                            local.get 15
                                                                                                            local.get 1
                                                                                                            select
                                                                                                            local.set 15
                                                                                                          end
                                                                                                          local.get 0
                                                                                                          i32.const 208
                                                                                                          i32.add
                                                                                                          local.tee 1
                                                                                                          local.get 0
                                                                                                          i32.const 88
                                                                                                          i32.add
                                                                                                          i32.const 120
                                                                                                          call 9
                                                                                                          drop
                                                                                                          local.get 1
                                                                                                          call 54
                                                                                                          i32.const 0
                                                                                                          local.set 1
                                                                                                          br 1 (;@50;)
                                                                                                        end
                                                                                                        local.get 0
                                                                                                        i32.load8_u offset=457
                                                                                                        local.set 3
                                                                                                      end
                                                                                                      local.get 0
                                                                                                      local.get 15
                                                                                                      i64.store offset=216
                                                                                                      local.get 0
                                                                                                      local.get 3
                                                                                                      i32.store8 offset=209
                                                                                                      local.get 0
                                                                                                      local.get 1
                                                                                                      i32.store8 offset=208
                                                                                                      local.get 0
                                                                                                      local.get 17
                                                                                                      i64.store offset=224
                                                                                                      br 45 (;@4;)
                                                                                                    end
                                                                                                    global.get 0
                                                                                                    i32.const 48
                                                                                                    i32.sub
                                                                                                    local.tee 1
                                                                                                    global.set 0
                                                                                                    local.get 1
                                                                                                    local.get 0
                                                                                                    i32.const 88
                                                                                                    i32.add
                                                                                                    local.tee 2
                                                                                                    i32.store offset=8
                                                                                                    local.get 1
                                                                                                    i32.const 12
                                                                                                    i32.add
                                                                                                    local.get 5
                                                                                                    i32.const 34
                                                                                                    call 9
                                                                                                    drop
                                                                                                    local.get 0
                                                                                                    i32.const 216
                                                                                                    i32.add
                                                                                                    local.get 2
                                                                                                    i64.load offset=32
                                                                                                    local.get 2
                                                                                                    i32.const 40
                                                                                                    i32.add
                                                                                                    i64.load
                                                                                                    local.get 1
                                                                                                    i32.const 13
                                                                                                    i32.add
                                                                                                    local.get 1
                                                                                                    i32.load8_u offset=12
                                                                                                    call 47
                                                                                                    local.get 1
                                                                                                    i32.const 48
                                                                                                    i32.add
                                                                                                    global.set 0
                                                                                                    br 43 (;@5;)
                                                                                                  end
                                                                                                  global.get 0
                                                                                                  i32.const 112
                                                                                                  i32.sub
                                                                                                  local.tee 1
                                                                                                  global.set 0
                                                                                                  local.get 1
                                                                                                  local.get 0
                                                                                                  i32.const 88
                                                                                                  i32.add
                                                                                                  local.tee 0
                                                                                                  i32.store
                                                                                                  local.get 1
                                                                                                  i32.const 8
                                                                                                  i32.add
                                                                                                  local.get 2
                                                                                                  i32.const 56
                                                                                                  call 9
                                                                                                  local.set 2
                                                                                                  block  ;; label = @48
                                                                                                    local.get 1
                                                                                                    i64.load offset=40
                                                                                                    local.tee 14
                                                                                                    local.get 1
                                                                                                    i32.const 48
                                                                                                    i32.add
                                                                                                    i64.load
                                                                                                    local.tee 13
                                                                                                    i64.or
                                                                                                    i64.eqz
                                                                                                    if  ;; label = @49
                                                                                                      i32.const 0
                                                                                                      local.set 2
                                                                                                      br 1 (;@48;)
                                                                                                    end
                                                                                                    local.get 1
                                                                                                    i32.const -64
                                                                                                    i32.sub
                                                                                                    local.get 2
                                                                                                    call 46
                                                                                                    i32.const 1
                                                                                                    local.set 2
                                                                                                    local.get 1
                                                                                                    i64.load offset=64
                                                                                                    local.tee 15
                                                                                                    local.get 14
                                                                                                    i64.add
                                                                                                    local.get 15
                                                                                                    i64.lt_u
                                                                                                    local.tee 3
                                                                                                    local.get 3
                                                                                                    i64.extend_i32_u
                                                                                                    local.get 1
                                                                                                    i32.const 72
                                                                                                    i32.add
                                                                                                    i64.load
                                                                                                    local.tee 16
                                                                                                    local.get 13
                                                                                                    i64.add
                                                                                                    i64.add
                                                                                                    local.tee 17
                                                                                                    local.get 16
                                                                                                    i64.lt_u
                                                                                                    local.get 16
                                                                                                    local.get 17
                                                                                                    i64.eq
                                                                                                    select
                                                                                                    br_if 0 (;@48;)
                                                                                                    local.get 0
                                                                                                    i64.load
                                                                                                    local.tee 17
                                                                                                    local.get 14
                                                                                                    i64.add
                                                                                                    local.get 17
                                                                                                    i64.lt_u
                                                                                                    local.tee 3
                                                                                                    local.get 3
                                                                                                    i64.extend_i32_u
                                                                                                    local.get 0
                                                                                                    i32.const 8
                                                                                                    i32.add
                                                                                                    i64.load
                                                                                                    local.tee 17
                                                                                                    local.get 13
                                                                                                    i64.add
                                                                                                    i64.add
                                                                                                    local.tee 18
                                                                                                    local.get 17
                                                                                                    i64.lt_u
                                                                                                    local.get 17
                                                                                                    local.get 18
                                                                                                    i64.eq
                                                                                                    select
                                                                                                    br_if 0 (;@48;)
                                                                                                    i32.const 0
                                                                                                    local.set 2
                                                                                                    local.get 15
                                                                                                    local.get 16
                                                                                                    i64.or
                                                                                                    i64.const 0
                                                                                                    i64.ne
                                                                                                    br_if 0 (;@48;)
                                                                                                    local.get 0
                                                                                                    i64.load offset=32
                                                                                                    local.get 14
                                                                                                    i64.le_u
                                                                                                    local.get 0
                                                                                                    i32.const 40
                                                                                                    i32.add
                                                                                                    i64.load
                                                                                                    local.tee 14
                                                                                                    local.get 13
                                                                                                    i64.le_u
                                                                                                    local.get 13
                                                                                                    local.get 14
                                                                                                    i64.eq
                                                                                                    select
                                                                                                    br_if 0 (;@48;)
                                                                                                    i32.const 2
                                                                                                    local.set 2
                                                                                                  end
                                                                                                  local.get 1
                                                                                                  i32.const 112
                                                                                                  i32.add
                                                                                                  global.set 0
                                                                                                  i32.const 66281
                                                                                                  local.get 2
                                                                                                  i32.store8
                                                                                                  i32.const 66280
                                                                                                  i32.const 0
                                                                                                  i32.store8
                                                                                                  i32.const 0
                                                                                                  i32.const 2
                                                                                                  call 55
                                                                                                  unreachable
                                                                                                end
                                                                                                local.get 0
                                                                                                i32.const 208
                                                                                                i32.add
                                                                                                local.set 3
                                                                                                global.get 0
                                                                                                i32.const 112
                                                                                                i32.sub
                                                                                                local.tee 1
                                                                                                global.set 0
                                                                                                local.get 1
                                                                                                local.get 0
                                                                                                i32.const 88
                                                                                                i32.add
                                                                                                local.tee 4
                                                                                                i32.store offset=8
                                                                                                local.get 1
                                                                                                i32.const 16
                                                                                                i32.add
                                                                                                local.get 2
                                                                                                i32.const 48
                                                                                                call 9
                                                                                                local.set 2
                                                                                                block  ;; label = @47
                                                                                                  local.get 1
                                                                                                  i64.load offset=48
                                                                                                  local.tee 15
                                                                                                  local.get 1
                                                                                                  i32.const 56
                                                                                                  i32.add
                                                                                                  i64.load
                                                                                                  local.tee 16
                                                                                                  i64.or
                                                                                                  i64.eqz
                                                                                                  if  ;; label = @48
                                                                                                    local.get 3
                                                                                                    i64.const 0
                                                                                                    i64.store
                                                                                                    br 1 (;@47;)
                                                                                                  end
                                                                                                  local.get 1
                                                                                                  i32.const -64
                                                                                                  i32.sub
                                                                                                  local.get 2
                                                                                                  call 46
                                                                                                  local.get 3
                                                                                                  i64.const 0
                                                                                                  local.get 1
                                                                                                  i64.load offset=64
                                                                                                  local.tee 14
                                                                                                  local.get 1
                                                                                                  i64.load offset=96
                                                                                                  local.tee 17
                                                                                                  i64.sub
                                                                                                  local.tee 13
                                                                                                  local.get 13
                                                                                                  local.get 14
                                                                                                  i64.gt_u
                                                                                                  local.get 1
                                                                                                  i32.const 72
                                                                                                  i32.add
                                                                                                  i64.load
                                                                                                  local.tee 13
                                                                                                  local.get 1
                                                                                                  i32.const 104
                                                                                                  i32.add
                                                                                                  i64.load
                                                                                                  i64.sub
                                                                                                  local.get 14
                                                                                                  local.get 17
                                                                                                  i64.lt_u
                                                                                                  i64.extend_i32_u
                                                                                                  i64.sub
                                                                                                  local.tee 17
                                                                                                  local.get 13
                                                                                                  i64.gt_u
                                                                                                  local.get 13
                                                                                                  local.get 17
                                                                                                  i64.eq
                                                                                                  select
                                                                                                  local.tee 2
                                                                                                  select
                                                                                                  local.get 15
                                                                                                  i64.lt_u
                                                                                                  i64.const 0
                                                                                                  local.get 17
                                                                                                  local.get 2
                                                                                                  select
                                                                                                  local.tee 17
                                                                                                  local.get 16
                                                                                                  i64.lt_u
                                                                                                  local.get 16
                                                                                                  local.get 17
                                                                                                  i64.eq
                                                                                                  select
                                                                                                  if (result i64)  ;; label = @48
                                                                                                    i64.const 1
                                                                                                  else
                                                                                                    block  ;; label = @49
                                                                                                      local.get 14
                                                                                                      local.get 15
                                                                                                      i64.le_u
                                                                                                      local.get 13
                                                                                                      local.get 16
                                                                                                      i64.le_u
                                                                                                      local.get 13
                                                                                                      local.get 16
                                                                                                      i64.eq
                                                                                                      select
                                                                                                      i32.eqz
                                                                                                      if  ;; label = @50
                                                                                                        i64.const 0
                                                                                                        local.get 14
                                                                                                        local.get 15
                                                                                                        i64.sub
                                                                                                        local.tee 17
                                                                                                        local.get 14
                                                                                                        local.get 17
                                                                                                        i64.lt_u
                                                                                                        local.get 13
                                                                                                        local.get 16
                                                                                                        i64.sub
                                                                                                        local.get 14
                                                                                                        local.get 15
                                                                                                        i64.lt_u
                                                                                                        i64.extend_i32_u
                                                                                                        i64.sub
                                                                                                        local.tee 14
                                                                                                        local.get 13
                                                                                                        i64.gt_u
                                                                                                        local.get 13
                                                                                                        local.get 14
                                                                                                        i64.eq
                                                                                                        select
                                                                                                        local.tee 2
                                                                                                        select
                                                                                                        local.tee 16
                                                                                                        local.get 4
                                                                                                        i64.load offset=32
                                                                                                        i64.lt_u
                                                                                                        i64.const 0
                                                                                                        local.get 14
                                                                                                        local.get 2
                                                                                                        select
                                                                                                        local.tee 13
                                                                                                        local.get 4
                                                                                                        i32.const 40
                                                                                                        i32.add
                                                                                                        i64.load
                                                                                                        local.tee 14
                                                                                                        i64.lt_u
                                                                                                        local.get 13
                                                                                                        local.get 14
                                                                                                        i64.eq
                                                                                                        select
                                                                                                        br_if 1 (;@49;)
                                                                                                      end
                                                                                                      local.get 3
                                                                                                      i64.const 0
                                                                                                      i64.store
                                                                                                      br 2 (;@47;)
                                                                                                    end
                                                                                                    local.get 3
                                                                                                    local.get 16
                                                                                                    i64.store offset=8
                                                                                                    local.get 3
                                                                                                    local.get 13
                                                                                                    i64.store offset=16
                                                                                                    i64.const 2
                                                                                                  end
                                                                                                  i64.store
                                                                                                end
                                                                                                local.get 1
                                                                                                i32.const 112
                                                                                                i32.add
                                                                                                global.set 0
                                                                                                local.get 0
                                                                                                i64.load offset=208
                                                                                                local.set 13
                                                                                                local.get 0
                                                                                                i64.load offset=216
                                                                                                local.set 14
                                                                                                local.get 0
                                                                                                i32.const 224
                                                                                                i32.add
                                                                                                i64.load
                                                                                                local.set 16
                                                                                                i32.const 0
                                                                                                local.set 1
                                                                                                global.get 0
                                                                                                i32.const 16
                                                                                                i32.sub
                                                                                                local.tee 2
                                                                                                global.set 0
                                                                                                local.get 2
                                                                                                i32.const 16384
                                                                                                i32.store offset=8
                                                                                                local.get 2
                                                                                                i32.const 66280
                                                                                                i32.store offset=4
                                                                                                i32.const 66280
                                                                                                i32.const 0
                                                                                                i32.store8
                                                                                                block  ;; label = @47
                                                                                                  block  ;; label = @48
                                                                                                    block  ;; label = @49
                                                                                                      block  ;; label = @50
                                                                                                        block  ;; label = @51
                                                                                                          block  ;; label = @52
                                                                                                            block  ;; label = @53
                                                                                                              local.get 13
                                                                                                              i32.wrap_i64
                                                                                                              i32.const 1
                                                                                                              i32.sub
                                                                                                              br_table 4 (;@49;) 3 (;@50;) 0 (;@53;) 1 (;@52;) 2 (;@51;) 5 (;@48;)
                                                                                                            end
                                                                                                            i32.const 3
                                                                                                            local.set 1
                                                                                                            br 4 (;@48;)
                                                                                                          end
                                                                                                          i32.const 4
                                                                                                          local.set 1
                                                                                                          br 3 (;@48;)
                                                                                                        end
                                                                                                        i32.const 5
                                                                                                        local.set 1
                                                                                                        br 2 (;@48;)
                                                                                                      end
                                                                                                      i32.const 66281
                                                                                                      i32.const 2
                                                                                                      i32.store8
                                                                                                      local.get 2
                                                                                                      i32.const 2
                                                                                                      i32.store offset=12
                                                                                                      local.get 14
                                                                                                      local.get 16
                                                                                                      local.get 2
                                                                                                      i32.const 4
                                                                                                      i32.add
                                                                                                      call 27
                                                                                                      local.get 2
                                                                                                      i32.load offset=12
                                                                                                      local.tee 1
                                                                                                      i32.const 16385
                                                                                                      i32.lt_u
                                                                                                      br_if 2 (;@47;)
                                                                                                      unreachable
                                                                                                    end
                                                                                                    i32.const 1
                                                                                                    local.set 1
                                                                                                  end
                                                                                                  i32.const 66281
                                                                                                  local.get 1
                                                                                                  i32.store8
                                                                                                  i32.const 2
                                                                                                  local.set 1
                                                                                                end
                                                                                                br 45 (;@1;)
                                                                                              end
                                                                                              local.get 0
                                                                                              i32.const 216
                                                                                              i32.add
                                                                                              local.get 2
                                                                                              i32.const 48
                                                                                              call 9
                                                                                              local.set 2
                                                                                              local.get 0
                                                                                              local.get 0
                                                                                              i32.const 88
                                                                                              i32.add
                                                                                              i32.store offset=208
                                                                                              local.get 0
                                                                                              i32.const 256
                                                                                              i32.add
                                                                                              i64.load
                                                                                              local.set 14
                                                                                              local.get 0
                                                                                              i64.load offset=248
                                                                                              local.set 16
                                                                                              local.get 0
                                                                                              i32.const 392
                                                                                              i32.add
                                                                                              local.tee 3
                                                                                              call 42
                                                                                              block (result i64)  ;; label = @46
                                                                                                block  ;; label = @47
                                                                                                  block (result i64)  ;; label = @48
                                                                                                    local.get 3
                                                                                                    local.get 1
                                                                                                    call 44
                                                                                                    if  ;; label = @49
                                                                                                      i64.const 0
                                                                                                      local.set 13
                                                                                                      i64.const 6
                                                                                                      br 1 (;@48;)
                                                                                                    end
                                                                                                    local.get 0
                                                                                                    i32.const 456
                                                                                                    i32.add
                                                                                                    local.get 2
                                                                                                    call 46
                                                                                                    local.get 0
                                                                                                    i32.const 464
                                                                                                    i32.add
                                                                                                    i64.load
                                                                                                    local.set 15
                                                                                                    local.get 0
                                                                                                    i64.load offset=456
                                                                                                    local.set 17
                                                                                                    block  ;; label = @49
                                                                                                      block  ;; label = @50
                                                                                                        local.get 14
                                                                                                        local.get 16
                                                                                                        i64.or
                                                                                                        i64.eqz
                                                                                                        i32.eqz
                                                                                                        if  ;; label = @51
                                                                                                          local.get 0
                                                                                                          i64.load offset=120
                                                                                                          local.get 16
                                                                                                          i64.gt_u
                                                                                                          local.get 0
                                                                                                          i32.const 128
                                                                                                          i32.add
                                                                                                          i64.load
                                                                                                          local.tee 13
                                                                                                          local.get 14
                                                                                                          i64.gt_u
                                                                                                          local.get 13
                                                                                                          local.get 14
                                                                                                          i64.eq
                                                                                                          select
                                                                                                          br_if 1 (;@50;)
                                                                                                        end
                                                                                                        local.get 0
                                                                                                        local.get 16
                                                                                                        i64.store offset=456
                                                                                                        local.get 0
                                                                                                        local.get 14
                                                                                                        i64.store offset=464
                                                                                                        local.get 0
                                                                                                        i32.const 96
                                                                                                        i32.add
                                                                                                        i64.load
                                                                                                        local.set 18
                                                                                                        local.get 0
                                                                                                        i64.load offset=88
                                                                                                        local.set 19
                                                                                                        local.get 16
                                                                                                        local.get 17
                                                                                                        i64.lt_u
                                                                                                        local.tee 1
                                                                                                        local.get 14
                                                                                                        local.get 15
                                                                                                        i64.lt_u
                                                                                                        local.get 14
                                                                                                        local.get 15
                                                                                                        i64.eq
                                                                                                        select
                                                                                                        br_if 18 (;@32;)
                                                                                                        i64.const 0
                                                                                                        local.set 13
                                                                                                        local.get 19
                                                                                                        local.get 19
                                                                                                        i64.const 0
                                                                                                        local.get 16
                                                                                                        local.get 17
                                                                                                        i64.sub
                                                                                                        local.tee 17
                                                                                                        local.get 16
                                                                                                        local.get 17
                                                                                                        i64.lt_u
                                                                                                        local.get 14
                                                                                                        local.get 15
                                                                                                        i64.sub
                                                                                                        local.get 1
                                                                                                        i64.extend_i32_u
                                                                                                        i64.sub
                                                                                                        local.tee 15
                                                                                                        local.get 14
                                                                                                        i64.gt_u
                                                                                                        local.get 14
                                                                                                        local.get 15
                                                                                                        i64.eq
                                                                                                        select
                                                                                                        local.tee 1
                                                                                                        select
                                                                                                        local.tee 17
                                                                                                        i64.add
                                                                                                        local.tee 20
                                                                                                        i64.gt_u
                                                                                                        local.tee 3
                                                                                                        local.get 3
                                                                                                        i64.extend_i32_u
                                                                                                        local.get 18
                                                                                                        i64.const 0
                                                                                                        local.get 15
                                                                                                        local.get 1
                                                                                                        select
                                                                                                        local.tee 19
                                                                                                        i64.add
                                                                                                        i64.add
                                                                                                        local.tee 15
                                                                                                        local.get 18
                                                                                                        i64.lt_u
                                                                                                        local.get 15
                                                                                                        local.get 18
                                                                                                        i64.eq
                                                                                                        select
                                                                                                        br_if 1 (;@49;)
                                                                                                        local.get 0
                                                                                                        local.get 20
                                                                                                        i64.store offset=88
                                                                                                        local.get 0
                                                                                                        local.get 15
                                                                                                        i64.store offset=96
                                                                                                        local.get 0
                                                                                                        i64.load offset=104
                                                                                                        local.tee 15
                                                                                                        local.get 17
                                                                                                        i64.add
                                                                                                        local.tee 17
                                                                                                        local.get 15
                                                                                                        i64.lt_u
                                                                                                        local.tee 1
                                                                                                        local.get 1
                                                                                                        i64.extend_i32_u
                                                                                                        local.get 0
                                                                                                        i32.const 112
                                                                                                        i32.add
                                                                                                        i64.load
                                                                                                        local.tee 18
                                                                                                        local.get 19
                                                                                                        i64.add
                                                                                                        i64.add
                                                                                                        local.tee 15
                                                                                                        local.get 18
                                                                                                        i64.lt_u
                                                                                                        local.get 15
                                                                                                        local.get 18
                                                                                                        i64.eq
                                                                                                        select
                                                                                                        br_if 1 (;@49;)
                                                                                                        br 41 (;@9;)
                                                                                                      end
                                                                                                      local.get 0
                                                                                                      i64.const 0
                                                                                                      i64.store offset=464
                                                                                                      local.get 0
                                                                                                      i64.const 0
                                                                                                      i64.store offset=456
                                                                                                      local.get 0
                                                                                                      i32.const 112
                                                                                                      i32.add
                                                                                                      i64.load
                                                                                                      local.set 13
                                                                                                      local.get 0
                                                                                                      i64.load offset=104
                                                                                                      local.set 18
                                                                                                      local.get 16
                                                                                                      local.get 17
                                                                                                      i64.lt_u
                                                                                                      local.tee 1
                                                                                                      local.get 14
                                                                                                      local.get 15
                                                                                                      i64.lt_u
                                                                                                      local.get 14
                                                                                                      local.get 15
                                                                                                      i64.eq
                                                                                                      select
                                                                                                      br_if 2 (;@47;)
                                                                                                      i64.const -1
                                                                                                      local.get 13
                                                                                                      i64.const 0
                                                                                                      local.get 14
                                                                                                      local.get 15
                                                                                                      i64.sub
                                                                                                      local.get 1
                                                                                                      i64.extend_i32_u
                                                                                                      i64.sub
                                                                                                      local.tee 15
                                                                                                      local.get 16
                                                                                                      local.get 17
                                                                                                      i64.sub
                                                                                                      local.tee 17
                                                                                                      local.get 16
                                                                                                      i64.gt_u
                                                                                                      local.get 14
                                                                                                      local.get 15
                                                                                                      i64.lt_u
                                                                                                      local.get 14
                                                                                                      local.get 15
                                                                                                      i64.eq
                                                                                                      select
                                                                                                      local.tee 1
                                                                                                      select
                                                                                                      local.tee 19
                                                                                                      i64.add
                                                                                                      local.get 18
                                                                                                      i64.const 0
                                                                                                      local.get 17
                                                                                                      local.get 1
                                                                                                      select
                                                                                                      local.tee 20
                                                                                                      i64.add
                                                                                                      local.tee 17
                                                                                                      local.get 18
                                                                                                      i64.lt_u
                                                                                                      local.tee 1
                                                                                                      i64.extend_i32_u
                                                                                                      i64.add
                                                                                                      local.tee 15
                                                                                                      local.get 1
                                                                                                      local.get 13
                                                                                                      local.get 15
                                                                                                      i64.gt_u
                                                                                                      local.get 13
                                                                                                      local.get 15
                                                                                                      i64.eq
                                                                                                      select
                                                                                                      local.tee 1
                                                                                                      select
                                                                                                      local.set 15
                                                                                                      i64.const -1
                                                                                                      local.get 17
                                                                                                      local.get 1
                                                                                                      select
                                                                                                      local.set 17
                                                                                                      i64.const -1
                                                                                                      local.get 0
                                                                                                      i64.load offset=88
                                                                                                      local.tee 13
                                                                                                      local.get 20
                                                                                                      i64.add
                                                                                                      local.tee 20
                                                                                                      local.get 13
                                                                                                      i64.lt_u
                                                                                                      local.tee 1
                                                                                                      i64.extend_i32_u
                                                                                                      local.get 0
                                                                                                      i32.const 96
                                                                                                      i32.add
                                                                                                      i64.load
                                                                                                      local.tee 13
                                                                                                      local.get 19
                                                                                                      i64.add
                                                                                                      i64.add
                                                                                                      local.tee 18
                                                                                                      local.get 1
                                                                                                      local.get 13
                                                                                                      local.get 18
                                                                                                      i64.gt_u
                                                                                                      local.get 13
                                                                                                      local.get 18
                                                                                                      i64.eq
                                                                                                      select
                                                                                                      local.tee 1
                                                                                                      select
                                                                                                      local.set 13
                                                                                                      i64.const -1
                                                                                                      local.get 20
                                                                                                      local.get 1
                                                                                                      select
                                                                                                      br 3 (;@46;)
                                                                                                    end
                                                                                                    i64.const 4
                                                                                                  end
                                                                                                  local.set 16
                                                                                                  i64.const 2
                                                                                                  local.set 15
                                                                                                  i32.const 1
                                                                                                  br 40 (;@7;)
                                                                                                end
                                                                                                i64.const 0
                                                                                                local.get 13
                                                                                                i64.const 0
                                                                                                local.get 15
                                                                                                local.get 14
                                                                                                i64.sub
                                                                                                local.get 16
                                                                                                local.get 17
                                                                                                i64.gt_u
                                                                                                i64.extend_i32_u
                                                                                                i64.sub
                                                                                                local.tee 19
                                                                                                local.get 17
                                                                                                local.get 17
                                                                                                local.get 16
                                                                                                i64.sub
                                                                                                local.tee 20
                                                                                                i64.lt_u
                                                                                                local.get 15
                                                                                                local.get 19
                                                                                                i64.lt_u
                                                                                                local.get 15
                                                                                                local.get 19
                                                                                                i64.eq
                                                                                                select
                                                                                                local.tee 1
                                                                                                select
                                                                                                local.tee 21
                                                                                                i64.sub
                                                                                                local.get 18
                                                                                                i64.const 0
                                                                                                local.get 20
                                                                                                local.get 1
                                                                                                select
                                                                                                local.tee 19
                                                                                                i64.lt_u
                                                                                                i64.extend_i32_u
                                                                                                i64.sub
                                                                                                local.tee 15
                                                                                                local.get 18
                                                                                                local.get 19
                                                                                                i64.sub
                                                                                                local.tee 17
                                                                                                local.get 18
                                                                                                i64.gt_u
                                                                                                local.get 13
                                                                                                local.get 15
                                                                                                i64.lt_u
                                                                                                local.get 13
                                                                                                local.get 15
                                                                                                i64.eq
                                                                                                select
                                                                                                local.tee 1
                                                                                                select
                                                                                                local.set 15
                                                                                                i64.const 0
                                                                                                local.get 17
                                                                                                local.get 1
                                                                                                select
                                                                                                local.set 17
                                                                                                i64.const 0
                                                                                                local.get 0
                                                                                                i32.const 96
                                                                                                i32.add
                                                                                                i64.load
                                                                                                local.tee 13
                                                                                                local.get 21
                                                                                                i64.sub
                                                                                                local.get 0
                                                                                                i64.load offset=88
                                                                                                local.tee 18
                                                                                                local.get 19
                                                                                                i64.lt_u
                                                                                                i64.extend_i32_u
                                                                                                i64.sub
                                                                                                local.tee 20
                                                                                                local.get 18
                                                                                                local.get 18
                                                                                                local.get 19
                                                                                                i64.sub
                                                                                                local.tee 19
                                                                                                i64.lt_u
                                                                                                local.get 13
                                                                                                local.get 20
                                                                                                i64.lt_u
                                                                                                local.get 13
                                                                                                local.get 20
                                                                                                i64.eq
                                                                                                select
                                                                                                local.tee 1
                                                                                                select
                                                                                                local.set 13
                                                                                                i64.const 0
                                                                                                local.get 19
                                                                                                local.get 1
                                                                                                select
                                                                                              end
                                                                                              local.set 18
                                                                                              local.get 0
                                                                                              local.get 17
                                                                                              i64.store offset=104
                                                                                              local.get 0
                                                                                              local.get 18
                                                                                              i64.store offset=88
                                                                                              local.get 0
                                                                                              local.get 15
                                                                                              i64.store offset=112
                                                                                              local.get 0
                                                                                              local.get 13
                                                                                              i64.store offset=96
                                                                                              local.get 2
                                                                                              local.get 0
                                                                                              i32.const 456
                                                                                              i32.add
                                                                                              call 28
                                                                                              i64.const 1
                                                                                              br 37 (;@8;)
                                                                                            end
                                                                                            local.get 0
                                                                                            i32.const 216
                                                                                            i32.add
                                                                                            local.get 2
                                                                                            i32.const 56
                                                                                            call 9
                                                                                            local.set 1
                                                                                            local.get 0
                                                                                            local.get 0
                                                                                            i32.const 88
                                                                                            i32.add
                                                                                            local.tee 2
                                                                                            i32.store offset=208
                                                                                            local.get 0
                                                                                            i32.const 456
                                                                                            i32.add
                                                                                            local.tee 3
                                                                                            local.get 2
                                                                                            local.get 1
                                                                                            local.get 0
                                                                                            i64.load offset=248
                                                                                            local.get 0
                                                                                            i32.const 256
                                                                                            i32.add
                                                                                            i64.load
                                                                                            local.get 0
                                                                                            i32.load8_u offset=265
                                                                                            local.get 0
                                                                                            i32.load8_u offset=264
                                                                                            call 61
                                                                                            local.get 0
                                                                                            i32.load8_u offset=456
                                                                                            i32.const 1
                                                                                            i32.ne
                                                                                            br_if 42 (;@2;)
                                                                                            i32.const 1
                                                                                            local.get 3
                                                                                            call 52
                                                                                            unreachable
                                                                                          end
                                                                                          local.get 0
                                                                                          local.get 0
                                                                                          i32.const 88
                                                                                          i32.add
                                                                                          i32.store offset=208
                                                                                          local.get 0
                                                                                          i32.const 216
                                                                                          i32.add
                                                                                          local.get 2
                                                                                          i32.const 56
                                                                                          call 9
                                                                                          local.set 1
                                                                                          local.get 0
                                                                                          i64.load offset=248
                                                                                          local.tee 14
                                                                                          local.get 0
                                                                                          i32.const 256
                                                                                          i32.add
                                                                                          i64.load
                                                                                          local.tee 16
                                                                                          i64.or
                                                                                          i64.eqz
                                                                                          br_if 30 (;@13;)
                                                                                          local.get 0
                                                                                          i32.load8_u offset=264
                                                                                          local.set 4
                                                                                          local.get 0
                                                                                          i32.const 392
                                                                                          i32.add
                                                                                          local.get 1
                                                                                          call 46
                                                                                          block  ;; label = @44
                                                                                            local.get 0
                                                                                            i64.load offset=392
                                                                                            local.tee 15
                                                                                            local.get 0
                                                                                            i32.const 400
                                                                                            i32.add
                                                                                            i64.load
                                                                                            local.tee 13
                                                                                            i64.or
                                                                                            i64.const 0
                                                                                            i64.ne
                                                                                            br_if 0 (;@44;)
                                                                                            local.get 0
                                                                                            i64.load offset=120
                                                                                            local.get 14
                                                                                            i64.le_u
                                                                                            local.get 0
                                                                                            i32.const 128
                                                                                            i32.add
                                                                                            i64.load
                                                                                            local.tee 17
                                                                                            local.get 16
                                                                                            i64.le_u
                                                                                            local.get 16
                                                                                            local.get 17
                                                                                            i64.eq
                                                                                            select
                                                                                            br_if 0 (;@44;)
                                                                                            i32.const 1
                                                                                            local.set 3
                                                                                            i64.const 0
                                                                                            local.set 14
                                                                                            i64.const 0
                                                                                            local.set 16
                                                                                            local.get 4
                                                                                            i32.const 1
                                                                                            i32.and
                                                                                            br_if 31 (;@13;)
                                                                                            br 33 (;@11;)
                                                                                          end
                                                                                          block (result i64)  ;; label = @44
                                                                                            block  ;; label = @45
                                                                                              local.get 14
                                                                                              local.get 15
                                                                                              i64.add
                                                                                              local.tee 19
                                                                                              local.get 15
                                                                                              i64.lt_u
                                                                                              local.tee 3
                                                                                              local.get 3
                                                                                              i64.extend_i32_u
                                                                                              local.get 13
                                                                                              local.get 16
                                                                                              i64.add
                                                                                              i64.add
                                                                                              local.tee 17
                                                                                              local.get 13
                                                                                              i64.lt_u
                                                                                              local.get 13
                                                                                              local.get 17
                                                                                              i64.eq
                                                                                              select
                                                                                              i32.const 1
                                                                                              i32.eq
                                                                                              if  ;; label = @46
                                                                                                local.get 4
                                                                                                i32.const 1
                                                                                                i32.and
                                                                                                br_if 1 (;@45;)
                                                                                                br 34 (;@12;)
                                                                                              end
                                                                                              local.get 0
                                                                                              i64.load offset=88
                                                                                              local.tee 20
                                                                                              local.get 14
                                                                                              i64.add
                                                                                              local.tee 22
                                                                                              local.get 20
                                                                                              i64.lt_u
                                                                                              local.tee 3
                                                                                              local.get 3
                                                                                              i64.extend_i32_u
                                                                                              local.get 0
                                                                                              i32.const 96
                                                                                              i32.add
                                                                                              i64.load
                                                                                              local.tee 18
                                                                                              local.get 16
                                                                                              i64.add
                                                                                              i64.add
                                                                                              local.tee 21
                                                                                              local.get 18
                                                                                              i64.lt_u
                                                                                              local.get 18
                                                                                              local.get 21
                                                                                              i64.eq
                                                                                              select
                                                                                              local.tee 3
                                                                                              i32.eqz
                                                                                              if  ;; label = @46
                                                                                                local.get 0
                                                                                                i32.const 112
                                                                                                i32.add
                                                                                                local.tee 4
                                                                                                i64.const -1
                                                                                                local.get 0
                                                                                                i64.load offset=104
                                                                                                local.tee 13
                                                                                                local.get 14
                                                                                                i64.add
                                                                                                local.tee 18
                                                                                                local.get 13
                                                                                                i64.lt_u
                                                                                                local.tee 5
                                                                                                i64.extend_i32_u
                                                                                                local.get 4
                                                                                                i64.load
                                                                                                local.tee 13
                                                                                                local.get 16
                                                                                                i64.add
                                                                                                i64.add
                                                                                                local.tee 15
                                                                                                local.get 5
                                                                                                local.get 13
                                                                                                local.get 15
                                                                                                i64.gt_u
                                                                                                local.get 13
                                                                                                local.get 15
                                                                                                i64.eq
                                                                                                select
                                                                                                local.tee 4
                                                                                                select
                                                                                                i64.store
                                                                                                local.get 0
                                                                                                local.get 19
                                                                                                i64.store offset=392
                                                                                                local.get 0
                                                                                                local.get 17
                                                                                                i64.store offset=400
                                                                                                local.get 0
                                                                                                i64.const -1
                                                                                                local.get 21
                                                                                                local.get 3
                                                                                                select
                                                                                                i64.store offset=96
                                                                                                local.get 0
                                                                                                i64.const -1
                                                                                                local.get 22
                                                                                                local.get 3
                                                                                                select
                                                                                                i64.store offset=88
                                                                                                local.get 0
                                                                                                i64.const -1
                                                                                                local.get 18
                                                                                                local.get 4
                                                                                                select
                                                                                                i64.store offset=104
                                                                                                local.get 1
                                                                                                local.get 0
                                                                                                i32.const 392
                                                                                                i32.add
                                                                                                call 28
                                                                                                local.get 0
                                                                                                i32.const 480
                                                                                                i32.add
                                                                                                local.get 2
                                                                                                i32.const 24
                                                                                                i32.add
                                                                                                i64.load
                                                                                                i64.store
                                                                                                local.get 0
                                                                                                i32.const 472
                                                                                                i32.add
                                                                                                local.get 2
                                                                                                i32.const 16
                                                                                                i32.add
                                                                                                i64.load
                                                                                                i64.store
                                                                                                local.get 0
                                                                                                i32.const 464
                                                                                                i32.add
                                                                                                local.get 2
                                                                                                i32.const 8
                                                                                                i32.add
                                                                                                i64.load
                                                                                                i64.store
                                                                                                local.get 0
                                                                                                local.get 17
                                                                                                i64.store offset=496
                                                                                                local.get 0
                                                                                                local.get 19
                                                                                                i64.store offset=488
                                                                                                local.get 0
                                                                                                local.get 2
                                                                                                i64.load
                                                                                                i64.store offset=456
                                                                                                local.get 0
                                                                                                i32.const 456
                                                                                                i32.add
                                                                                                call 38
                                                                                                br 33 (;@13;)
                                                                                              end
                                                                                              local.get 4
                                                                                              i32.const 1
                                                                                              i32.and
                                                                                              i32.eqz
                                                                                              br_if 33 (;@12;)
                                                                                              local.get 0
                                                                                              i64.const -1
                                                                                              local.get 15
                                                                                              local.get 20
                                                                                              i64.const -1
                                                                                              i64.xor
                                                                                              local.tee 14
                                                                                              i64.add
                                                                                              local.tee 17
                                                                                              local.get 15
                                                                                              i64.lt_u
                                                                                              local.tee 2
                                                                                              i64.extend_i32_u
                                                                                              local.get 13
                                                                                              local.get 18
                                                                                              i64.const -1
                                                                                              i64.xor
                                                                                              local.tee 16
                                                                                              i64.add
                                                                                              i64.add
                                                                                              local.tee 15
                                                                                              local.get 2
                                                                                              local.get 13
                                                                                              local.get 15
                                                                                              i64.gt_u
                                                                                              local.get 13
                                                                                              local.get 15
                                                                                              i64.eq
                                                                                              select
                                                                                              local.tee 2
                                                                                              select
                                                                                              i64.store offset=400
                                                                                              local.get 0
                                                                                              i64.const -1
                                                                                              local.get 17
                                                                                              local.get 2
                                                                                              select
                                                                                              i64.store offset=392
                                                                                              i64.const -1
                                                                                              local.set 13
                                                                                              i64.const -1
                                                                                              br 1 (;@44;)
                                                                                            end
                                                                                            local.get 0
                                                                                            i64.const -1
                                                                                            i64.store offset=400
                                                                                            local.get 0
                                                                                            i64.const -1
                                                                                            i64.store offset=392
                                                                                            i64.const -1
                                                                                            local.get 0
                                                                                            i64.load offset=88
                                                                                            local.tee 16
                                                                                            local.get 15
                                                                                            i64.const -1
                                                                                            i64.xor
                                                                                            local.tee 14
                                                                                            i64.add
                                                                                            local.tee 17
                                                                                            local.get 16
                                                                                            i64.lt_u
                                                                                            local.tee 2
                                                                                            i64.extend_i32_u
                                                                                            local.get 0
                                                                                            i32.const 96
                                                                                            i32.add
                                                                                            i64.load
                                                                                            local.tee 15
                                                                                            local.get 13
                                                                                            i64.const -1
                                                                                            i64.xor
                                                                                            local.tee 16
                                                                                            i64.add
                                                                                            i64.add
                                                                                            local.tee 13
                                                                                            local.get 2
                                                                                            local.get 13
                                                                                            local.get 15
                                                                                            i64.lt_u
                                                                                            local.get 13
                                                                                            local.get 15
                                                                                            i64.eq
                                                                                            select
                                                                                            local.tee 2
                                                                                            select
                                                                                            local.set 13
                                                                                            i64.const -1
                                                                                            local.get 17
                                                                                            local.get 2
                                                                                            select
                                                                                          end
                                                                                          local.set 18
                                                                                          local.get 0
                                                                                          i32.const 112
                                                                                          i32.add
                                                                                          local.tee 2
                                                                                          i64.const -1
                                                                                          local.get 0
                                                                                          i64.load offset=104
                                                                                          local.tee 15
                                                                                          local.get 14
                                                                                          i64.add
                                                                                          local.tee 19
                                                                                          local.get 15
                                                                                          i64.lt_u
                                                                                          local.tee 3
                                                                                          i64.extend_i32_u
                                                                                          local.get 2
                                                                                          i64.load
                                                                                          local.tee 15
                                                                                          local.get 16
                                                                                          i64.add
                                                                                          i64.add
                                                                                          local.tee 17
                                                                                          local.get 3
                                                                                          local.get 15
                                                                                          local.get 17
                                                                                          i64.gt_u
                                                                                          local.get 15
                                                                                          local.get 17
                                                                                          i64.eq
                                                                                          select
                                                                                          local.tee 3
                                                                                          select
                                                                                          i64.store
                                                                                          local.get 0
                                                                                          local.get 18
                                                                                          i64.store offset=88
                                                                                          local.get 0
                                                                                          local.get 13
                                                                                          i64.store offset=96
                                                                                          local.get 0
                                                                                          i64.const -1
                                                                                          local.get 19
                                                                                          local.get 3
                                                                                          select
                                                                                          i64.store offset=104
                                                                                          local.get 1
                                                                                          local.get 0
                                                                                          i32.const 392
                                                                                          i32.add
                                                                                          call 28
                                                                                          br 30 (;@13;)
                                                                                        end
                                                                                        local.get 0
                                                                                        i32.const 208
                                                                                        i32.add
                                                                                        local.tee 2
                                                                                        call 42
                                                                                        local.get 2
                                                                                        local.get 1
                                                                                        call 44
                                                                                        i32.eqz
                                                                                        br_if 20 (;@22;)
                                                                                        i32.const 1
                                                                                        local.set 2
                                                                                        i32.const 6
                                                                                        br 21 (;@21;)
                                                                                      end
                                                                                      local.get 0
                                                                                      i32.const 208
                                                                                      i32.add
                                                                                      local.tee 2
                                                                                      call 42
                                                                                      local.get 2
                                                                                      local.get 1
                                                                                      call 44
                                                                                      i32.eqz
                                                                                      br_if 17 (;@24;)
                                                                                      i32.const 1
                                                                                      local.set 2
                                                                                      i32.const 6
                                                                                      br 18 (;@23;)
                                                                                    end
                                                                                    local.get 0
                                                                                    i32.const 208
                                                                                    i32.add
                                                                                    local.tee 2
                                                                                    call 42
                                                                                    local.get 2
                                                                                    local.get 1
                                                                                    call 44
                                                                                    i32.eqz
                                                                                    br_if 14 (;@26;)
                                                                                    i32.const 1
                                                                                    local.set 2
                                                                                    i32.const 6
                                                                                    br 15 (;@25;)
                                                                                  end
                                                                                  local.get 0
                                                                                  i32.const 216
                                                                                  i32.add
                                                                                  local.get 2
                                                                                  i32.const 56
                                                                                  call 9
                                                                                  local.set 1
                                                                                  local.get 0
                                                                                  local.get 0
                                                                                  i32.const 88
                                                                                  i32.add
                                                                                  local.tee 2
                                                                                  i32.store offset=208
                                                                                  local.get 0
                                                                                  i32.const 456
                                                                                  i32.add
                                                                                  local.tee 3
                                                                                  local.get 2
                                                                                  local.get 1
                                                                                  local.get 0
                                                                                  i64.load offset=248
                                                                                  local.get 0
                                                                                  i32.const 256
                                                                                  i32.add
                                                                                  i64.load
                                                                                  local.get 0
                                                                                  i32.load8_u offset=265
                                                                                  local.get 0
                                                                                  i32.load8_u offset=264
                                                                                  call 61
                                                                                  local.get 0
                                                                                  i32.load8_u offset=456
                                                                                  i32.const 1
                                                                                  i32.ne
                                                                                  br_if 37 (;@2;)
                                                                                  i32.const 1
                                                                                  local.get 3
                                                                                  call 52
                                                                                  unreachable
                                                                                end
                                                                                local.get 0
                                                                                local.get 0
                                                                                i32.const 88
                                                                                i32.add
                                                                                i32.store offset=208
                                                                                local.get 0
                                                                                i32.const 216
                                                                                i32.add
                                                                                local.get 2
                                                                                i32.const 48
                                                                                call 9
                                                                                local.set 3
                                                                                block (result i32)  ;; label = @39
                                                                                  block  ;; label = @40
                                                                                    local.get 0
                                                                                    i64.load offset=248
                                                                                    local.tee 14
                                                                                    local.get 0
                                                                                    i32.const 256
                                                                                    i32.add
                                                                                    i64.load
                                                                                    local.tee 13
                                                                                    i64.or
                                                                                    i64.eqz
                                                                                    i32.eqz
                                                                                    if  ;; label = @41
                                                                                      local.get 0
                                                                                      i32.const 392
                                                                                      i32.add
                                                                                      local.get 3
                                                                                      call 46
                                                                                      local.get 0
                                                                                      i64.load offset=392
                                                                                      local.tee 15
                                                                                      local.get 0
                                                                                      i32.const 400
                                                                                      i32.add
                                                                                      i64.load
                                                                                      local.tee 16
                                                                                      i64.or
                                                                                      i64.eqz
                                                                                      if  ;; label = @42
                                                                                        i32.const 1
                                                                                        local.set 1
                                                                                        local.get 0
                                                                                        i64.load offset=120
                                                                                        local.get 14
                                                                                        i64.gt_u
                                                                                        local.get 0
                                                                                        i32.const 128
                                                                                        i32.add
                                                                                        i64.load
                                                                                        local.tee 17
                                                                                        local.get 13
                                                                                        i64.gt_u
                                                                                        local.get 13
                                                                                        local.get 17
                                                                                        i64.eq
                                                                                        select
                                                                                        br_if 2 (;@40;)
                                                                                      end
                                                                                      i32.const 4
                                                                                      local.set 1
                                                                                      local.get 0
                                                                                      i64.load offset=88
                                                                                      local.tee 17
                                                                                      local.get 14
                                                                                      i64.add
                                                                                      local.tee 19
                                                                                      local.get 17
                                                                                      i64.lt_u
                                                                                      local.tee 4
                                                                                      local.get 4
                                                                                      i64.extend_i32_u
                                                                                      local.get 0
                                                                                      i32.const 96
                                                                                      i32.add
                                                                                      i64.load
                                                                                      local.tee 17
                                                                                      local.get 13
                                                                                      i64.add
                                                                                      i64.add
                                                                                      local.tee 18
                                                                                      local.get 17
                                                                                      i64.lt_u
                                                                                      local.get 17
                                                                                      local.get 18
                                                                                      i64.eq
                                                                                      select
                                                                                      br_if 1 (;@40;)
                                                                                      local.get 0
                                                                                      local.get 19
                                                                                      i64.store offset=88
                                                                                      local.get 0
                                                                                      local.get 18
                                                                                      i64.store offset=96
                                                                                      local.get 0
                                                                                      i64.load offset=104
                                                                                      local.tee 17
                                                                                      local.get 14
                                                                                      i64.add
                                                                                      local.tee 19
                                                                                      local.get 17
                                                                                      i64.lt_u
                                                                                      local.tee 4
                                                                                      local.get 4
                                                                                      i64.extend_i32_u
                                                                                      local.get 0
                                                                                      i32.const 112
                                                                                      i32.add
                                                                                      i64.load
                                                                                      local.tee 17
                                                                                      local.get 13
                                                                                      i64.add
                                                                                      i64.add
                                                                                      local.tee 18
                                                                                      local.get 17
                                                                                      i64.lt_u
                                                                                      local.get 17
                                                                                      local.get 18
                                                                                      i64.eq
                                                                                      select
                                                                                      br_if 1 (;@40;)
                                                                                      local.get 0
                                                                                      local.get 19
                                                                                      i64.store offset=104
                                                                                      local.get 0
                                                                                      local.get 18
                                                                                      i64.store offset=112
                                                                                      local.get 14
                                                                                      local.get 15
                                                                                      i64.add
                                                                                      local.tee 17
                                                                                      local.get 15
                                                                                      i64.lt_u
                                                                                      local.tee 4
                                                                                      local.get 4
                                                                                      i64.extend_i32_u
                                                                                      local.get 13
                                                                                      local.get 16
                                                                                      i64.add
                                                                                      i64.add
                                                                                      local.tee 15
                                                                                      local.get 16
                                                                                      i64.lt_u
                                                                                      local.get 15
                                                                                      local.get 16
                                                                                      i64.eq
                                                                                      select
                                                                                      br_if 1 (;@40;)
                                                                                      local.get 0
                                                                                      local.get 17
                                                                                      i64.store offset=392
                                                                                      local.get 0
                                                                                      local.get 15
                                                                                      i64.store offset=400
                                                                                      local.get 3
                                                                                      local.get 0
                                                                                      i32.const 392
                                                                                      i32.add
                                                                                      call 28
                                                                                      local.get 0
                                                                                      i32.const 480
                                                                                      i32.add
                                                                                      local.get 2
                                                                                      i32.const 24
                                                                                      i32.add
                                                                                      i64.load
                                                                                      i64.store
                                                                                      local.get 0
                                                                                      i32.const 472
                                                                                      i32.add
                                                                                      local.get 2
                                                                                      i32.const 16
                                                                                      i32.add
                                                                                      i64.load
                                                                                      i64.store
                                                                                      local.get 0
                                                                                      i32.const 464
                                                                                      i32.add
                                                                                      local.get 2
                                                                                      i32.const 8
                                                                                      i32.add
                                                                                      i64.load
                                                                                      i64.store
                                                                                      local.get 0
                                                                                      i64.const 16384
                                                                                      i64.store offset=332 align=4
                                                                                      local.get 0
                                                                                      i32.const 66280
                                                                                      i32.store offset=328
                                                                                      local.get 0
                                                                                      local.get 13
                                                                                      i64.store offset=496
                                                                                      local.get 0
                                                                                      local.get 14
                                                                                      i64.store offset=488
                                                                                      local.get 0
                                                                                      local.get 2
                                                                                      i64.load
                                                                                      i64.store offset=456
                                                                                      local.get 0
                                                                                      local.get 0
                                                                                      i32.const 456
                                                                                      i32.add
                                                                                      local.tee 4
                                                                                      i32.store offset=376
                                                                                      local.get 0
                                                                                      i32.const 328
                                                                                      i32.add
                                                                                      local.tee 1
                                                                                      i32.const 2
                                                                                      call 34
                                                                                      local.get 1
                                                                                      i32.const 65841
                                                                                      call 30
                                                                                      local.get 0
                                                                                      i32.const 516
                                                                                      i32.add
                                                                                      local.tee 2
                                                                                      local.get 1
                                                                                      local.get 0
                                                                                      i32.const 376
                                                                                      i32.add
                                                                                      call 39
                                                                                      local.get 0
                                                                                      i32.load offset=520
                                                                                      local.tee 5
                                                                                      local.get 0
                                                                                      i32.load offset=524
                                                                                      local.tee 1
                                                                                      i32.lt_u
                                                                                      br_if 25 (;@16;)
                                                                                      local.get 0
                                                                                      i32.load offset=516
                                                                                      local.set 3
                                                                                      local.get 0
                                                                                      i32.const 0
                                                                                      i32.store offset=524
                                                                                      local.get 0
                                                                                      local.get 5
                                                                                      local.get 1
                                                                                      i32.sub
                                                                                      i32.store offset=520
                                                                                      local.get 0
                                                                                      local.get 1
                                                                                      local.get 3
                                                                                      i32.add
                                                                                      i32.store offset=516
                                                                                      local.get 4
                                                                                      local.get 2
                                                                                      call 31
                                                                                      local.get 0
                                                                                      i64.load offset=488
                                                                                      local.get 0
                                                                                      i32.const 496
                                                                                      i32.add
                                                                                      i64.load
                                                                                      local.get 2
                                                                                      call 27
                                                                                      local.get 0
                                                                                      i32.load offset=524
                                                                                      local.tee 2
                                                                                      local.get 0
                                                                                      i32.load offset=520
                                                                                      i32.gt_u
                                                                                      br_if 25 (;@16;)
                                                                                      local.get 3
                                                                                      local.get 1
                                                                                      local.get 0
                                                                                      i32.load offset=516
                                                                                      local.get 2
                                                                                      call 2
                                                                                    end
                                                                                    local.get 0
                                                                                    i32.const 208
                                                                                    i32.add
                                                                                    local.tee 1
                                                                                    local.get 0
                                                                                    i32.const 88
                                                                                    i32.add
                                                                                    i32.const 120
                                                                                    call 9
                                                                                    drop
                                                                                    local.get 1
                                                                                    call 54
                                                                                    i32.const 7
                                                                                    local.set 1
                                                                                    i32.const 0
                                                                                    br 1 (;@39;)
                                                                                  end
                                                                                  i32.const 1
                                                                                end
                                                                                local.get 1
                                                                                call 49
                                                                                unreachable
                                                                              end
                                                                              local.get 0
                                                                              local.get 0
                                                                              i32.const 88
                                                                              i32.add
                                                                              i32.store offset=208
                                                                              local.get 0
                                                                              i32.const 216
                                                                              i32.add
                                                                              local.get 2
                                                                              i32.const 48
                                                                              call 9
                                                                              local.set 1
                                                                              block (result i32)  ;; label = @38
                                                                                block  ;; label = @39
                                                                                  local.get 0
                                                                                  i64.load offset=248
                                                                                  local.tee 13
                                                                                  local.get 0
                                                                                  i32.const 256
                                                                                  i32.add
                                                                                  i64.load
                                                                                  local.tee 14
                                                                                  i64.or
                                                                                  i64.eqz
                                                                                  i32.eqz
                                                                                  if  ;; label = @40
                                                                                    local.get 0
                                                                                    i32.const 392
                                                                                    i32.add
                                                                                    local.tee 3
                                                                                    local.get 1
                                                                                    call 46
                                                                                    local.get 0
                                                                                    i64.load offset=392
                                                                                    local.tee 19
                                                                                    local.get 13
                                                                                    i64.lt_u
                                                                                    local.tee 4
                                                                                    local.get 0
                                                                                    i32.const 400
                                                                                    i32.add
                                                                                    i64.load
                                                                                    local.tee 16
                                                                                    local.get 14
                                                                                    i64.lt_u
                                                                                    local.get 14
                                                                                    local.get 16
                                                                                    i64.eq
                                                                                    select
                                                                                    br_if 1 (;@39;)
                                                                                    local.get 0
                                                                                    i32.const 96
                                                                                    i32.add
                                                                                    local.tee 5
                                                                                    i64.const 0
                                                                                    local.get 5
                                                                                    i64.load
                                                                                    local.tee 15
                                                                                    local.get 14
                                                                                    i64.sub
                                                                                    local.get 0
                                                                                    i64.load offset=88
                                                                                    local.tee 17
                                                                                    local.get 13
                                                                                    i64.lt_u
                                                                                    i64.extend_i32_u
                                                                                    i64.sub
                                                                                    local.tee 18
                                                                                    local.get 17
                                                                                    local.get 13
                                                                                    i64.sub
                                                                                    local.tee 20
                                                                                    local.get 17
                                                                                    i64.gt_u
                                                                                    local.get 15
                                                                                    local.get 18
                                                                                    i64.lt_u
                                                                                    local.get 15
                                                                                    local.get 18
                                                                                    i64.eq
                                                                                    select
                                                                                    local.tee 5
                                                                                    select
                                                                                    i64.store
                                                                                    local.get 0
                                                                                    i32.const 112
                                                                                    i32.add
                                                                                    local.tee 6
                                                                                    i64.const 0
                                                                                    local.get 6
                                                                                    i64.load
                                                                                    local.tee 15
                                                                                    local.get 14
                                                                                    i64.sub
                                                                                    local.get 0
                                                                                    i64.load offset=104
                                                                                    local.tee 17
                                                                                    local.get 13
                                                                                    i64.lt_u
                                                                                    i64.extend_i32_u
                                                                                    i64.sub
                                                                                    local.tee 18
                                                                                    local.get 17
                                                                                    local.get 17
                                                                                    local.get 13
                                                                                    i64.sub
                                                                                    local.tee 21
                                                                                    i64.lt_u
                                                                                    local.get 15
                                                                                    local.get 18
                                                                                    i64.lt_u
                                                                                    local.get 15
                                                                                    local.get 18
                                                                                    i64.eq
                                                                                    select
                                                                                    local.tee 6
                                                                                    select
                                                                                    i64.store
                                                                                    local.get 0
                                                                                    local.get 19
                                                                                    local.get 13
                                                                                    i64.sub
                                                                                    i64.store offset=392
                                                                                    local.get 0
                                                                                    local.get 16
                                                                                    local.get 14
                                                                                    i64.sub
                                                                                    local.get 4
                                                                                    i64.extend_i32_u
                                                                                    i64.sub
                                                                                    i64.store offset=400
                                                                                    local.get 0
                                                                                    i64.const 0
                                                                                    local.get 20
                                                                                    local.get 5
                                                                                    select
                                                                                    i64.store offset=88
                                                                                    local.get 0
                                                                                    i64.const 0
                                                                                    local.get 21
                                                                                    local.get 6
                                                                                    select
                                                                                    i64.store offset=104
                                                                                    local.get 1
                                                                                    local.get 3
                                                                                    call 28
                                                                                    local.get 0
                                                                                    i32.const 480
                                                                                    i32.add
                                                                                    local.get 2
                                                                                    i32.const 24
                                                                                    i32.add
                                                                                    i64.load
                                                                                    i64.store
                                                                                    local.get 0
                                                                                    i32.const 472
                                                                                    i32.add
                                                                                    local.get 2
                                                                                    i32.const 16
                                                                                    i32.add
                                                                                    i64.load
                                                                                    i64.store
                                                                                    local.get 0
                                                                                    i32.const 464
                                                                                    i32.add
                                                                                    local.get 2
                                                                                    i32.const 8
                                                                                    i32.add
                                                                                    i64.load
                                                                                    i64.store
                                                                                    local.get 0
                                                                                    i64.const 16384
                                                                                    i64.store offset=344 align=4
                                                                                    local.get 0
                                                                                    i32.const 66280
                                                                                    i32.store offset=340
                                                                                    local.get 0
                                                                                    local.get 14
                                                                                    i64.store offset=496
                                                                                    local.get 0
                                                                                    local.get 13
                                                                                    i64.store offset=488
                                                                                    local.get 0
                                                                                    local.get 2
                                                                                    i64.load
                                                                                    i64.store offset=456
                                                                                    local.get 0
                                                                                    local.get 0
                                                                                    i32.const 456
                                                                                    i32.add
                                                                                    local.tee 4
                                                                                    i32.store offset=376
                                                                                    local.get 0
                                                                                    i32.const 340
                                                                                    i32.add
                                                                                    local.tee 1
                                                                                    i32.const 2
                                                                                    call 34
                                                                                    local.get 1
                                                                                    i32.const 65874
                                                                                    call 30
                                                                                    local.get 0
                                                                                    i32.const 516
                                                                                    i32.add
                                                                                    local.tee 2
                                                                                    local.get 1
                                                                                    local.get 0
                                                                                    i32.const 376
                                                                                    i32.add
                                                                                    call 39
                                                                                    local.get 0
                                                                                    i32.load offset=520
                                                                                    local.tee 5
                                                                                    local.get 0
                                                                                    i32.load offset=524
                                                                                    local.tee 1
                                                                                    i32.lt_u
                                                                                    br_if 24 (;@16;)
                                                                                    local.get 0
                                                                                    i32.load offset=516
                                                                                    local.set 3
                                                                                    local.get 0
                                                                                    i32.const 0
                                                                                    i32.store offset=524
                                                                                    local.get 0
                                                                                    local.get 5
                                                                                    local.get 1
                                                                                    i32.sub
                                                                                    i32.store offset=520
                                                                                    local.get 0
                                                                                    local.get 1
                                                                                    local.get 3
                                                                                    i32.add
                                                                                    i32.store offset=516
                                                                                    local.get 4
                                                                                    local.get 2
                                                                                    call 31
                                                                                    local.get 0
                                                                                    i64.load offset=488
                                                                                    local.get 0
                                                                                    i32.const 496
                                                                                    i32.add
                                                                                    i64.load
                                                                                    local.get 2
                                                                                    call 27
                                                                                    local.get 0
                                                                                    i32.load offset=524
                                                                                    local.tee 2
                                                                                    local.get 0
                                                                                    i32.load offset=520
                                                                                    i32.gt_u
                                                                                    br_if 24 (;@16;)
                                                                                    local.get 3
                                                                                    local.get 1
                                                                                    local.get 0
                                                                                    i32.load offset=516
                                                                                    local.get 2
                                                                                    call 2
                                                                                  end
                                                                                  local.get 0
                                                                                  i32.const 208
                                                                                  i32.add
                                                                                  local.tee 1
                                                                                  local.get 0
                                                                                  i32.const 88
                                                                                  i32.add
                                                                                  i32.const 120
                                                                                  call 9
                                                                                  drop
                                                                                  local.get 1
                                                                                  call 54
                                                                                  i32.const 0
                                                                                  local.set 2
                                                                                  i32.const 7
                                                                                  br 1 (;@38;)
                                                                                end
                                                                                i32.const 1
                                                                                local.set 2
                                                                                i32.const 0
                                                                              end
                                                                              local.set 1
                                                                              br 34 (;@3;)
                                                                            end
                                                                            local.get 0
                                                                            i32.const 464
                                                                            i32.add
                                                                            local.set 4
                                                                            global.get 0
                                                                            i32.const 112
                                                                            i32.sub
                                                                            local.tee 3
                                                                            global.set 0
                                                                            local.get 3
                                                                            local.get 0
                                                                            i32.const 88
                                                                            i32.add
                                                                            local.tee 1
                                                                            i32.store offset=8
                                                                            local.get 3
                                                                            i32.const 16
                                                                            i32.add
                                                                            local.get 2
                                                                            i32.const 48
                                                                            call 9
                                                                            local.set 2
                                                                            local.get 3
                                                                            i32.const 56
                                                                            i32.add
                                                                            i64.load
                                                                            local.set 13
                                                                            local.get 3
                                                                            i64.load offset=48
                                                                            local.set 14
                                                                            local.get 3
                                                                            i32.const -64
                                                                            i32.sub
                                                                            local.get 2
                                                                            call 46
                                                                            block  ;; label = @37
                                                                              block  ;; label = @38
                                                                                local.get 14
                                                                                local.get 3
                                                                                i64.load offset=64
                                                                                local.tee 16
                                                                                i64.xor
                                                                                local.get 13
                                                                                local.get 3
                                                                                i32.const 72
                                                                                i32.add
                                                                                i64.load
                                                                                local.tee 15
                                                                                i64.xor
                                                                                i64.or
                                                                                i64.eqz
                                                                                i32.eqz
                                                                                if  ;; label = @39
                                                                                  block  ;; label = @40
                                                                                    local.get 14
                                                                                    local.get 16
                                                                                    i64.le_u
                                                                                    local.get 13
                                                                                    local.get 15
                                                                                    i64.le_u
                                                                                    local.get 13
                                                                                    local.get 15
                                                                                    i64.eq
                                                                                    select
                                                                                    i32.eqz
                                                                                    if  ;; label = @41
                                                                                      local.get 1
                                                                                      i64.load
                                                                                      local.tee 17
                                                                                      i64.const 0
                                                                                      local.get 14
                                                                                      local.get 16
                                                                                      i64.sub
                                                                                      local.tee 18
                                                                                      local.get 14
                                                                                      local.get 18
                                                                                      i64.lt_u
                                                                                      local.get 13
                                                                                      local.get 15
                                                                                      i64.sub
                                                                                      local.get 14
                                                                                      local.get 16
                                                                                      i64.lt_u
                                                                                      i64.extend_i32_u
                                                                                      i64.sub
                                                                                      local.tee 14
                                                                                      local.get 13
                                                                                      i64.gt_u
                                                                                      local.get 13
                                                                                      local.get 14
                                                                                      i64.eq
                                                                                      select
                                                                                      local.tee 5
                                                                                      select
                                                                                      local.tee 13
                                                                                      i64.add
                                                                                      local.tee 20
                                                                                      local.get 17
                                                                                      i64.lt_u
                                                                                      local.tee 6
                                                                                      local.get 6
                                                                                      i64.extend_i32_u
                                                                                      local.get 1
                                                                                      i32.const 8
                                                                                      i32.add
                                                                                      i64.load
                                                                                      local.tee 17
                                                                                      i64.const 0
                                                                                      local.get 14
                                                                                      local.get 5
                                                                                      select
                                                                                      local.tee 18
                                                                                      i64.add
                                                                                      i64.add
                                                                                      local.tee 19
                                                                                      local.get 17
                                                                                      i64.lt_u
                                                                                      local.get 17
                                                                                      local.get 19
                                                                                      i64.eq
                                                                                      select
                                                                                      br_if 3 (;@38;)
                                                                                      local.get 13
                                                                                      local.get 16
                                                                                      i64.add
                                                                                      local.tee 14
                                                                                      local.get 16
                                                                                      i64.lt_u
                                                                                      local.tee 5
                                                                                      local.get 15
                                                                                      local.get 18
                                                                                      i64.add
                                                                                      local.tee 17
                                                                                      local.get 5
                                                                                      i64.extend_i32_u
                                                                                      i64.add
                                                                                      local.tee 21
                                                                                      local.get 15
                                                                                      i64.lt_u
                                                                                      local.get 15
                                                                                      local.get 21
                                                                                      i64.eq
                                                                                      select
                                                                                      br_if 3 (;@38;)
                                                                                      local.get 1
                                                                                      local.get 20
                                                                                      i64.store
                                                                                      local.get 1
                                                                                      local.get 19
                                                                                      i64.store offset=8
                                                                                      local.get 1
                                                                                      i64.const -1
                                                                                      local.get 1
                                                                                      i64.load offset=16
                                                                                      local.tee 16
                                                                                      local.get 13
                                                                                      i64.add
                                                                                      local.tee 15
                                                                                      local.get 15
                                                                                      local.get 16
                                                                                      i64.lt_u
                                                                                      local.tee 5
                                                                                      local.get 5
                                                                                      i64.extend_i32_u
                                                                                      local.get 1
                                                                                      i32.const 24
                                                                                      i32.add
                                                                                      local.tee 5
                                                                                      i64.load
                                                                                      local.tee 16
                                                                                      local.get 18
                                                                                      i64.add
                                                                                      i64.add
                                                                                      local.tee 15
                                                                                      local.get 16
                                                                                      i64.lt_u
                                                                                      local.get 15
                                                                                      local.get 16
                                                                                      i64.eq
                                                                                      select
                                                                                      local.tee 6
                                                                                      select
                                                                                      i64.store offset=16
                                                                                      local.get 5
                                                                                      i64.const -1
                                                                                      local.get 15
                                                                                      local.get 6
                                                                                      select
                                                                                      i64.store
                                                                                      local.get 17
                                                                                      local.get 13
                                                                                      local.get 14
                                                                                      i64.gt_u
                                                                                      i64.extend_i32_u
                                                                                      i64.add
                                                                                      local.set 13
                                                                                      br 1 (;@40;)
                                                                                    end
                                                                                    local.get 1
                                                                                    i64.const 0
                                                                                    local.get 1
                                                                                    i64.load
                                                                                    local.tee 17
                                                                                    i64.const 0
                                                                                    local.get 16
                                                                                    local.get 14
                                                                                    i64.sub
                                                                                    local.tee 18
                                                                                    local.get 16
                                                                                    local.get 18
                                                                                    i64.lt_u
                                                                                    local.get 15
                                                                                    local.get 13
                                                                                    i64.sub
                                                                                    local.get 14
                                                                                    local.get 16
                                                                                    i64.gt_u
                                                                                    i64.extend_i32_u
                                                                                    i64.sub
                                                                                    local.tee 13
                                                                                    local.get 15
                                                                                    i64.gt_u
                                                                                    local.get 13
                                                                                    local.get 15
                                                                                    i64.eq
                                                                                    select
                                                                                    local.tee 5
                                                                                    select
                                                                                    local.tee 14
                                                                                    i64.sub
                                                                                    local.tee 18
                                                                                    local.get 17
                                                                                    local.get 18
                                                                                    i64.lt_u
                                                                                    local.get 1
                                                                                    i32.const 8
                                                                                    i32.add
                                                                                    local.tee 6
                                                                                    i64.load
                                                                                    local.tee 18
                                                                                    i64.const 0
                                                                                    local.get 13
                                                                                    local.get 5
                                                                                    select
                                                                                    local.tee 13
                                                                                    i64.sub
                                                                                    local.get 14
                                                                                    local.get 17
                                                                                    i64.gt_u
                                                                                    i64.extend_i32_u
                                                                                    i64.sub
                                                                                    local.tee 17
                                                                                    local.get 18
                                                                                    i64.gt_u
                                                                                    local.get 17
                                                                                    local.get 18
                                                                                    i64.eq
                                                                                    select
                                                                                    local.tee 5
                                                                                    select
                                                                                    i64.store
                                                                                    local.get 6
                                                                                    i64.const 0
                                                                                    local.get 17
                                                                                    local.get 5
                                                                                    select
                                                                                    i64.store
                                                                                    local.get 1
                                                                                    i64.const 0
                                                                                    local.get 1
                                                                                    i64.load offset=16
                                                                                    local.tee 17
                                                                                    local.get 14
                                                                                    i64.sub
                                                                                    local.tee 18
                                                                                    local.get 17
                                                                                    local.get 18
                                                                                    i64.lt_u
                                                                                    local.get 1
                                                                                    i32.const 24
                                                                                    i32.add
                                                                                    local.tee 5
                                                                                    i64.load
                                                                                    local.tee 18
                                                                                    local.get 13
                                                                                    i64.sub
                                                                                    local.get 14
                                                                                    local.get 17
                                                                                    i64.gt_u
                                                                                    i64.extend_i32_u
                                                                                    i64.sub
                                                                                    local.tee 17
                                                                                    local.get 18
                                                                                    i64.gt_u
                                                                                    local.get 17
                                                                                    local.get 18
                                                                                    i64.eq
                                                                                    select
                                                                                    local.tee 6
                                                                                    select
                                                                                    i64.store offset=16
                                                                                    local.get 5
                                                                                    i64.const 0
                                                                                    local.get 17
                                                                                    local.get 6
                                                                                    select
                                                                                    i64.store
                                                                                    local.get 15
                                                                                    local.get 13
                                                                                    i64.sub
                                                                                    local.get 14
                                                                                    local.get 16
                                                                                    i64.gt_u
                                                                                    i64.extend_i32_u
                                                                                    i64.sub
                                                                                    local.set 13
                                                                                    local.get 16
                                                                                    local.get 14
                                                                                    i64.sub
                                                                                    local.set 14
                                                                                  end
                                                                                  local.get 3
                                                                                  local.get 14
                                                                                  i64.store offset=64
                                                                                  local.get 3
                                                                                  local.get 13
                                                                                  i64.store offset=72
                                                                                  local.get 2
                                                                                  local.get 3
                                                                                  i32.const -64
                                                                                  i32.sub
                                                                                  call 28
                                                                                end
                                                                                local.get 4
                                                                                local.get 14
                                                                                i64.store
                                                                                local.get 4
                                                                                local.get 13
                                                                                i64.store offset=8
                                                                                br 1 (;@37;)
                                                                              end
                                                                              local.get 4
                                                                              local.get 16
                                                                              i64.store
                                                                              local.get 4
                                                                              local.get 15
                                                                              i64.store offset=8
                                                                            end
                                                                            local.get 3
                                                                            i32.const 112
                                                                            i32.add
                                                                            global.set 0
                                                                            local.get 0
                                                                            i32.const 208
                                                                            i32.add
                                                                            local.tee 2
                                                                            local.get 1
                                                                            i32.const 120
                                                                            call 9
                                                                            drop
                                                                            local.get 2
                                                                            call 54
                                                                            local.get 0
                                                                            i64.load offset=464
                                                                            local.get 0
                                                                            i32.const 472
                                                                            i32.add
                                                                            i64.load
                                                                            call 50
                                                                            unreachable
                                                                          end
                                                                          local.get 0
                                                                          local.get 0
                                                                          i32.const 88
                                                                          i32.add
                                                                          i32.store offset=208
                                                                          local.get 0
                                                                          i32.const 216
                                                                          i32.add
                                                                          local.get 2
                                                                          i32.const 48
                                                                          call 9
                                                                          local.set 3
                                                                          block (result i32)  ;; label = @36
                                                                            block  ;; label = @37
                                                                              local.get 0
                                                                              i64.load offset=248
                                                                              local.tee 14
                                                                              local.get 0
                                                                              i32.const 256
                                                                              i32.add
                                                                              i64.load
                                                                              local.tee 13
                                                                              i64.or
                                                                              i64.eqz
                                                                              i32.eqz
                                                                              if  ;; label = @38
                                                                                local.get 0
                                                                                i32.const 392
                                                                                i32.add
                                                                                local.tee 4
                                                                                local.get 3
                                                                                call 46
                                                                                i32.const 0
                                                                                local.set 1
                                                                                local.get 0
                                                                                i64.load offset=392
                                                                                local.tee 15
                                                                                local.get 14
                                                                                i64.lt_u
                                                                                local.tee 5
                                                                                local.get 0
                                                                                i32.const 400
                                                                                i32.add
                                                                                i64.load
                                                                                local.tee 16
                                                                                local.get 13
                                                                                i64.lt_u
                                                                                local.get 13
                                                                                local.get 16
                                                                                i64.eq
                                                                                select
                                                                                br_if 1 (;@37;)
                                                                                i64.const 0
                                                                                local.get 15
                                                                                local.get 0
                                                                                i64.load offset=424
                                                                                local.tee 17
                                                                                i64.sub
                                                                                local.tee 18
                                                                                local.get 15
                                                                                local.get 18
                                                                                i64.lt_u
                                                                                local.get 16
                                                                                local.get 0
                                                                                i32.const 432
                                                                                i32.add
                                                                                i64.load
                                                                                i64.sub
                                                                                local.get 15
                                                                                local.get 17
                                                                                i64.lt_u
                                                                                i64.extend_i32_u
                                                                                i64.sub
                                                                                local.tee 17
                                                                                local.get 16
                                                                                i64.gt_u
                                                                                local.get 16
                                                                                local.get 17
                                                                                i64.eq
                                                                                select
                                                                                local.tee 6
                                                                                select
                                                                                local.get 14
                                                                                i64.lt_u
                                                                                i64.const 0
                                                                                local.get 17
                                                                                local.get 6
                                                                                select
                                                                                local.tee 17
                                                                                local.get 13
                                                                                i64.lt_u
                                                                                local.get 13
                                                                                local.get 17
                                                                                i64.eq
                                                                                select
                                                                                br_if 1 (;@37;)
                                                                                local.get 0
                                                                                local.get 15
                                                                                local.get 14
                                                                                i64.sub
                                                                                i64.store offset=392
                                                                                local.get 0
                                                                                local.get 16
                                                                                local.get 13
                                                                                i64.sub
                                                                                local.get 5
                                                                                i64.extend_i32_u
                                                                                i64.sub
                                                                                i64.store offset=400
                                                                                i32.const 4
                                                                                local.set 1
                                                                                local.get 0
                                                                                i64.load offset=408
                                                                                local.tee 16
                                                                                local.get 14
                                                                                i64.add
                                                                                local.tee 17
                                                                                local.get 16
                                                                                i64.lt_u
                                                                                local.tee 5
                                                                                local.get 5
                                                                                i64.extend_i32_u
                                                                                local.get 0
                                                                                i32.const 416
                                                                                i32.add
                                                                                i64.load
                                                                                local.tee 16
                                                                                local.get 13
                                                                                i64.add
                                                                                i64.add
                                                                                local.tee 15
                                                                                local.get 16
                                                                                i64.lt_u
                                                                                local.get 15
                                                                                local.get 16
                                                                                i64.eq
                                                                                select
                                                                                br_if 1 (;@37;)
                                                                                local.get 0
                                                                                local.get 17
                                                                                i64.store offset=408
                                                                                local.get 0
                                                                                local.get 15
                                                                                i64.store offset=416
                                                                                local.get 3
                                                                                local.get 4
                                                                                call 28
                                                                                local.get 0
                                                                                i32.const 480
                                                                                i32.add
                                                                                local.get 2
                                                                                i32.const 24
                                                                                i32.add
                                                                                i64.load
                                                                                i64.store
                                                                                local.get 0
                                                                                i32.const 472
                                                                                i32.add
                                                                                local.get 2
                                                                                i32.const 16
                                                                                i32.add
                                                                                i64.load
                                                                                i64.store
                                                                                local.get 0
                                                                                i32.const 464
                                                                                i32.add
                                                                                local.get 2
                                                                                i32.const 8
                                                                                i32.add
                                                                                i64.load
                                                                                i64.store
                                                                                local.get 0
                                                                                i64.const 16384
                                                                                i64.store offset=356 align=4
                                                                                local.get 0
                                                                                i32.const 66280
                                                                                i32.store offset=352
                                                                                local.get 0
                                                                                local.get 13
                                                                                i64.store offset=496
                                                                                local.get 0
                                                                                local.get 14
                                                                                i64.store offset=488
                                                                                local.get 0
                                                                                local.get 2
                                                                                i64.load
                                                                                i64.store offset=456
                                                                                local.get 0
                                                                                local.get 0
                                                                                i32.const 456
                                                                                i32.add
                                                                                local.tee 4
                                                                                i32.store offset=376
                                                                                local.get 0
                                                                                i32.const 352
                                                                                i32.add
                                                                                local.tee 1
                                                                                i32.const 2
                                                                                call 34
                                                                                local.get 1
                                                                                i32.const 65676
                                                                                call 30
                                                                                local.get 0
                                                                                i32.const 516
                                                                                i32.add
                                                                                local.tee 2
                                                                                local.get 1
                                                                                local.get 0
                                                                                i32.const 376
                                                                                i32.add
                                                                                call 39
                                                                                local.get 0
                                                                                i32.load offset=520
                                                                                local.tee 5
                                                                                local.get 0
                                                                                i32.load offset=524
                                                                                local.tee 1
                                                                                i32.lt_u
                                                                                br_if 22 (;@16;)
                                                                                local.get 0
                                                                                i32.load offset=516
                                                                                local.set 3
                                                                                local.get 0
                                                                                i32.const 0
                                                                                i32.store offset=524
                                                                                local.get 0
                                                                                local.get 5
                                                                                local.get 1
                                                                                i32.sub
                                                                                i32.store offset=520
                                                                                local.get 0
                                                                                local.get 1
                                                                                local.get 3
                                                                                i32.add
                                                                                i32.store offset=516
                                                                                local.get 4
                                                                                local.get 2
                                                                                call 31
                                                                                local.get 0
                                                                                i64.load offset=488
                                                                                local.get 0
                                                                                i32.const 496
                                                                                i32.add
                                                                                i64.load
                                                                                local.get 2
                                                                                call 27
                                                                                local.get 0
                                                                                i32.load offset=524
                                                                                local.tee 2
                                                                                local.get 0
                                                                                i32.load offset=520
                                                                                i32.gt_u
                                                                                br_if 22 (;@16;)
                                                                                local.get 3
                                                                                local.get 1
                                                                                local.get 0
                                                                                i32.load offset=516
                                                                                local.get 2
                                                                                call 2
                                                                              end
                                                                              local.get 0
                                                                              i32.const 208
                                                                              i32.add
                                                                              local.tee 1
                                                                              local.get 0
                                                                              i32.const 88
                                                                              i32.add
                                                                              i32.const 120
                                                                              call 9
                                                                              drop
                                                                              local.get 1
                                                                              call 54
                                                                              i32.const 7
                                                                              local.set 1
                                                                              i32.const 0
                                                                              br 1 (;@36;)
                                                                            end
                                                                            i32.const 1
                                                                          end
                                                                          local.get 1
                                                                          call 49
                                                                          unreachable
                                                                        end
                                                                        local.get 0
                                                                        local.get 0
                                                                        i32.const 88
                                                                        i32.add
                                                                        i32.store offset=208
                                                                        local.get 0
                                                                        i32.const 216
                                                                        i32.add
                                                                        local.get 2
                                                                        i32.const 48
                                                                        call 9
                                                                        local.set 1
                                                                        i64.const 0
                                                                        local.set 16
                                                                        i64.const 0
                                                                        local.set 14
                                                                        block (result i32)  ;; label = @35
                                                                          block  ;; label = @36
                                                                            local.get 0
                                                                            i64.load offset=248
                                                                            local.tee 18
                                                                            local.get 0
                                                                            i32.const 256
                                                                            i32.add
                                                                            i64.load
                                                                            local.tee 17
                                                                            i64.or
                                                                            i64.eqz
                                                                            i32.eqz
                                                                            if  ;; label = @37
                                                                              local.get 0
                                                                              i32.const 392
                                                                              i32.add
                                                                              local.tee 3
                                                                              local.get 1
                                                                              call 46
                                                                              local.get 0
                                                                              i32.const 416
                                                                              i32.add
                                                                              local.tee 4
                                                                              i64.const 0
                                                                              local.get 4
                                                                              i64.load
                                                                              local.tee 13
                                                                              local.get 17
                                                                              local.get 13
                                                                              local.get 18
                                                                              local.get 0
                                                                              i64.load offset=408
                                                                              local.tee 15
                                                                              i64.lt_u
                                                                              local.get 13
                                                                              local.get 17
                                                                              i64.gt_u
                                                                              local.get 13
                                                                              local.get 17
                                                                              i64.eq
                                                                              select
                                                                              local.tee 4
                                                                              select
                                                                              local.tee 14
                                                                              i64.sub
                                                                              local.get 15
                                                                              local.get 18
                                                                              local.get 15
                                                                              local.get 4
                                                                              select
                                                                              local.tee 16
                                                                              i64.lt_u
                                                                              i64.extend_i32_u
                                                                              i64.sub
                                                                              local.tee 17
                                                                              local.get 15
                                                                              local.get 15
                                                                              local.get 16
                                                                              i64.sub
                                                                              local.tee 18
                                                                              i64.lt_u
                                                                              local.get 13
                                                                              local.get 17
                                                                              i64.lt_u
                                                                              local.get 13
                                                                              local.get 17
                                                                              i64.eq
                                                                              select
                                                                              local.tee 4
                                                                              select
                                                                              i64.store
                                                                              local.get 0
                                                                              i64.const 0
                                                                              local.get 18
                                                                              local.get 4
                                                                              select
                                                                              i64.store offset=408
                                                                              local.get 0
                                                                              i64.load offset=392
                                                                              local.tee 13
                                                                              local.get 16
                                                                              i64.add
                                                                              local.tee 17
                                                                              local.get 13
                                                                              i64.lt_u
                                                                              local.tee 4
                                                                              local.get 4
                                                                              i64.extend_i32_u
                                                                              local.get 0
                                                                              i32.const 400
                                                                              i32.add
                                                                              i64.load
                                                                              local.tee 13
                                                                              local.get 14
                                                                              i64.add
                                                                              i64.add
                                                                              local.tee 15
                                                                              local.get 13
                                                                              i64.lt_u
                                                                              local.get 13
                                                                              local.get 15
                                                                              i64.eq
                                                                              select
                                                                              br_if 1 (;@36;)
                                                                              local.get 0
                                                                              local.get 17
                                                                              i64.store offset=392
                                                                              local.get 0
                                                                              local.get 15
                                                                              i64.store offset=400
                                                                              local.get 1
                                                                              local.get 3
                                                                              call 28
                                                                              local.get 0
                                                                              i32.const 480
                                                                              i32.add
                                                                              local.get 2
                                                                              i32.const 24
                                                                              i32.add
                                                                              i64.load
                                                                              i64.store
                                                                              local.get 0
                                                                              i32.const 472
                                                                              i32.add
                                                                              local.get 2
                                                                              i32.const 16
                                                                              i32.add
                                                                              i64.load
                                                                              i64.store
                                                                              local.get 0
                                                                              i32.const 464
                                                                              i32.add
                                                                              local.get 2
                                                                              i32.const 8
                                                                              i32.add
                                                                              i64.load
                                                                              i64.store
                                                                              local.get 0
                                                                              i64.const 16384
                                                                              i64.store offset=368 align=4
                                                                              local.get 0
                                                                              i32.const 66280
                                                                              i32.store offset=364
                                                                              local.get 0
                                                                              local.get 14
                                                                              i64.store offset=496
                                                                              local.get 0
                                                                              local.get 16
                                                                              i64.store offset=488
                                                                              local.get 0
                                                                              local.get 2
                                                                              i64.load
                                                                              i64.store offset=456
                                                                              local.get 0
                                                                              local.get 0
                                                                              i32.const 456
                                                                              i32.add
                                                                              local.tee 4
                                                                              i32.store offset=376
                                                                              local.get 0
                                                                              i32.const 364
                                                                              i32.add
                                                                              local.tee 1
                                                                              i32.const 2
                                                                              call 34
                                                                              local.get 1
                                                                              i32.const 65709
                                                                              call 30
                                                                              local.get 0
                                                                              i32.const 516
                                                                              i32.add
                                                                              local.tee 2
                                                                              local.get 1
                                                                              local.get 0
                                                                              i32.const 376
                                                                              i32.add
                                                                              call 39
                                                                              local.get 0
                                                                              i32.load offset=520
                                                                              local.tee 5
                                                                              local.get 0
                                                                              i32.load offset=524
                                                                              local.tee 1
                                                                              i32.lt_u
                                                                              br_if 21 (;@16;)
                                                                              local.get 0
                                                                              i32.load offset=516
                                                                              local.set 3
                                                                              local.get 0
                                                                              i32.const 0
                                                                              i32.store offset=524
                                                                              local.get 0
                                                                              local.get 5
                                                                              local.get 1
                                                                              i32.sub
                                                                              i32.store offset=520
                                                                              local.get 0
                                                                              local.get 1
                                                                              local.get 3
                                                                              i32.add
                                                                              i32.store offset=516
                                                                              local.get 4
                                                                              local.get 2
                                                                              call 31
                                                                              local.get 0
                                                                              i64.load offset=488
                                                                              local.get 0
                                                                              i32.const 496
                                                                              i32.add
                                                                              i64.load
                                                                              local.get 2
                                                                              call 27
                                                                              local.get 0
                                                                              i32.load offset=524
                                                                              local.tee 2
                                                                              local.get 0
                                                                              i32.load offset=520
                                                                              i32.gt_u
                                                                              br_if 21 (;@16;)
                                                                              local.get 3
                                                                              local.get 1
                                                                              local.get 0
                                                                              i32.load offset=516
                                                                              local.get 2
                                                                              call 2
                                                                            end
                                                                            local.get 0
                                                                            i32.const 208
                                                                            i32.add
                                                                            local.tee 1
                                                                            local.get 0
                                                                            i32.const 88
                                                                            i32.add
                                                                            i32.const 120
                                                                            call 9
                                                                            drop
                                                                            local.get 1
                                                                            call 54
                                                                            i32.const 0
                                                                            br 1 (;@35;)
                                                                          end
                                                                          i32.const 1
                                                                        end
                                                                        local.set 1
                                                                        local.get 0
                                                                        local.get 16
                                                                        i64.store offset=216
                                                                        local.get 0
                                                                        i32.const 4
                                                                        i32.store8 offset=209
                                                                        local.get 0
                                                                        local.get 1
                                                                        i32.store8 offset=208
                                                                        local.get 0
                                                                        local.get 14
                                                                        i64.store offset=224
                                                                        br 30 (;@4;)
                                                                      end
                                                                      local.get 0
                                                                      local.get 0
                                                                      i32.const 88
                                                                      i32.add
                                                                      i32.store offset=208
                                                                      local.get 0
                                                                      i32.const 216
                                                                      i32.add
                                                                      local.get 2
                                                                      i32.const 56
                                                                      call 9
                                                                      local.set 6
                                                                      local.get 0
                                                                      i32.const 264
                                                                      i32.add
                                                                      i64.load
                                                                      local.set 13
                                                                      local.get 0
                                                                      i64.load offset=256
                                                                      local.set 14
                                                                      local.get 0
                                                                      i64.load offset=248
                                                                      local.set 16
                                                                      local.get 0
                                                                      i32.const 456
                                                                      i32.add
                                                                      local.get 6
                                                                      call 16
                                                                      block (result i32)  ;; label = @34
                                                                        local.get 0
                                                                        i32.load offset=456
                                                                        i32.const -2147483648
                                                                        i32.eq
                                                                        if  ;; label = @35
                                                                          i32.const 0
                                                                          local.set 5
                                                                          local.get 0
                                                                          i32.const 0
                                                                          i32.store offset=384
                                                                          local.get 0
                                                                          i64.const 34359738368
                                                                          i64.store offset=376
                                                                          i32.const 8
                                                                          br 1 (;@34;)
                                                                        end
                                                                        local.get 0
                                                                        i32.const 384
                                                                        i32.add
                                                                        local.get 0
                                                                        i32.const 464
                                                                        i32.add
                                                                        i32.load
                                                                        local.tee 5
                                                                        i32.store
                                                                        local.get 0
                                                                        local.get 0
                                                                        i64.load offset=456 align=4
                                                                        i64.store offset=376
                                                                        local.get 0
                                                                        i32.load offset=380
                                                                      end
                                                                      local.set 4
                                                                      local.get 5
                                                                      i32.const 24
                                                                      i32.mul
                                                                      local.set 3
                                                                      i32.const 0
                                                                      local.set 1
                                                                      loop  ;; label = @34
                                                                        local.get 1
                                                                        local.get 3
                                                                        i32.eq
                                                                        if  ;; label = @35
                                                                          local.get 0
                                                                          i32.load offset=168
                                                                          local.get 5
                                                                          i32.gt_u
                                                                          if  ;; label = @36
                                                                            local.get 0
                                                                            local.get 14
                                                                            i64.store offset=456
                                                                            local.get 0
                                                                            local.get 16
                                                                            i64.store offset=472
                                                                            local.get 0
                                                                            local.get 13
                                                                            i64.store offset=464
                                                                            local.get 0
                                                                            i32.const 376
                                                                            i32.add
                                                                            local.get 0
                                                                            i32.const 456
                                                                            i32.add
                                                                            call 23
                                                                            local.get 0
                                                                            i32.load offset=380
                                                                            local.set 4
                                                                            local.get 0
                                                                            i32.load offset=384
                                                                            local.set 5
                                                                            br 19 (;@17;)
                                                                          end
                                                                          i32.const 1
                                                                          local.set 2
                                                                          i32.const 5
                                                                          br 21 (;@14;)
                                                                        end
                                                                        local.get 1
                                                                        local.get 4
                                                                        i32.add
                                                                        local.set 7
                                                                        local.get 1
                                                                        i32.const 24
                                                                        i32.add
                                                                        local.set 1
                                                                        local.get 7
                                                                        i32.const 16
                                                                        i32.add
                                                                        i64.load align=1
                                                                        local.get 16
                                                                        i64.ne
                                                                        br_if 0 (;@34;)
                                                                      end
                                                                      local.get 1
                                                                      local.get 4
                                                                      i32.add
                                                                      i32.const 24
                                                                      i32.sub
                                                                      local.tee 1
                                                                      local.get 13
                                                                      i64.store offset=8
                                                                      local.get 1
                                                                      local.get 14
                                                                      i64.store
                                                                      br 16 (;@17;)
                                                                    end
                                                                    local.get 0
                                                                    local.get 0
                                                                    i32.const 88
                                                                    i32.add
                                                                    i32.store offset=392
                                                                    local.get 0
                                                                    i32.const 396
                                                                    i32.add
                                                                    local.get 5
                                                                    i32.const 40
                                                                    call 9
                                                                    local.set 8
                                                                    local.get 0
                                                                    i64.load offset=428 align=4
                                                                    local.set 13
                                                                    local.get 0
                                                                    i32.const 208
                                                                    i32.add
                                                                    local.get 8
                                                                    call 16
                                                                    local.get 0
                                                                    i32.load offset=208
                                                                    i32.const -2147483648
                                                                    i32.eq
                                                                    if  ;; label = @33
                                                                      i64.const 0
                                                                      local.set 14
                                                                      i32.const 1
                                                                      local.set 2
                                                                      i32.const 0
                                                                      local.set 7
                                                                      i32.const 8
                                                                      local.set 6
                                                                      i64.const 0
                                                                      local.set 16
                                                                      br 15 (;@18;)
                                                                    end
                                                                    local.get 0
                                                                    i32.load offset=212
                                                                    local.set 6
                                                                    local.get 0
                                                                    i32.load offset=216
                                                                    local.tee 2
                                                                    i32.eqz
                                                                    if  ;; label = @33
                                                                      i64.const 0
                                                                      local.set 14
                                                                      i32.const 1
                                                                      local.set 2
                                                                      i32.const 0
                                                                      local.set 7
                                                                      i64.const 0
                                                                      local.set 16
                                                                      br 15 (;@18;)
                                                                    end
                                                                    local.get 6
                                                                    i32.const 16
                                                                    i32.add
                                                                    local.set 3
                                                                    i32.const 0
                                                                    local.set 1
                                                                    loop  ;; label = @33
                                                                      block  ;; label = @34
                                                                        local.get 1
                                                                        local.get 2
                                                                        i32.eq
                                                                        if  ;; label = @35
                                                                          local.get 2
                                                                          local.set 1
                                                                          i32.const 0
                                                                          local.set 4
                                                                          br 1 (;@34;)
                                                                        end
                                                                        i32.const 1
                                                                        local.set 4
                                                                        local.get 1
                                                                        i32.const 1
                                                                        i32.add
                                                                        local.set 1
                                                                        local.get 3
                                                                        i64.load align=1
                                                                        local.set 14
                                                                        local.get 3
                                                                        i32.const 24
                                                                        i32.add
                                                                        local.set 3
                                                                        local.get 13
                                                                        local.get 14
                                                                        i64.ne
                                                                        br_if 1 (;@33;)
                                                                      end
                                                                    end
                                                                    local.get 6
                                                                    local.get 1
                                                                    i32.const 24
                                                                    i32.mul
                                                                    i32.add
                                                                    local.set 3
                                                                    loop  ;; label = @33
                                                                      block  ;; label = @34
                                                                        local.get 1
                                                                        local.get 2
                                                                        i32.ne
                                                                        if  ;; label = @35
                                                                          local.get 13
                                                                          local.get 3
                                                                          i32.const 16
                                                                          i32.add
                                                                          local.tee 9
                                                                          i64.load align=1
                                                                          i64.eq
                                                                          if  ;; label = @36
                                                                            local.get 4
                                                                            i32.const 1
                                                                            i32.add
                                                                            local.set 4
                                                                            br 2 (;@34;)
                                                                          end
                                                                          local.get 3
                                                                          local.get 4
                                                                          i32.const -24
                                                                          i32.mul
                                                                          i32.add
                                                                          local.tee 7
                                                                          local.get 3
                                                                          i64.load
                                                                          i64.store
                                                                          local.get 7
                                                                          i32.const 16
                                                                          i32.add
                                                                          local.get 9
                                                                          i64.load
                                                                          i64.store
                                                                          local.get 7
                                                                          i32.const 8
                                                                          i32.add
                                                                          local.get 3
                                                                          i32.const 8
                                                                          i32.add
                                                                          i64.load
                                                                          i64.store
                                                                          br 1 (;@34;)
                                                                        end
                                                                        local.get 2
                                                                        local.get 4
                                                                        i32.sub
                                                                        local.set 7
                                                                        local.get 2
                                                                        local.get 4
                                                                        i32.eq
                                                                        if  ;; label = @35
                                                                          i64.const 0
                                                                          local.set 14
                                                                          i32.const 1
                                                                          local.set 2
                                                                          i64.const 0
                                                                          local.set 16
                                                                          br 17 (;@18;)
                                                                        end
                                                                        local.get 6
                                                                        i32.const 8
                                                                        i32.add
                                                                        i64.load
                                                                        local.set 16
                                                                        local.get 6
                                                                        i64.load
                                                                        local.set 14
                                                                        i32.const 0
                                                                        local.set 2
                                                                        local.get 7
                                                                        i32.const 1
                                                                        i32.eq
                                                                        if  ;; label = @35
                                                                          i32.const 1
                                                                          local.set 7
                                                                          br 17 (;@18;)
                                                                        end
                                                                        local.get 6
                                                                        i32.const 24
                                                                        i32.add
                                                                        local.set 1
                                                                        local.get 7
                                                                        i32.const 24
                                                                        i32.mul
                                                                        i32.const 24
                                                                        i32.sub
                                                                        i32.const 24
                                                                        i32.div_u
                                                                        local.set 3
                                                                        loop  ;; label = @35
                                                                          local.get 16
                                                                          local.get 1
                                                                          i32.const 8
                                                                          i32.add
                                                                          i64.load
                                                                          local.tee 13
                                                                          local.get 14
                                                                          local.get 1
                                                                          i64.load
                                                                          local.tee 15
                                                                          i64.gt_u
                                                                          local.get 13
                                                                          local.get 16
                                                                          i64.lt_u
                                                                          local.get 13
                                                                          local.get 16
                                                                          i64.eq
                                                                          select
                                                                          local.tee 4
                                                                          select
                                                                          local.set 16
                                                                          local.get 14
                                                                          local.get 15
                                                                          local.get 4
                                                                          select
                                                                          local.set 14
                                                                          local.get 1
                                                                          i32.const 24
                                                                          i32.add
                                                                          local.set 1
                                                                          local.get 3
                                                                          i32.const 1
                                                                          i32.sub
                                                                          local.tee 3
                                                                          br_if 0 (;@35;)
                                                                        end
                                                                        br 16 (;@18;)
                                                                      end
                                                                      local.get 3
                                                                      i32.const 24
                                                                      i32.add
                                                                      local.set 3
                                                                      local.get 1
                                                                      i32.const 1
                                                                      i32.add
                                                                      local.set 1
                                                                      br 0 (;@33;)
                                                                    end
                                                                    unreachable
                                                                  end
                                                                  local.get 0
                                                                  i64.const 0
                                                                  local.get 18
                                                                  i64.const 0
                                                                  local.get 15
                                                                  local.get 14
                                                                  i64.sub
                                                                  local.get 16
                                                                  local.get 17
                                                                  i64.gt_u
                                                                  i64.extend_i32_u
                                                                  i64.sub
                                                                  local.tee 13
                                                                  local.get 17
                                                                  local.get 17
                                                                  local.get 16
                                                                  i64.sub
                                                                  local.tee 20
                                                                  i64.lt_u
                                                                  local.get 13
                                                                  local.get 15
                                                                  i64.gt_u
                                                                  local.get 13
                                                                  local.get 15
                                                                  i64.eq
                                                                  select
                                                                  local.tee 1
                                                                  select
                                                                  local.tee 17
                                                                  i64.sub
                                                                  local.get 19
                                                                  i64.const 0
                                                                  local.get 20
                                                                  local.get 1
                                                                  select
                                                                  local.tee 13
                                                                  i64.lt_u
                                                                  i64.extend_i32_u
                                                                  i64.sub
                                                                  local.tee 15
                                                                  local.get 19
                                                                  local.get 19
                                                                  local.get 13
                                                                  i64.sub
                                                                  local.tee 20
                                                                  i64.lt_u
                                                                  local.get 15
                                                                  local.get 18
                                                                  i64.gt_u
                                                                  local.get 15
                                                                  local.get 18
                                                                  i64.eq
                                                                  select
                                                                  local.tee 1
                                                                  select
                                                                  i64.store offset=96
                                                                  local.get 0
                                                                  i64.const 0
                                                                  local.get 20
                                                                  local.get 1
                                                                  select
                                                                  i64.store offset=88
                                                                  i64.const 0
                                                                  local.get 0
                                                                  i32.const 112
                                                                  i32.add
                                                                  i64.load
                                                                  local.tee 15
                                                                  local.get 17
                                                                  i64.sub
                                                                  local.get 0
                                                                  i64.load offset=104
                                                                  local.tee 17
                                                                  local.get 13
                                                                  i64.lt_u
                                                                  i64.extend_i32_u
                                                                  i64.sub
                                                                  local.tee 18
                                                                  local.get 17
                                                                  local.get 13
                                                                  i64.sub
                                                                  local.tee 13
                                                                  local.get 17
                                                                  i64.gt_u
                                                                  local.get 15
                                                                  local.get 18
                                                                  i64.lt_u
                                                                  local.get 15
                                                                  local.get 18
                                                                  i64.eq
                                                                  select
                                                                  local.tee 1
                                                                  select
                                                                  local.set 15
                                                                  i64.const 0
                                                                  local.get 13
                                                                  local.get 1
                                                                  select
                                                                  local.set 17
                                                                  br 22 (;@9;)
                                                                end
                                                                local.get 0
                                                                i32.const 208
                                                                i32.add
                                                                local.tee 1
                                                                i32.const 1
                                                                i32.or
                                                                local.get 4
                                                                i32.const 33
                                                                call 9
                                                                drop
                                                                local.get 0
                                                                i32.const 0
                                                                i32.store8 offset=208
                                                                global.get 0
                                                                i32.const 16
                                                                i32.sub
                                                                local.tee 2
                                                                global.set 0
                                                                local.get 2
                                                                i32.const 16384
                                                                i32.store offset=8
                                                                local.get 2
                                                                i32.const 66280
                                                                i32.store offset=4
                                                                block  ;; label = @31
                                                                  local.get 1
                                                                  i32.load8_u
                                                                  i32.const 1
                                                                  i32.eq
                                                                  if  ;; label = @32
                                                                    i32.const 66280
                                                                    i32.const 257
                                                                    i32.store16 align=1
                                                                    i32.const 2
                                                                    local.set 1
                                                                    br 1 (;@31;)
                                                                  end
                                                                  i32.const 66280
                                                                  i32.const 0
                                                                  i32.store8
                                                                  local.get 2
                                                                  i32.const 1
                                                                  i32.store offset=12
                                                                  local.get 1
                                                                  i32.const 1
                                                                  i32.add
                                                                  local.get 2
                                                                  i32.const 4
                                                                  i32.add
                                                                  call 41
                                                                  local.get 2
                                                                  i32.load offset=12
                                                                  local.tee 1
                                                                  i32.const 16385
                                                                  i32.lt_u
                                                                  br_if 0 (;@31;)
                                                                  unreachable
                                                                end
                                                                br 29 (;@1;)
                                                              end
                                                              local.get 0
                                                              i32.const 216
                                                              i32.add
                                                              local.get 2
                                                              i32.const 56
                                                              call 9
                                                              local.set 2
                                                              local.get 0
                                                              local.get 0
                                                              i32.const 88
                                                              i32.add
                                                              local.tee 1
                                                              i32.store offset=208
                                                              local.get 0
                                                              i32.const 256
                                                              i32.add
                                                              i64.load
                                                              local.set 13
                                                              local.get 0
                                                              i64.load offset=248
                                                              local.set 14
                                                              local.get 0
                                                              i32.load8_u offset=264
                                                              local.set 3
                                                              local.get 0
                                                              i32.const 456
                                                              i32.add
                                                              local.tee 4
                                                              call 42
                                                              local.get 1
                                                              local.get 4
                                                              local.get 2
                                                              local.get 14
                                                              local.get 13
                                                              local.get 3
                                                              call 62
                                                              i32.const 255
                                                              i32.and
                                                              local.tee 2
                                                              i32.const 7
                                                              i32.eq
                                                              if (result i32)  ;; label = @30
                                                                local.get 0
                                                                i32.const 208
                                                                i32.add
                                                                local.tee 0
                                                                local.get 1
                                                                i32.const 120
                                                                call 9
                                                                drop
                                                                local.get 0
                                                                call 54
                                                                i32.const 0
                                                              else
                                                                i32.const 1
                                                              end
                                                              local.get 2
                                                              call 49
                                                              unreachable
                                                            end
                                                            local.get 0
                                                            i32.const 216
                                                            i32.add
                                                            local.get 2
                                                            i32.const 48
                                                            call 9
                                                            local.set 2
                                                            local.get 0
                                                            local.get 0
                                                            i32.const 88
                                                            i32.add
                                                            local.tee 1
                                                            i32.store offset=208
                                                            local.get 0
                                                            i32.const 256
                                                            i32.add
                                                            i64.load
                                                            local.set 13
                                                            local.get 0
                                                            i64.load offset=248
                                                            local.set 14
                                                            local.get 0
                                                            i32.const 456
                                                            i32.add
                                                            local.tee 3
                                                            call 42
                                                            local.get 1
                                                            local.get 3
                                                            local.get 2
                                                            local.get 14
                                                            local.get 13
                                                            i32.const 1
                                                            call 62
                                                            i32.const 255
                                                            i32.and
                                                            local.tee 2
                                                            i32.const 7
                                                            i32.eq
                                                            if (result i32)  ;; label = @29
                                                              local.get 0
                                                              i32.const 208
                                                              i32.add
                                                              local.tee 0
                                                              local.get 1
                                                              i32.const 120
                                                              call 9
                                                              drop
                                                              local.get 0
                                                              call 54
                                                              i32.const 0
                                                            else
                                                              i32.const 1
                                                            end
                                                            local.get 2
                                                            call 49
                                                            unreachable
                                                          end
                                                          local.get 0
                                                          i32.const 216
                                                          i32.add
                                                          local.get 2
                                                          i32.const 48
                                                          call 9
                                                          local.set 2
                                                          local.get 0
                                                          local.get 0
                                                          i32.const 88
                                                          i32.add
                                                          local.tee 1
                                                          i32.store offset=208
                                                          local.get 0
                                                          i32.const 256
                                                          i32.add
                                                          i64.load
                                                          local.set 13
                                                          local.get 0
                                                          i64.load offset=248
                                                          local.set 14
                                                          local.get 0
                                                          i32.const 456
                                                          i32.add
                                                          local.tee 3
                                                          call 42
                                                          local.get 1
                                                          local.get 3
                                                          local.get 2
                                                          local.get 14
                                                          local.get 13
                                                          i32.const 0
                                                          call 62
                                                          i32.const 255
                                                          i32.and
                                                          local.tee 2
                                                          i32.const 7
                                                          i32.eq
                                                          if (result i32)  ;; label = @28
                                                            local.get 0
                                                            i32.const 208
                                                            i32.add
                                                            local.tee 0
                                                            local.get 1
                                                            i32.const 120
                                                            call 9
                                                            drop
                                                            local.get 0
                                                            call 54
                                                            i32.const 0
                                                          else
                                                            i32.const 1
                                                          end
                                                          local.get 2
                                                          call 49
                                                          unreachable
                                                        end
                                                        local.get 0
                                                        i32.const 216
                                                        i32.add
                                                        local.get 2
                                                        i32.const 48
                                                        call 9
                                                        local.set 2
                                                        local.get 0
                                                        local.get 0
                                                        i32.const 88
                                                        i32.add
                                                        local.tee 1
                                                        i32.store offset=208
                                                        local.get 1
                                                        local.get 2
                                                        local.get 0
                                                        i64.load offset=248
                                                        local.get 0
                                                        i32.const 256
                                                        i32.add
                                                        i64.load
                                                        call 60
                                                        i32.const 255
                                                        i32.and
                                                        local.tee 2
                                                        i32.const 7
                                                        i32.eq
                                                        if (result i32)  ;; label = @27
                                                          local.get 0
                                                          i32.const 208
                                                          i32.add
                                                          local.tee 0
                                                          local.get 1
                                                          i32.const 120
                                                          call 9
                                                          drop
                                                          local.get 0
                                                          call 54
                                                          i32.const 0
                                                        else
                                                          i32.const 1
                                                        end
                                                        local.get 2
                                                        call 49
                                                        unreachable
                                                      end
                                                      local.get 0
                                                      i64.const -1
                                                      local.get 14
                                                      local.get 17
                                                      i64.add
                                                      local.tee 14
                                                      local.get 17
                                                      i64.lt_u
                                                      local.tee 1
                                                      i64.extend_i32_u
                                                      local.get 13
                                                      local.get 16
                                                      i64.add
                                                      i64.add
                                                      local.tee 13
                                                      local.get 1
                                                      local.get 13
                                                      local.get 16
                                                      i64.lt_u
                                                      local.get 13
                                                      local.get 16
                                                      i64.eq
                                                      select
                                                      local.tee 1
                                                      select
                                                      local.tee 13
                                                      local.get 15
                                                      i64.const -1
                                                      local.get 14
                                                      local.get 1
                                                      select
                                                      local.tee 14
                                                      local.get 18
                                                      i64.lt_u
                                                      local.get 13
                                                      local.get 15
                                                      i64.lt_u
                                                      local.get 13
                                                      local.get 15
                                                      i64.eq
                                                      select
                                                      local.tee 1
                                                      select
                                                      i64.store offset=112
                                                      local.get 0
                                                      local.get 14
                                                      local.get 18
                                                      local.get 1
                                                      select
                                                      i64.store offset=104
                                                      local.get 0
                                                      i32.const 208
                                                      i32.add
                                                      local.tee 1
                                                      local.get 0
                                                      i32.const 88
                                                      i32.add
                                                      i32.const 120
                                                      call 9
                                                      drop
                                                      local.get 1
                                                      call 54
                                                      i32.const 0
                                                      local.set 2
                                                      i32.const 7
                                                    end
                                                    local.set 1
                                                    br 21 (;@3;)
                                                  end
                                                  local.get 0
                                                  i64.const 0
                                                  local.get 16
                                                  local.get 13
                                                  i64.sub
                                                  local.get 14
                                                  local.get 17
                                                  i64.gt_u
                                                  i64.extend_i32_u
                                                  i64.sub
                                                  local.tee 13
                                                  local.get 17
                                                  local.get 14
                                                  i64.sub
                                                  local.tee 14
                                                  local.get 17
                                                  i64.gt_u
                                                  local.get 13
                                                  local.get 16
                                                  i64.gt_u
                                                  local.get 13
                                                  local.get 16
                                                  i64.eq
                                                  select
                                                  local.tee 1
                                                  select
                                                  i64.store offset=112
                                                  local.get 0
                                                  i64.const 0
                                                  local.get 14
                                                  local.get 1
                                                  select
                                                  i64.store offset=104
                                                  local.get 0
                                                  i32.const 208
                                                  i32.add
                                                  local.tee 1
                                                  local.get 0
                                                  i32.const 88
                                                  i32.add
                                                  i32.const 120
                                                  call 9
                                                  drop
                                                  local.get 1
                                                  call 54
                                                  i32.const 0
                                                  local.set 2
                                                  i32.const 7
                                                end
                                                local.set 1
                                                br 19 (;@3;)
                                              end
                                              local.get 0
                                              local.get 14
                                              i64.store offset=88
                                              local.get 0
                                              local.get 13
                                              i64.store offset=96
                                              local.get 0
                                              local.get 13
                                              local.get 16
                                              local.get 13
                                              local.get 14
                                              local.get 17
                                              i64.gt_u
                                              local.get 13
                                              local.get 16
                                              i64.gt_u
                                              local.get 13
                                              local.get 16
                                              i64.eq
                                              select
                                              local.tee 1
                                              select
                                              local.get 15
                                              local.get 18
                                              i64.or
                                              i64.eqz
                                              local.tee 2
                                              select
                                              i64.store offset=112
                                              local.get 0
                                              local.get 14
                                              local.get 17
                                              local.get 14
                                              local.get 1
                                              select
                                              local.get 2
                                              select
                                              i64.store offset=104
                                              local.get 0
                                              i32.const 208
                                              i32.add
                                              local.tee 1
                                              local.get 0
                                              i32.const 88
                                              i32.add
                                              i32.const 120
                                              call 9
                                              drop
                                              local.get 1
                                              call 54
                                              i32.const 0
                                              local.set 2
                                              i32.const 7
                                            end
                                            local.set 1
                                            br 17 (;@3;)
                                          end
                                          local.get 20
                                          local.get 19
                                          call 50
                                          unreachable
                                        end
                                        local.get 0
                                        i32.const 208
                                        i32.add
                                        local.tee 2
                                        call 42
                                        block (result i32)  ;; label = @19
                                          local.get 2
                                          local.get 1
                                          call 44
                                          if  ;; label = @20
                                            i32.const 1
                                            local.set 2
                                            i32.const 6
                                            br 1 (;@19;)
                                          end
                                          local.get 4
                                          local.get 5
                                          i32.const 33
                                          call 9
                                          drop
                                          local.get 0
                                          i32.const 208
                                          i32.add
                                          local.tee 1
                                          local.get 0
                                          i32.const 88
                                          i32.add
                                          i32.const 120
                                          call 9
                                          drop
                                          local.get 1
                                          call 54
                                          i32.const 0
                                          local.set 2
                                          i32.const 7
                                        end
                                        local.set 1
                                        br 15 (;@3;)
                                      end
                                      local.get 0
                                      i32.const 456
                                      i32.add
                                      local.get 8
                                      call 46
                                      local.get 0
                                      i32.const 496
                                      i32.add
                                      local.tee 1
                                      i64.load
                                      local.set 13
                                      local.get 1
                                      local.get 16
                                      i64.store
                                      local.get 0
                                      i64.load offset=488
                                      local.set 15
                                      local.get 0
                                      local.get 14
                                      i64.store offset=488
                                      block  ;; label = @18
                                        local.get 2
                                        i32.eqz
                                        if  ;; label = @19
                                          local.get 8
                                          local.get 6
                                          local.get 7
                                          call 24
                                          br 1 (;@18;)
                                        end
                                        local.get 0
                                        i32.const 220
                                        i32.add
                                        local.get 5
                                        i32.const 8
                                        i32.add
                                        i64.load align=1
                                        i64.store align=4
                                        local.get 0
                                        i32.const 228
                                        i32.add
                                        local.get 5
                                        i32.const 16
                                        i32.add
                                        i64.load align=1
                                        i64.store align=4
                                        local.get 0
                                        i32.const 236
                                        i32.add
                                        local.get 5
                                        i32.const 24
                                        i32.add
                                        i64.load align=1
                                        i64.store align=4
                                        local.get 0
                                        i32.const 65536
                                        i32.store offset=208
                                        local.get 0
                                        local.get 5
                                        i64.load align=1
                                        i64.store offset=212 align=4
                                        local.get 0
                                        i64.const 16384
                                        i64.store offset=520 align=4
                                        local.get 0
                                        i32.const 66280
                                        i32.store offset=516
                                        local.get 0
                                        i32.const 208
                                        i32.add
                                        local.get 0
                                        i32.const 516
                                        i32.add
                                        call 17
                                        local.get 0
                                        i32.load offset=524
                                        local.tee 1
                                        local.get 0
                                        i32.load offset=520
                                        i32.gt_u
                                        br_if 2 (;@16;)
                                        local.get 0
                                        i32.load offset=516
                                        local.get 1
                                        call 4
                                        drop
                                      end
                                      local.get 8
                                      local.get 0
                                      i32.const 456
                                      i32.add
                                      call 28
                                      local.get 14
                                      local.get 15
                                      i64.ge_u
                                      local.get 13
                                      local.get 16
                                      i64.le_u
                                      local.get 13
                                      local.get 16
                                      i64.eq
                                      select
                                      i32.eqz
                                      if  ;; label = @18
                                        local.get 0
                                        i32.const 232
                                        i32.add
                                        local.get 5
                                        i32.const 24
                                        i32.add
                                        i64.load align=1
                                        i64.store
                                        local.get 0
                                        i32.const 224
                                        i32.add
                                        local.get 5
                                        i32.const 16
                                        i32.add
                                        i64.load align=1
                                        i64.store
                                        local.get 0
                                        i32.const 216
                                        i32.add
                                        local.get 5
                                        i32.const 8
                                        i32.add
                                        i64.load align=1
                                        i64.store
                                        local.get 0
                                        i64.const 16384
                                        i64.store offset=508 align=4
                                        local.get 0
                                        i32.const 66280
                                        i32.store offset=504
                                        local.get 0
                                        local.get 5
                                        i64.load align=1
                                        i64.store offset=208
                                        local.get 0
                                        i64.const 0
                                        local.get 13
                                        local.get 16
                                        i64.sub
                                        local.get 14
                                        local.get 15
                                        i64.gt_u
                                        i64.extend_i32_u
                                        i64.sub
                                        local.tee 16
                                        local.get 15
                                        local.get 14
                                        i64.sub
                                        local.tee 14
                                        local.get 15
                                        i64.gt_u
                                        local.get 13
                                        local.get 16
                                        i64.lt_u
                                        local.get 13
                                        local.get 16
                                        i64.eq
                                        select
                                        local.tee 1
                                        select
                                        i64.store offset=248
                                        local.get 0
                                        i64.const 0
                                        local.get 14
                                        local.get 1
                                        select
                                        i64.store offset=240
                                        local.get 0
                                        local.get 0
                                        i32.const 208
                                        i32.add
                                        local.tee 4
                                        i32.store offset=376
                                        local.get 0
                                        i32.const 504
                                        i32.add
                                        local.tee 1
                                        i32.const 2
                                        call 34
                                        local.get 1
                                        i32.const 65775
                                        call 30
                                        local.get 0
                                        i32.const 516
                                        i32.add
                                        local.tee 2
                                        local.get 1
                                        local.get 0
                                        i32.const 376
                                        i32.add
                                        call 39
                                        local.get 0
                                        i32.load offset=520
                                        local.tee 5
                                        local.get 0
                                        i32.load offset=524
                                        local.tee 1
                                        i32.lt_u
                                        br_if 2 (;@16;)
                                        local.get 0
                                        i32.load offset=516
                                        local.set 3
                                        local.get 0
                                        i32.const 0
                                        i32.store offset=524
                                        local.get 0
                                        local.get 5
                                        local.get 1
                                        i32.sub
                                        i32.store offset=520
                                        local.get 0
                                        local.get 1
                                        local.get 3
                                        i32.add
                                        i32.store offset=516
                                        local.get 4
                                        local.get 2
                                        call 31
                                        local.get 0
                                        i64.load offset=240
                                        local.get 0
                                        i32.const 248
                                        i32.add
                                        i64.load
                                        local.get 2
                                        call 27
                                        local.get 0
                                        i32.load offset=524
                                        local.tee 2
                                        local.get 0
                                        i32.load offset=520
                                        i32.gt_u
                                        br_if 2 (;@16;)
                                        local.get 3
                                        local.get 1
                                        local.get 0
                                        i32.load offset=516
                                        local.get 2
                                        call 2
                                      end
                                      local.get 0
                                      i32.const 208
                                      i32.add
                                      local.tee 1
                                      local.get 0
                                      i32.const 88
                                      i32.add
                                      i32.const 120
                                      call 9
                                      drop
                                      local.get 1
                                      call 54
                                      i32.const 0
                                      i32.const 7
                                      call 49
                                      unreachable
                                    end
                                    i64.const 0
                                    local.set 14
                                    i64.const 0
                                    local.set 16
                                    block  ;; label = @17
                                      local.get 5
                                      i32.eqz
                                      br_if 0 (;@17;)
                                      local.get 4
                                      i32.const 8
                                      i32.add
                                      i64.load
                                      local.set 16
                                      local.get 4
                                      i64.load
                                      local.set 14
                                      local.get 5
                                      i32.const 1
                                      i32.eq
                                      br_if 0 (;@17;)
                                      local.get 4
                                      i32.const 24
                                      i32.add
                                      local.set 1
                                      local.get 5
                                      i32.const 24
                                      i32.mul
                                      i32.const 24
                                      i32.sub
                                      i32.const 24
                                      i32.div_u
                                      local.set 3
                                      loop  ;; label = @18
                                        local.get 16
                                        local.get 1
                                        i32.const 8
                                        i32.add
                                        i64.load
                                        local.tee 13
                                        local.get 14
                                        local.get 1
                                        i64.load
                                        local.tee 15
                                        i64.gt_u
                                        local.get 13
                                        local.get 16
                                        i64.lt_u
                                        local.get 13
                                        local.get 16
                                        i64.eq
                                        select
                                        local.tee 7
                                        select
                                        local.set 16
                                        local.get 14
                                        local.get 15
                                        local.get 7
                                        select
                                        local.set 14
                                        local.get 1
                                        i32.const 24
                                        i32.add
                                        local.set 1
                                        local.get 3
                                        i32.const 1
                                        i32.sub
                                        local.tee 3
                                        br_if 0 (;@18;)
                                      end
                                    end
                                    local.get 0
                                    i32.const 392
                                    i32.add
                                    local.tee 1
                                    local.get 6
                                    call 46
                                    local.get 0
                                    i32.const 432
                                    i32.add
                                    local.tee 3
                                    i64.load
                                    local.set 13
                                    local.get 0
                                    i64.load offset=424
                                    local.set 15
                                    local.get 0
                                    local.get 14
                                    i64.store offset=424
                                    local.get 3
                                    local.get 16
                                    i64.store
                                    local.get 6
                                    local.get 4
                                    local.get 5
                                    call 24
                                    local.get 6
                                    local.get 1
                                    call 28
                                    local.get 14
                                    local.get 15
                                    i64.gt_u
                                    local.get 13
                                    local.get 16
                                    i64.lt_u
                                    local.get 13
                                    local.get 16
                                    i64.eq
                                    select
                                    i32.eqz
                                    br_if 1 (;@15;)
                                    local.get 0
                                    i32.const 480
                                    i32.add
                                    local.get 2
                                    i32.const 24
                                    i32.add
                                    i64.load
                                    i64.store
                                    local.get 0
                                    i32.const 472
                                    i32.add
                                    local.get 2
                                    i32.const 16
                                    i32.add
                                    i64.load
                                    i64.store
                                    local.get 0
                                    i32.const 464
                                    i32.add
                                    local.get 2
                                    i32.const 8
                                    i32.add
                                    i64.load
                                    i64.store
                                    local.get 0
                                    i64.const 16384
                                    i64.store offset=444 align=4
                                    local.get 0
                                    i32.const 66280
                                    i32.store offset=440
                                    local.get 0
                                    local.get 2
                                    i64.load
                                    i64.store offset=456
                                    local.get 0
                                    i64.const 0
                                    local.get 16
                                    local.get 13
                                    i64.sub
                                    local.get 14
                                    local.get 15
                                    i64.lt_u
                                    i64.extend_i32_u
                                    i64.sub
                                    local.tee 13
                                    local.get 14
                                    local.get 14
                                    local.get 15
                                    i64.sub
                                    local.tee 15
                                    i64.lt_u
                                    local.get 13
                                    local.get 16
                                    i64.gt_u
                                    local.get 13
                                    local.get 16
                                    i64.eq
                                    select
                                    local.tee 1
                                    select
                                    i64.store offset=496
                                    local.get 0
                                    i64.const 0
                                    local.get 15
                                    local.get 1
                                    select
                                    i64.store offset=488
                                    local.get 0
                                    local.get 0
                                    i32.const 456
                                    i32.add
                                    local.tee 4
                                    i32.store offset=452
                                    local.get 0
                                    i32.const 440
                                    i32.add
                                    local.tee 1
                                    i32.const 2
                                    call 34
                                    local.get 1
                                    i32.const 65742
                                    call 30
                                    local.get 0
                                    i32.const 516
                                    i32.add
                                    local.tee 2
                                    local.get 1
                                    local.get 0
                                    i32.const 452
                                    i32.add
                                    call 39
                                    local.get 0
                                    i32.load offset=520
                                    local.tee 5
                                    local.get 0
                                    i32.load offset=524
                                    local.tee 1
                                    i32.lt_u
                                    br_if 0 (;@16;)
                                    local.get 0
                                    i32.load offset=516
                                    local.set 3
                                    local.get 0
                                    i32.const 0
                                    i32.store offset=524
                                    local.get 0
                                    local.get 5
                                    local.get 1
                                    i32.sub
                                    i32.store offset=520
                                    local.get 0
                                    local.get 1
                                    local.get 3
                                    i32.add
                                    i32.store offset=516
                                    local.get 4
                                    local.get 2
                                    call 31
                                    local.get 0
                                    i64.load offset=488
                                    local.get 0
                                    i32.const 496
                                    i32.add
                                    i64.load
                                    local.get 2
                                    call 27
                                    local.get 0
                                    i32.load offset=524
                                    local.tee 2
                                    local.get 0
                                    i32.load offset=520
                                    i32.gt_u
                                    br_if 0 (;@16;)
                                    local.get 3
                                    local.get 1
                                    local.get 0
                                    i32.load offset=516
                                    local.get 2
                                    call 2
                                    br 1 (;@15;)
                                  end
                                  unreachable
                                end
                                local.get 0
                                i32.const 208
                                i32.add
                                local.tee 1
                                local.get 0
                                i32.const 88
                                i32.add
                                i32.const 120
                                call 9
                                drop
                                local.get 1
                                call 54
                                i32.const 0
                                local.set 2
                                i32.const 7
                              end
                              local.set 1
                              br 10 (;@3;)
                            end
                            local.get 0
                            i32.const 208
                            i32.add
                            local.tee 1
                            local.get 0
                            i32.const 88
                            i32.add
                            i32.const 120
                            call 9
                            drop
                            local.get 1
                            call 54
                            i32.const 0
                            br 2 (;@10;)
                          end
                          i32.const 4
                          local.set 3
                        end
                        i32.const 1
                      end
                      local.set 1
                      local.get 0
                      local.get 14
                      i64.store offset=216
                      local.get 0
                      local.get 3
                      i32.store8 offset=209
                      local.get 0
                      local.get 1
                      i32.store8 offset=208
                      local.get 0
                      local.get 16
                      i64.store offset=224
                      br 5 (;@4;)
                    end
                    local.get 0
                    local.get 17
                    i64.store offset=104
                    local.get 0
                    local.get 15
                    i64.store offset=112
                    local.get 2
                    local.get 0
                    i32.const 456
                    i32.add
                    call 28
                    i64.const 0
                  end
                  local.set 15
                  local.get 0
                  i32.const 208
                  i32.add
                  local.tee 1
                  local.get 0
                  i32.const 88
                  i32.add
                  i32.const 120
                  call 9
                  drop
                  local.get 1
                  call 54
                  local.get 14
                  local.set 13
                  i32.const 0
                end
                local.set 1
                local.get 0
                local.get 16
                i64.store offset=216
                local.get 0
                local.get 15
                i64.store offset=208
                local.get 0
                local.get 13
                i64.store offset=224
                i32.const 0
                local.set 3
                global.get 0
                i32.const 16
                i32.sub
                local.tee 2
                global.set 0
                local.get 2
                i32.const 16384
                i32.store offset=8
                local.get 2
                i32.const 66280
                i32.store offset=4
                block  ;; label = @7
                  block (result i32)  ;; label = @8
                    block  ;; label = @9
                      local.get 0
                      i32.const 208
                      i32.add
                      local.tee 0
                      i64.load
                      local.tee 13
                      i64.const 3
                      i64.ne
                      if  ;; label = @10
                        i32.const 66280
                        i32.const 0
                        i32.store8
                        block  ;; label = @11
                          local.get 13
                          i64.const 2
                          i64.ne
                          if  ;; label = @12
                            i32.const 66281
                            i32.const 0
                            i32.store8
                            local.get 13
                            i32.wrap_i64
                            i32.const 1
                            i32.and
                            br_if 1 (;@11;)
                            br 3 (;@9;)
                          end
                          i32.const 66281
                          i32.const 1
                          i32.store8
                          local.get 0
                          i32.load8_u offset=8
                          local.set 3
                          br 2 (;@9;)
                        end
                        i32.const 66282
                        i32.const 1
                        i32.store8
                        local.get 2
                        i32.const 3
                        i32.store offset=12
                        local.get 0
                        i64.load offset=8
                        local.get 0
                        i32.const 16
                        i32.add
                        i64.load
                        local.get 2
                        i32.const 4
                        i32.add
                        call 27
                        local.get 2
                        i32.load offset=12
                        local.tee 2
                        i32.const 16385
                        i32.lt_u
                        br_if 3 (;@7;)
                        unreachable
                      end
                      i32.const 1
                      local.set 3
                      i32.const 66280
                      i32.const 1
                      i32.store8
                      i32.const 2
                      local.set 2
                      i32.const 66281
                      br 1 (;@8;)
                    end
                    i32.const 3
                    local.set 2
                    i32.const 66282
                  end
                  local.get 3
                  i32.store8
                end
                local.get 1
                local.get 2
                call 55
                unreachable
              end
              global.get 0
              i32.const 96
              i32.sub
              local.tee 1
              global.set 0
              local.get 1
              i32.const 24
              i32.add
              local.get 5
              i32.const 8
              i32.add
              i64.load align=1
              i64.store align=4
              local.get 1
              i32.const 32
              i32.add
              local.get 5
              i32.const 16
              i32.add
              i64.load align=1
              i64.store align=4
              local.get 1
              i32.const 40
              i32.add
              local.get 5
              i32.const 24
              i32.add
              i64.load align=1
              i64.store align=4
              local.get 1
              local.get 0
              i32.const 88
              i32.add
              i32.store offset=12
              local.get 1
              local.get 5
              i64.load align=1
              i64.store offset=16 align=4
              local.get 1
              i32.const 48
              i32.add
              local.get 1
              i32.const 16
              i32.add
              call 46
              local.get 0
              i32.const 216
              i32.add
              local.tee 2
              local.get 1
              i32.const 56
              i32.add
              i64.load
              i64.store offset=8
              local.get 2
              local.get 1
              i64.load offset=48
              i64.store
              local.get 1
              i32.const 96
              i32.add
              global.set 0
            end
            local.get 0
            i64.load offset=216
            local.get 0
            i32.const 224
            i32.add
            i64.load
            call 50
            unreachable
          end
          local.get 1
          local.get 0
          i32.const 208
          i32.add
          call 52
          unreachable
        end
        local.get 2
        local.get 1
        call 49
        unreachable
      end
      local.get 0
      i32.const 208
      i32.add
      local.tee 1
      local.get 0
      i32.const 88
      i32.add
      i32.const 120
      call 9
      drop
      local.get 1
      call 54
      i32.const 0
      local.get 0
      i32.const 456
      i32.add
      call 52
      unreachable
    end
    i32.const 0
    local.get 1
    call 55
    unreachable)
  ;; Function 64: Deploy dispatcher (constructor)
  ;; Decodes constructor selector
  ;; Parameters: () -> never
  (func $dispatch_deploy (;64;) (type 5)
    (local i32 i32 i32 i32 i32 i32 i64 i64)
    global.get 0
    i32.const 304
    i32.sub
    local.tee 0
    global.set 0
    block  ;; label = @1
      block  ;; label = @2
        call 43
        i32.const 255
        i32.and
        i32.const 5
        i32.ne
        br_if 0 (;@2;)
        local.get 0
        i32.const 16384
        i32.store offset=184
        i32.const 66280
        local.get 0
        i32.const 184
        i32.add
        local.tee 5
        call 1
        local.get 0
        i32.load offset=184
        local.tee 1
        i32.const 16385
        i32.ge_u
        br_if 0 (;@2;)
        local.get 0
        local.get 1
        i32.store offset=60
        local.get 0
        i32.const 66280
        i32.store offset=56
        block  ;; label = @3
          local.get 0
          i32.const 56
          i32.add
          local.get 5
          call 48
          br_if 0 (;@3;)
          local.get 0
          i32.load offset=184
          local.tee 1
          i32.const 24
          i32.shr_u
          local.set 2
          local.get 1
          i32.const 16
          i32.shr_u
          local.set 3
          local.get 1
          i32.const 8
          i32.shr_u
          local.set 4
          local.get 1
          i32.const 255
          i32.and
          local.tee 1
          i32.const 25
          i32.ne
          if  ;; label = @4
            local.get 1
            i32.const 155
            i32.ne
            if  ;; label = @5
              local.get 1
              i32.const 237
              i32.ne
              local.get 2
              i32.const 27
              i32.ne
              i32.or
              local.get 4
              i32.const 255
              i32.and
              i32.const 75
              i32.ne
              local.get 3
              i32.const 255
              i32.and
              i32.const 157
              i32.ne
              i32.or
              i32.or
              br_if 2 (;@3;)
              local.get 5
              i64.const 1
              i64.const 0
              i32.const 10
              call 65
              local.get 5
              call 54
              call 51
              unreachable
            end
            local.get 2
            i32.const 94
            i32.ne
            local.get 4
            i32.const 255
            i32.and
            i32.const 174
            i32.ne
            i32.or
            local.get 3
            i32.const 255
            i32.and
            i32.const 157
            i32.ne
            i32.or
            br_if 1 (;@3;)
            local.get 0
            i32.const 184
            i32.add
            local.tee 1
            local.get 0
            i32.const 56
            i32.add
            local.tee 2
            call 22
            local.get 0
            i32.load offset=184
            br_if 1 (;@3;)
            local.get 0
            i32.const 200
            i32.add
            i64.load
            local.set 6
            local.get 0
            i64.load offset=192
            local.set 7
            local.get 0
            i32.const 8
            i32.add
            local.get 2
            call 19
            local.get 0
            i32.load offset=8
            br_if 1 (;@3;)
            local.get 1
            local.get 7
            local.get 6
            local.get 0
            i32.load offset=12
            call 65
            local.get 1
            call 54
            call 51
            unreachable
          end
          local.get 2
          i32.const 169
          i32.ne
          local.get 4
          i32.const 255
          i32.and
          i32.const 65
          i32.ne
          i32.or
          local.get 3
          i32.const 255
          i32.and
          i32.const 244
          i32.ne
          i32.or
          br_if 0 (;@3;)
          local.get 0
          i32.const -64
          i32.sub
          local.get 0
          i32.const 56
          i32.add
          local.tee 2
          call 22
          local.get 0
          i32.load offset=64
          br_if 0 (;@3;)
          local.get 0
          i32.const 80
          i32.add
          i64.load
          local.set 6
          local.get 0
          i64.load offset=72
          local.set 7
          local.get 0
          i32.const 16
          i32.add
          local.get 2
          call 19
          local.get 0
          i32.load offset=16
          br_if 0 (;@3;)
          local.get 0
          i32.load offset=20
          local.set 1
          local.get 0
          i32.const 184
          i32.add
          local.get 2
          call 35
          local.get 0
          i32.load8_u offset=184
          i32.const 1
          i32.ne
          br_if 2 (;@1;)
        end
        call 53
      end
      unreachable
    end
    local.get 0
    i32.const 48
    i32.add
    local.tee 2
    local.get 0
    i32.const 209
    i32.add
    i64.load align=1
    i64.store
    local.get 0
    i32.const 40
    i32.add
    local.tee 3
    local.get 0
    i32.const 201
    i32.add
    i64.load align=1
    i64.store
    local.get 0
    i32.const 32
    i32.add
    local.tee 4
    local.get 0
    i32.const 193
    i32.add
    i64.load align=1
    i64.store
    local.get 0
    local.get 0
    i64.load offset=185 align=1
    i64.store offset=24
    local.get 0
    i32.const 112
    i32.add
    call 42
    local.get 0
    i32.const 88
    i32.add
    i64.const 0
    i64.store
    local.get 0
    i32.const 80
    i32.add
    i64.const 0
    i64.store
    local.get 0
    i32.const 72
    i32.add
    i64.const 0
    i64.store
    local.get 0
    i32.const 157
    i32.add
    local.get 4
    i64.load
    i64.store align=1
    local.get 0
    i32.const 165
    i32.add
    local.get 3
    i64.load
    i64.store align=1
    local.get 0
    i32.const 173
    i32.add
    local.get 2
    i64.load
    i64.store align=1
    local.get 0
    local.get 6
    i64.store offset=104
    local.get 0
    local.get 7
    i64.store offset=96
    local.get 0
    i64.const 0
    i64.store offset=64
    local.get 0
    i32.const 1
    i32.store8 offset=148
    local.get 0
    local.get 1
    i32.store offset=144
    local.get 0
    local.get 0
    i64.load offset=24
    i64.store offset=149 align=1
    local.get 0
    i32.const 184
    i32.add
    local.tee 1
    local.get 0
    i32.const -64
    i32.sub
    i32.const 120
    call 9
    drop
    local.get 1
    call 54
    call 51
    unreachable)

  ;; Function 65: Initialize contract state
  ;; Sets up initial contract storage
  ;; Parameters: (state_ptr, ed_low, ed_high, max_locks) -> void
  (func $initialize_contract_state (;65;) (type 16) (param i32 i64 i64 i32)
    ;; Get caller as owner
    local.get 0
    i32.const 48
    i32.add
    call 42
    
    ;; Store parameters
    local.get 0
    local.get 2
    i64.store offset=40
    local.get 0
    local.get 1
    i64.store offset=32
    local.get 0
    i32.const 24
    i32.add
    i64.const 0
    i64.store
    local.get 0
    i32.const 16
    i32.add
    i64.const 0
    i64.store
    local.get 0
    i32.const 8
    i32.add
    i64.const 0
    i64.store
    local.get 0
    i64.const 0
    i64.store
    local.get 0
    i32.const 0
    i32.store8 offset=84
    local.get 0
    local.get 3
    i32.store offset=80)

  ;; Function 66: Check deposit feasibility
  ;; Validates deposit operation
  ;; Parameters: (config_ptr, account_ptr, new_balance_ptr) -> result
  (func $check_deposit_feasibility (;66;) (type 2) (param i32 i32 i32) (result i32)
    (local i32 i32 i32 i32 i64 i64 i64 i64)
    global.get 0
    i32.const 80
    i32.sub
    local.tee 3
    global.set 0
    
    ;; Load new balance
    local.get 2
    i32.const 8
    i32.add
    i64.load
    local.set 10
    local.get 2
    i64.load
    local.set 7
    block  ;; label = @1
      block (result i32)  ;; label = @2
        block  ;; label = @3
          local.get 0
          i32.load8_u offset=84
          i32.const 1
          i32.eq
          if  ;; label = @4
            local.get 3
            local.get 0
            i32.const 85
            i32.add
            local.tee 0
            call 46
            local.get 7
            local.get 3
            i64.load
            local.tee 7
            i64.add
            local.tee 8
            local.get 7
            i64.lt_u
            local.tee 1
            local.get 1
            i64.extend_i32_u
            local.get 3
            i32.const 8
            i32.add
            i64.load
            local.tee 7
            local.get 10
            i64.add
            i64.add
            local.tee 10
            local.get 7
            i64.lt_u
            local.get 7
            local.get 10
            i64.eq
            select
            br_if 1 (;@3;)
            local.get 3
            local.get 8
            i64.store
            local.get 3
            local.get 10
            i64.store offset=8
            local.get 0
            local.get 3
            call 28
            local.get 2
            i64.const 0
            i64.store offset=8
            local.get 2
            i64.const 0
            i64.store
            i32.const 7
            br 2 (;@2;)
          end
          local.get 3
          i32.const 24
          i32.add
          local.get 1
          i32.const 24
          i32.add
          i64.load align=1
          i64.store
          local.get 3
          i32.const 16
          i32.add
          local.get 1
          i32.const 16
          i32.add
          i64.load align=1
          i64.store
          local.get 3
          i32.const 8
          i32.add
          local.get 1
          i32.const 8
          i32.add
          i64.load align=1
          i64.store
          local.get 3
          local.get 7
          i64.store offset=32
          local.get 3
          i64.const 16384
          i64.store offset=56 align=4
          local.get 3
          i32.const 66280
          i32.store offset=52
          local.get 3
          local.get 10
          i64.store offset=40
          local.get 3
          local.get 1
          i64.load align=1
          i64.store
          local.get 3
          local.get 3
          i32.store offset=64
          local.get 3
          i32.const 52
          i32.add
          local.tee 1
          i32.const 2
          call 34
          local.get 1
          i32.const 65643
          call 30
          local.get 3
          i32.const 68
          i32.add
          local.tee 5
          local.get 1
          local.get 3
          i32.const -64
          i32.sub
          call 39
          local.get 3
          i32.load offset=72
          local.tee 4
          local.get 3
          i32.load offset=76
          local.tee 1
          i32.lt_u
          br_if 2 (;@1;)
          local.get 3
          i32.load offset=68
          local.set 6
          local.get 3
          i32.const 0
          i32.store offset=76
          local.get 3
          local.get 4
          local.get 1
          i32.sub
          i32.store offset=72
          local.get 3
          local.get 1
          local.get 6
          i32.add
          i32.store offset=68
          local.get 3
          local.get 5
          call 31
          local.get 3
          i64.load offset=32
          local.get 3
          i32.const 40
          i32.add
          i64.load
          local.get 5
          call 27
          local.get 3
          i32.load offset=76
          local.tee 4
          local.get 3
          i32.load offset=72
          i32.gt_u
          br_if 2 (;@1;)
          local.get 6
          local.get 1
          local.get 3
          i32.load offset=68
          local.get 4
          call 2
          local.get 2
          i64.const 0
          i64.store offset=8
          local.get 2
          i64.const 0
          i64.store
          local.get 0
          i64.const 0
          local.get 0
          i64.load
          local.tee 8
          local.get 7
          i64.sub
          local.tee 9
          local.get 8
          local.get 9
          i64.lt_u
          local.get 0
          i32.const 8
          i32.add
          local.tee 1
          i64.load
          local.tee 9
          local.get 10
          i64.sub
          local.get 7
          local.get 8
          i64.gt_u
          i64.extend_i32_u
          i64.sub
          local.tee 8
          local.get 9
          i64.gt_u
          local.get 8
          local.get 9
          i64.eq
          select
          local.tee 2
          select
          i64.store
          local.get 1
          i64.const 0
          local.get 8
          local.get 2
          select
          i64.store
          local.get 0
          i64.const 0
          local.get 0
          i64.load offset=16
          local.tee 8
          local.get 7
          i64.sub
          local.tee 9
          local.get 8
          local.get 9
          i64.lt_u
          local.get 0
          i32.const 24
          i32.add
          local.tee 0
          i64.load
          local.tee 9
          local.get 10
          i64.sub
          local.get 7
          local.get 8
          i64.gt_u
          i64.extend_i32_u
          i64.sub
          local.tee 7
          local.get 9
          i64.gt_u
          local.get 7
          local.get 9
          i64.eq
          select
          local.tee 1
          select
          i64.store offset=16
          local.get 0
          i64.const 0
          local.get 7
          local.get 1
          select
          i64.store
          i32.const 7
          br 1 (;@2;)
        end
        i32.const 4
      end
      local.set 0
      local.get 3
      i32.const 80
      i32.add
      global.set 0
      local.get 0
      return
    end
    unreachable)

  ;; Function 67: Allocate memory with alignment
  ;; Low-level allocation wrapper
  ;; Parameters: (result_ptr, size) -> void
  (func $alloc_aligned (;67;) (type 0) (param i32 i32)
    (local i32)
    local.get 1
    if (result i32)  ;; label = @1
      i32.const 82664
      i32.load8_u
      drop
      local.get 1
      call 68
    else
      i32.const 8
    end
    local.set 2
    
    local.get 0
    local.get 1
    i32.store offset=4
    local.get 0
    local.get 2
    i32.store)

  ;; Function 68: Core allocation function
  ;; Bump allocator implementation
  ;; Parameters: (size) -> ptr
  (func $alloc (;68;) (type 6) (param i32) (result i32)
    (local i32 i32)
    
    block (result i32)  ;; label = @1
      i32.const 66268
      i32.load8_u
      if  ;; label = @2
        i32.const 66272
        i32.load
        br 1 (;@1;)
      end
      
      memory.size
      local.set 1
      i32.const 66272
      i32.const 82672
      i32.store
      i32.const 66268
      i32.const 1
      i32.store8
      i32.const 66276
      local.get 1
      i32.const 16
      i32.shl
      i32.store
      i32.const 82672
    end
    local.set 1
    
    block  ;; label = @1
      block (result i32)  ;; label = @2
        i32.const 0
        local.get 1
        i32.const 7
        i32.add
        i32.const -8
        i32.and
        local.tee 1
        local.get 0
        i32.add
        local.tee 2
        local.get 1
        i32.lt_u
        br_if 0 (;@2;)
        drop
        
        i32.const 66276
        i32.load
        local.get 2
        i32.lt_u
        if  ;; label = @3
          local.get 0
          i32.const 65535
          i32.add
          local.tee 2
          i32.const 16
          i32.shr_u
          memory.grow
          local.tee 1
          i32.const -1
          i32.eq
          br_if 2 (;@1;)
          
          local.get 1
          i32.const 16
          i32.shl
          local.tee 1
          local.get 2
          i32.const -65536
          i32.and
          i32.add
          local.tee 2
          local.get 1
          i32.lt_u
          br_if 2 (;@1;)
          
          i32.const 66276
          local.get 2
          i32.store
          
          i32.const 0
          local.get 0
          local.get 1
          i32.add
          local.tee 2
          local.get 1
          i32.lt_u
          br_if 1 (;@2;)
          drop
        end
        
        i32.const 66272
        local.get 2
        i32.store
        local.get 1
      end
      return
    end
    i32.const 0)

  ;; ============================================================================
  ;; EXPORTS AND MODULE METADATA
  ;; ============================================================================
  
  (global (;0;) (mut i32) (i32.const 65536))
  (global (;1;) i32 (i32.const 82672))
  (global (;2;) i32 (i32.const 82665))
  
  (export "call" (func 63))
  (export "deploy" (func 64))
  
  ;; ============================================================================
  ;; STATIC DATA SECTION
  ;; ============================================================================
  
  (data (;0;) (i32.const 65536)
    ;; Mapping prefix and XOR key
    "\ff\df\a2?\b4z}\fd"
    
    ;; Source file path references
    "\fc\01\01\00i\00\00\00"    ;; buffer.rs path
    "\99\00\00\00.\00\00\00"    ;; Line 153, column 46
    
    "\fc\01\01\00i\00\00\00"
    "\94\00\00\000\00\00\00"    ;; Line 148, column 48
    
    ;; Cryptographic constants (SHA-256 initial values, etc.)
    "\01\b5\b6\1a>j!\a1k\e4\f0D\b5\17\c2\8a\c6\92I/s\c5\bf\d3\f6\01x\ad\98\c7g\f4\cb"
    "\01\d8>B\e4<_\bc\d3\1c\e6\a9[\13(F\12\acM\a9\1b)\17\d0\d5\bd\ad\be\ff\b6@\db\bc"
    "\01\b7~\08\8e\0f,r\a8\81+&\02M\5c\a3\014\9b3p\ce>\d5o\c3\eas3\b0\9c\0bR"
    "\01 \85\7f\1e\c4\a4\e9\8e\83\bb\ec\a3\e9\98\22\88WS1\07t\11\fe\d94\ea\0bCn\e3\deU"
    "\01\89\f3\e8\aa\18\97\bb\8d8\e2o=S\bdJ]\ae\06\bb\14\c9Lz@}\b5\1c\98\da{j\11"
    "\01\c5w\1e\b4zW\e5OXR\fb\b9\12\bc6hS\d8N9\ec\b1\95W\a0\b9\f0\ac\f4\18\f9\7f"
    "\01\d6\d3\1a\dew%%\df\03\80\07.\13\9d\03U>\d7m\c5[\18\f9\c8\0e\a6x\a2\8d\a28#"
    "\01\e6\c5\e2\a1\0d\92\bc\c1\87O\98\182\ab}K\e9\7f\09\b2\f8\e8\88ih~?}\c0\84\de\9b"
    "\01\8b\cf\93\86\9b\87\f1\f2s\91\ca\d4\09\a3\cd\d3\87\93\0c\ba\d3\07\f9\e1j\8df\00Ozb1"
    "\01A(&C\d6\e8\01\b1\b3\ed\0f1\f9\94b\c2\9b\e6\94\1c\fb\cdV;\d9UGG\f6%\a9+"
    
    ;; Selector dispatch table
    "\10\01\02\03\04\05\06\07\08\09\0a\0b\0c\0d\0e"
    
    ;; Error messages and paths
    "/usr/local/cargo/registry/src/index.crates.io-6f17d22bba15001f/ink_env-5.1.1/src/engine/on_chain/buffer.rs\00"
    "\81\01\01\00j\00\00\00]\00\00\00\0e\00\00\00"
    
    "/usr/local/cargo/registry/src/index.crates.io-6f17d22bba15001f/ink_env-5.1.1/src/engine/on_chain/impls.rs"
    "/usr/local/cargo/registry/src/index.crates.io-6f17d22bba15001f/parity-scale-codec-3.7.5/src/codec.rs\00"
    
    "\00\00e\02\01\00d\00\00\00"
    "{\00\00\00\0e"
  )
)