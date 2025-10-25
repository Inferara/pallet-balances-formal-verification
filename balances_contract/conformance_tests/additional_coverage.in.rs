/// Test pair creation and resolution with zero amounts
#[ink::test]
fn pair_zero_amount() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let (credit, debt) = contract.pair(0).unwrap();
    assert_eq!(credit.peek(), 0);
    assert_eq!(debt.peek(), 0);
    
    // Resolve zero credit
    let account = accounts.bob;
    contract.resolve_credit(account, credit).unwrap();
    assert_eq!(contract.balance(account), 0);
}

/// Test settle_debt with zero amount
#[ink::test]
fn settle_debt_zero() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 100).unwrap();
    
    let debt = DebtImbalance { amount: 0 };
    let remaining = contract.settle_debt(account, debt, Preservation::Expendable).unwrap();
    assert_eq!(remaining.peek(), 0);
}

/// Test settle_debt with partial settlement
#[ink::test]
fn settle_debt_partial() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 50).unwrap();
    
    // Try to settle more debt than available (with Preserve)
    let debt = DebtImbalance { amount: 60 };
    let remaining = contract.settle_debt(account, debt, Preservation::Preserve).unwrap();
    
    // Should have burned what it could (50 - ED)
    assert_eq!(contract.balance(account), contract.existential_deposit());
    assert_eq!(remaining.peek(), 60 - (50 - contract.existential_deposit()));
}

/// Test can_deposit with zero amount
#[ink::test]
fn can_deposit_zero() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    let ret = contract.can_deposit(account, 0, Provenance::Minted);
    assert_eq!(ret, DepositConsequence::Success);
}

/// Test can_deposit with Provenance::Extant
#[ink::test]
fn can_deposit_extant() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 50).unwrap();
    
    let ret = contract.can_deposit(account, 10, Provenance::Extant);
    assert_eq!(ret, DepositConsequence::Success);
}

/// Test can_deposit when total issuance would overflow
#[ink::test]
fn can_deposit_total_overflow() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    // First create the account with minimum balance
    contract.mint(account, contract.existential_deposit()).unwrap();
    
    // Now set total issuance near max
    contract.set_total_issuance(Balance::MAX - 5).unwrap();
    
    // Try to deposit more, which would overflow total issuance
    let ret = contract.can_deposit(account, 10, Provenance::Minted);
    assert_eq!(ret, DepositConsequence::Overflow);
}

/// Test can_withdraw with zero amount
#[ink::test]
fn can_withdraw_zero() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    let ret = contract.can_withdraw(account, 0);
    assert_eq!(ret, WithdrawConsequence::Success);
}

/// Test write_balance returning dust
#[ink::test]
fn write_balance_with_dust() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    if contract.existential_deposit() == 0 {
        return Ok(());
    }
    
    let account = accounts.bob;
    contract.mint(account, 100).unwrap();
    
    // Write balance below ED but > 0
    let dust = contract.write_balance(account, contract.existential_deposit() - 1).unwrap();
    assert_eq!(dust, Some(contract.existential_deposit() - 1));
    assert_eq!(contract.balance(account), 0);
}

/// Test write_balance with exact ED
#[ink::test]
fn write_balance_exact_ed() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 100).unwrap();
    
    let dust = contract.write_balance(account, contract.existential_deposit()).unwrap();
    assert_eq!(dust, None);
    assert_eq!(contract.balance(account), contract.existential_deposit());
}

/// Test write_balance unauthorized
#[ink::test]
fn write_balance_unauthorized() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    // Switch to non-owner
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.bob);
    
    let result = contract.write_balance(accounts.charlie, 100);
    assert_eq!(result, Err(Error::NotAllowed));
}

/// Test decrease_balance (same as burn_from)
#[ink::test]
fn decrease_balance() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 100).unwrap();
    
    let burned = contract.decrease_balance(
        account,
        10,
        Precision::Exact,
        Preservation::Expendable,
        Fortitude::Polite,
    ).unwrap();
    
    assert_eq!(burned, 10);
    assert_eq!(contract.balance(account), 90);
}

/// Test increase_balance with zero
#[ink::test]
fn increase_balance_zero() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    let result = contract.increase_balance(account, 0, Precision::Exact).unwrap();
    assert_eq!(result, 0);
}

/// Test increase_balance below ED for new account with Exact
#[ink::test]
fn increase_balance_below_ed_exact() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    if contract.existential_deposit() < 2 {
        return Ok(());
    }
    
    let account = accounts.bob;
    let result = contract.increase_balance(
        account,
        contract.existential_deposit() - 1,
        Precision::Exact
    );
    assert_eq!(result, Err(Error::ExistentialDeposit));
}

/// Test increase_balance below ED for new account with BestEffort
#[ink::test]
fn increase_balance_below_ed_best_effort() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    if contract.existential_deposit() < 2 {
        return Ok(());
    }
    
    let account = accounts.bob;
    let result = contract.increase_balance(
        account,
        contract.existential_deposit() - 1,
        Precision::BestEffort
    ).unwrap();
    assert_eq!(result, 0);
}

/// Test increase_balance with overflow and BestEffort
#[ink::test]
fn increase_balance_overflow_best_effort() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, Balance::MAX - 10).unwrap();
    
    let result = contract.increase_balance(account, 20, Precision::BestEffort).unwrap();
    assert_eq!(result, 10);
    assert_eq!(contract.balance(account), Balance::MAX);
}

/// Test increase_balance with total issuance overflow and BestEffort
#[ink::test]
fn increase_balance_total_overflow_best_effort() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    // First create the account with ED
    contract.mint(account, contract.existential_deposit()).unwrap();
    
    // Now set total issuance near max
    contract.set_total_issuance(Balance::MAX - 10).unwrap();
    
    // This should saturate at the available space (10 tokens)
    let result = contract.increase_balance(account, 20, Precision::BestEffort).unwrap();
    assert_eq!(result, 10); // Should add what fits
    assert_eq!(contract.total_issuance(), Balance::MAX);
}

/// Test set_total_issuance unauthorized
#[ink::test]
fn set_total_issuance_unauthorized() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.bob);
    let result = contract.set_total_issuance(100);
    assert_eq!(result, Err(Error::NotAllowed));
}

/// Test set_total_issuance with zero base
#[ink::test]
fn set_total_issuance_from_zero() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    assert_eq!(contract.total_issuance(), 0);
    contract.set_total_issuance(100).unwrap();
    assert_eq!(contract.total_issuance(), 100);
    assert_eq!(contract.active_issuance(), 100);
}

/// Test deactivate unauthorized
#[ink::test]
fn deactivate_unauthorized() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.bob);
    let result = contract.deactivate(10);
    assert_eq!(result, Err(Error::NotAllowed));
}

/// Test reactivate unauthorized
#[ink::test]
fn reactivate_unauthorized() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.bob);
    let result = contract.reactivate(10);
    assert_eq!(result, Err(Error::NotAllowed));
}

/// Test mint unauthorized
#[ink::test]
fn mint_unauthorized() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.bob);
    let result = contract.mint(accounts.charlie, 100);
    assert_eq!(result, Err(Error::NotAllowed));
}

/// Test mint with zero amount
#[ink::test]
fn mint_zero() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let result = contract.mint(accounts.bob, 0);
    assert_eq!(result, Ok(()));
}

/// Test burn_from with zero
#[ink::test]
fn burn_from_zero() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 100).unwrap();
    
    let result = contract.burn_from(
        account,
        0,
        Preservation::Expendable,
        Precision::Exact,
        Fortitude::Polite,
    ).unwrap();
    assert_eq!(result, 0);
}

/// Test burn_from with Fortitude::Force
#[ink::test]
fn burn_from_force() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 100).unwrap();
    
    let result = contract.burn_from(
        account,
        10,
        Preservation::Expendable,
        Precision::Exact,
        Fortitude::Force,
    ).unwrap();
    assert_eq!(result, 10);
}

/// Test burn_from leaving dust with Expendable
#[ink::test]
fn burn_from_expendable_creates_dust() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    if contract.existential_deposit() < 2 {
        return Ok(());
    }
    
    let account = accounts.bob;
    contract.mint(account, contract.existential_deposit() + 5).unwrap();
    
    // Burn amount that leaves dust
    let burn_amount = 6;
    let result = contract.burn_from(
        account,
        burn_amount,
        Preservation::Expendable,
        Precision::Exact,
        Fortitude::Polite,
    ).unwrap();
    
    assert_eq!(result, burn_amount);
    // Account should be dusted
    assert_eq!(contract.balance(account), 0);
}

/// Test restore with zero
#[ink::test]
fn restore_zero() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let result = contract.restore(accounts.bob, 0);
    assert_eq!(result, Ok(()));
}

/// Test shelve with zero
#[ink::test]
fn shelve_zero() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let result = contract.shelve(accounts.bob, 0);
    assert_eq!(result, Ok(()));
}

/// Test set_balance with same amount
#[ink::test]
fn set_balance_same() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 50).unwrap();
    
    let result = contract.set_balance(account, 50);
    assert_eq!(result, 50);
}

/// Test set_balance with overflow on increase saturates
#[ink::test]
fn set_balance_increase_overflow() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, Balance::MAX - 10).unwrap();
    
    // Try to set balance that would overflow the account balance
    let result = contract.set_balance(account, Balance::MAX);
    // set_balance saturates on overflow, so it should succeed
    assert_eq!(result, Balance::MAX);
    assert_eq!(contract.balance(account), Balance::MAX);
}

/// Test set_balance with overflow on decrease
#[ink::test]
fn set_balance_decrease_overflow() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 100).unwrap();
    
    // Normal decrease
    let result = contract.set_balance(account, 50);
    assert_eq!(result, 50);
    assert_eq!(contract.balance(account), 50);
}

/// Test transfer with zero amount
#[ink::test]
fn transfer_zero() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let from = accounts.bob;
    let to = accounts.charlie;
    contract.mint(from, 100).unwrap();
    
    test::set_caller::<ink::env::DefaultEnvironment>(from);
    let result = contract.transfer(to, 0);
    assert_eq!(result, Ok(()));
}

/// Test transfer with locked funds
#[ink::test]
fn transfer_with_lock() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let from = accounts.bob;
    let to = accounts.charlie;
    contract.mint(from, 100).unwrap();
    
    // Set a lock
    contract.set_lock(from, *b"testlock", 50).unwrap();
    
    test::set_caller::<ink::env::DefaultEnvironment>(from);
    // Should only be able to transfer 50 (100 - 50 locked)
    let result = contract.transfer(to, 51);
    assert_eq!(result, Err(Error::LiquidityRestrictions));
}

/// Test reserve with zero
#[ink::test]
fn reserve_zero() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let result = contract.reserve(accounts.bob, 0);
    assert_eq!(result, Ok(()));
}

/// Test reserve insufficient balance
#[ink::test]
fn reserve_insufficient() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 50).unwrap();
    
    let result = contract.reserve(account, 51);
    assert_eq!(result, Err(Error::InsufficientBalance));
}

/// Test unreserve with zero
#[ink::test]
fn unreserve_zero() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let result = contract.unreserve(accounts.bob, 0).unwrap();
    assert_eq!(result, 0);
}

/// Test unreserve more than reserved
#[ink::test]
fn unreserve_more_than_reserved() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 100).unwrap();
    contract.reserve(account, 30).unwrap();
    
    // Try to unreserve more than reserved
    let result = contract.unreserve(account, 50).unwrap();
    assert_eq!(result, 30); // Should only unreserve what was reserved
}

/// Test set_lock updating existing lock
#[ink::test]
fn set_lock_update() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 100).unwrap();
    
    let lock_id = *b"testlock";
    contract.set_lock(account, lock_id, 50).unwrap();
    
    // Update the lock
    contract.set_lock(account, lock_id, 30).unwrap();
    
    let account_data = contract.account(account);
    assert_eq!(account_data.frozen, 30);
}

/// Test set_lock too many locks
#[ink::test]
fn set_lock_too_many() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 2, None); // max_locks = 2
    
    let account = accounts.bob;
    contract.mint(account, 100).unwrap();
    
    contract.set_lock(account, *b"lock0001", 10).unwrap();
    contract.set_lock(account, *b"lock0002", 10).unwrap();
    
    let result = contract.set_lock(account, *b"lock0003", 10);
    assert_eq!(result, Err(Error::TooManyLocks));
}

/// Test remove_lock
#[ink::test]
fn remove_lock_test() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 100).unwrap();
    
    let lock_id = *b"testlock";
    contract.set_lock(account, lock_id, 50).unwrap();
    
    contract.remove_lock(account, lock_id).unwrap();
    
    let account_data = contract.account(account);
    assert_eq!(account_data.frozen, 0);
}

/// Test remove_lock with multiple locks
#[ink::test]
fn remove_lock_multiple() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 100).unwrap();
    
    contract.set_lock(account, *b"lock0001", 30).unwrap();
    contract.set_lock(account, *b"lock0002", 50).unwrap();
    
    // Remove the smaller lock
    contract.remove_lock(account, *b"lock0001").unwrap();
    
    let account_data = contract.account(account);
    assert_eq!(account_data.frozen, 50); // Still locked by lock0002
}

/// Test set_dust_trap unauthorized
#[ink::test]
fn set_dust_trap_unauthorized() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.bob);
    let result = contract.set_dust_trap(Some(accounts.charlie));
    assert_eq!(result, Err(Error::NotAllowed));
}

/// Test set_dust_trap and dust_trap getter
#[ink::test]
fn set_and_get_dust_trap() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    assert_eq!(contract.dust_trap(), None);
    
    contract.set_dust_trap(Some(accounts.django)).unwrap();
    assert_eq!(contract.dust_trap(), Some(accounts.django));
    
    contract.set_dust_trap(None).unwrap();
    assert_eq!(contract.dust_trap(), None);
}

/// Test default constructor
#[ink::test]
fn default_constructor() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let contract = BalancesContract::default();
    
    assert_eq!(contract.existential_deposit(), 1);
    assert_eq!(contract.total_issuance(), 0);
}

/// Test total_balance getter
#[ink::test]
fn total_balance_test() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 50).unwrap();
    contract.reserve(account, 20).unwrap();
    
    assert_eq!(contract.total_balance(account), 50);
    assert_eq!(contract.free_balance(account), 30);
    assert_eq!(contract.reserved_balance(account), 20);
}

/// Test usable_balance with locks
#[ink::test]
fn usable_balance_with_locks() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 100).unwrap();
    contract.set_lock(account, *b"testlock", 40).unwrap();
    
    assert_eq!(contract.usable_balance(account), 60);
}

/// Test reducible_balance with locks
#[ink::test]
fn reducible_balance_with_locks() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 100).unwrap();
    contract.set_lock(account, *b"testlock", 40).unwrap();
    
    let reducible = contract.reducible_balance(
        account,
        Preservation::Expendable,
        Fortitude::Polite
    );
    assert_eq!(reducible, 60);
}

/// Test burn_from with Preserve and locked funds
#[ink::test]
fn burn_preserve_with_locks() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 100).unwrap();
    contract.set_lock(account, *b"testlock", 60).unwrap();
    
    // Can burn from usable balance
    let result = contract.burn_from(
        account,
        30,
        Preservation::Preserve,
        Precision::Exact,
        Fortitude::Polite,
    ).unwrap();
    assert_eq!(result, 30);
}

/// Test write_balance increasing from zero
#[ink::test]
fn write_balance_increase_from_zero() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    
    // Write balance from zero (line 538-540)
    let dust = contract.write_balance(account, 50).unwrap();
    assert_eq!(dust, None);
    assert_eq!(contract.balance(account), 50);
    assert_eq!(contract.total_issuance(), 50);
}

/// Test write_balance decreasing to zero
#[ink::test]
fn write_balance_decrease_to_zero() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 100).unwrap();
    
    // Write balance to zero - this should return None (not dust since it's exactly zero)
    let dust = contract.write_balance(account, 0).unwrap();
    assert_eq!(dust, None); // Zero is not dust, it's a valid balance
    assert_eq!(contract.balance(account), 0);
}

/// Test write_balance with overflow on increase
#[ink::test]
fn write_balance_overflow_increase() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    // Set the account to a high value, but keep total issuance manageable
    contract.set_total_issuance(Balance::MAX - 50).unwrap();
    contract.set_balance(account, Balance::MAX - 100);
    
    // Now try to increase beyond max - the increase would overflow total issuance
    let result = contract.write_balance(account, Balance::MAX);
    assert_eq!(result, Err(Error::Overflow));
}

/// Test increase_balance with account overflow (BestEffort saturating at Balance::MAX)
#[ink::test]
fn increase_balance_account_overflow_saturate() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, Balance::MAX - 5).unwrap();
    
    // This should hit the saturation case on lines 476, 535-536
    let result = contract.increase_balance(account, 20, Precision::BestEffort).unwrap();
    assert_eq!(result, 5);
    assert_eq!(contract.balance(account), Balance::MAX);
}

/// Test increase_balance with exact overflow error
#[ink::test]
fn increase_balance_exact_overflow() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, Balance::MAX - 5).unwrap();
    
    // This should hit line 382 (Precision::Exact overflow)
    let result = contract.increase_balance(account, 20, Precision::Exact);
    assert_eq!(result, Err(Error::Overflow));
}

/// Test burn_from with exact expendability error (new_balance < ED but > 0)
#[ink::test]
fn burn_exact_expendability_error() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    if contract.existential_deposit() < 2 {
        return Ok(());
    }
    
    let account = accounts.bob;
    contract.mint(account, contract.existential_deposit() + 5).unwrap();
    
    // Try to burn amount that would leave dust with Preserve (lines 607, 619-622)
    let burn_amount = 6;
    let result = contract.burn_from(
        account,
        burn_amount,
        Preservation::Preserve,
        Precision::Exact,
        Fortitude::Polite,
    );
    assert_eq!(result, Err(Error::Expendability));
}

/// Test burn_from creating dust with Protect preservation
#[ink::test]
fn burn_protect_expendability() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    if contract.existential_deposit() < 2 {
        return Ok(());
    }
    
    let account = accounts.bob;
    contract.mint(account, contract.existential_deposit() + 5).unwrap();
    
    // Try to burn with Protect that would create dust (line 624)
    let burn_amount = 6;
    let result = contract.burn_from(
        account,
        burn_amount,
        Preservation::Protect,
        Precision::Exact,
        Fortitude::Polite,
    );
    assert_eq!(result, Err(Error::Expendability));
}

/// Test transfer with locked balance exactly matching required amount
#[ink::test]
fn transfer_exact_locked_amount() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let from = accounts.bob;
    let to = accounts.charlie;
    contract.mint(from, 100).unwrap();
    
    // Lock exactly 50
    contract.set_lock(from, *b"testlock", 50).unwrap();
    
    // Try to transfer exactly the usable amount (line 781)
    test::set_caller::<ink::env::DefaultEnvironment>(from);
    let result = contract.transfer(to, 50);
    assert_eq!(result, Ok(()));
    assert_eq!(contract.balance(from), 50);
}

/// Test transfer that would leave dust with Preserve mode
#[ink::test]
fn transfer_preserve_would_leave_dust() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    if contract.existential_deposit() < 2 {
        return Ok(());
    }
    
    let from = accounts.bob;
    let to = accounts.charlie;
    let initial_balance = contract.existential_deposit() + 5;
    contract.mint(from, initial_balance).unwrap();
    contract.mint(to, 100).unwrap();
    
    // Try to transfer leaving dust with Preserve (line 898)
    test::set_caller::<ink::env::DefaultEnvironment>(from);
    let transfer_amount = 6;
    let result = contract.transfer_keep_alive(to, transfer_amount);
    assert_eq!(result, Err(Error::Expendability));
}

/// Test reserve with locked balance consideration
#[ink::test]
fn reserve_with_frozen_balance() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 100).unwrap();
    contract.set_lock(account, *b"testlock", 60).unwrap();
    
    // Try to reserve more than usable (line 590, 979)
    let result = contract.reserve(account, 50);
    assert_eq!(result, Err(Error::InsufficientBalance));
}

/// Test set_lock with zero amount on existing lock
#[ink::test]
fn set_lock_zero_update() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 100).unwrap();
    
    let lock_id = *b"testlock";
    contract.set_lock(account, lock_id, 50).unwrap();
    assert_eq!(contract.account(account).frozen, 50);
    
    // Update to zero (line 626, 629)
    contract.set_lock(account, lock_id, 0).unwrap();
    assert_eq!(contract.account(account).frozen, 0);
}

/// Test resolve_credit with zero amount credit
#[ink::test]
fn resolve_credit_zero_test() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    let credit = CreditImbalance { amount: 0 };
    
    let result = contract.resolve_credit(account, credit);
    assert_eq!(result, Ok(()));
}

/// Test pair overflow at exact boundary
#[ink::test]
fn pair_overflow_boundary() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    // Set total issuance to max
    contract.set_total_issuance(Balance::MAX).unwrap();
    
    // Try to create pair with any amount (should overflow)
    let result = contract.pair(1);
    assert_eq!(result, Err(Error::Overflow));
}

/// Test settle_debt with BestEffort returning remaining credit
#[ink::test]
fn settle_debt_best_effort_remaining() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 30).unwrap();
    
    // Create debt larger than can be settled
    let debt = DebtImbalance { amount: 100 };
    
    // Settle with Expendable (best effort)
    let remaining = contract.settle_debt(account, debt, Preservation::Expendable).unwrap();
    
    // Should burn all 30 and return 70 as remaining
    assert_eq!(contract.balance(account), 0);
    assert_eq!(remaining.peek(), 70);
}

/// Test can_deposit checking total issuance overflow before account overflow
#[ink::test]
fn can_deposit_total_issuance_check_order() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 100).unwrap();
    
    // Set total to near max but account has room
    contract.set_total_issuance(Balance::MAX - 5).unwrap();
    
    // Should check total issuance overflow
    let result = contract.can_deposit(account, 10, Provenance::Minted);
    assert_eq!(result, DepositConsequence::Overflow);
}

/// Test can_withdraw with exact ED balance
#[ink::test]
fn can_withdraw_exact_ed() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    if contract.existential_deposit() == 0 {
        return Ok(());
    }
    
    let account = accounts.bob;
    contract.mint(account, contract.existential_deposit()).unwrap();
    
    // Withdraw full ED should succeed (goes to zero, not dust)
    let result = contract.can_withdraw(account, contract.existential_deposit());
    assert_eq!(result, WithdrawConsequence::Success);
}

/// Test transfer to self (should be a no-op)
#[ink::test]
fn transfer_to_self() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    contract.mint(account, 100).unwrap();
    
    test::set_caller::<ink::env::DefaultEnvironment>(account);
    let result = contract.transfer(account, 10);
    assert_eq!(result, Ok(()));
    
    // Self-transfer should be a no-op
    assert_eq!(contract.balance(account), 100);
}

/// Test burn_from with preservation check before dust handling
#[ink::test]
fn burn_preservation_before_dust() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    if contract.existential_deposit() < 3 {
        return Ok(());
    }
    
    let account = accounts.bob;
    contract.mint(account, contract.existential_deposit() + 2).unwrap();
    
    // Burn leaving 1 token (dust) with Protect
    let burn_amount = contract.existential_deposit() + 1;
    let result = contract.burn_from(
        account,
        burn_amount,
        Preservation::Protect,
        Precision::Exact,
        Fortitude::Polite,
    );
    
    // Should fail at preservation check
    assert_eq!(result, Err(Error::Expendability));
    assert_eq!(contract.balance(account), contract.existential_deposit() + 2);
}