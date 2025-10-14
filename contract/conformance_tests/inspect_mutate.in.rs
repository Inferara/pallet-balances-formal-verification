/// Helper to create contract with optional dust trap
fn new_contract(ed: Balance, max_locks: u32, dust_trap: Option<AccountId>) -> BalancesContract {
    match dust_trap {
        Some(trap) => BalancesContract::new_with_dust_trap(ed, max_locks, trap),
        None => BalancesContract::new(ed, max_locks),
    }
}

/// Test the `mint` function for successful token minting.
#[ink::test]
fn mint_into_success() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let initial_total_issuance = contract.total_issuance();
    let account_0 = accounts.bob;
    let account_1 = accounts.charlie;

    // Test: Mint an amount into each account
    let amount_0 = contract.existential_deposit();
    let amount_1 = contract.existential_deposit() + 5;
    contract.mint(account_0, amount_0).unwrap();
    contract.mint(account_1, amount_1).unwrap();

    // Verify: Account balances are updated correctly
    assert_eq!(contract.total_balance(account_0), amount_0);
    assert_eq!(contract.total_balance(account_1), amount_1);
    assert_eq!(contract.balance(account_0), amount_0);
    assert_eq!(contract.balance(account_1), amount_1);

    // Verify: Total issuance is updated correctly
    assert_eq!(contract.total_issuance(), initial_total_issuance + amount_0 + amount_1);
    assert_eq!(contract.active_issuance(), initial_total_issuance + amount_0 + amount_1);
}

/// Test the `mint` function for overflow prevention.
#[ink::test]
fn mint_into_overflow() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let initial_total_issuance = contract.total_issuance();
    let account = accounts.bob;
    let amount = Balance::MAX - 5 - initial_total_issuance;

    // Mint just below the maximum balance
    contract.mint(account, amount).unwrap();

    // Verify: Minting beyond the maximum balance value returns an Err
    assert_eq!(contract.mint(account, 10), Err(Error::Overflow));

    // Verify: The balance did not change
    assert_eq!(contract.total_balance(account), amount);
    assert_eq!(contract.balance(account), amount);

    // Verify: The total issuance did not change
    assert_eq!(contract.total_issuance(), initial_total_issuance + amount);
    assert_eq!(contract.active_issuance(), initial_total_issuance + amount);
}

/// Test the `mint` function for handling balances below the minimum value.
#[ink::test]
fn mint_into_below_minimum() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    // Skip if there is no minimum balance
    if contract.existential_deposit() == 0 {
        return Ok(());
    }

    let initial_total_issuance = contract.total_issuance();
    let account = accounts.bob;
    let amount = contract.existential_deposit() - 1;

    // Verify: Minting below the minimum balance returns Err
    assert_eq!(contract.mint(account, amount), Err(Error::ExistentialDeposit));

    // Verify: noop
    assert_eq!(contract.total_balance(account), 0);
    assert_eq!(contract.balance(account), 0);
    assert_eq!(contract.total_issuance(), initial_total_issuance);
    assert_eq!(contract.active_issuance(), initial_total_issuance);
}

/// Test the `burn_from` function for successfully burning an exact amount of tokens.
#[ink::test]
fn burn_from_exact_success() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let initial_total_issuance = contract.total_issuance();

    // Setup account
    let account = accounts.bob;
    let initial_balance = contract.minimum_balance() + 10;
    contract.mint(account, initial_balance).unwrap();

    // Test: Burn an exact amount from the account
    let amount_to_burn = 5;
    let preservation = Preservation::Expendable;
    let precision = Precision::Exact;
    let force = Fortitude::Polite;
    contract.burn_from(account, amount_to_burn, preservation, precision, force).unwrap();

    // Verify: The balance and total issuance should be reduced by the burned amount
    assert_eq!(contract.balance(account), initial_balance - amount_to_burn);
    assert_eq!(contract.total_balance(account), initial_balance - amount_to_burn);
    assert_eq!(contract.total_issuance(), initial_total_issuance + initial_balance - amount_to_burn);
    assert_eq!(contract.active_issuance(), initial_total_issuance + initial_balance - amount_to_burn);
}

/// Test the `burn_from` function for successfully burning tokens with a best-effort approach.
#[ink::test]
fn burn_from_best_effort_success() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let initial_total_issuance = contract.total_issuance();

    // Setup account
    let account = accounts.bob;
    let initial_balance = contract.minimum_balance() + 10;
    contract.mint(account, initial_balance).unwrap();

    // Get reducible balance
    let force = Fortitude::Polite;
    let reducible_balance = contract.reducible_balance(account, Preservation::Expendable, force);

    // Test: Burn a best effort amount from the account that is greater than the reducible balance
    let amount_to_burn = reducible_balance + 5;
    let preservation = Preservation::Expendable;
    let precision = Precision::BestEffort;
    assert!(amount_to_burn > reducible_balance);
    assert!(amount_to_burn > contract.balance(account));
    contract.burn_from(account, amount_to_burn, preservation, precision, force).unwrap();

    // Verify: The balance and total issuance should be reduced by the reducible_balance
    assert_eq!(contract.balance(account), initial_balance - reducible_balance);
    assert_eq!(contract.total_balance(account), initial_balance - reducible_balance);
    assert_eq!(contract.total_issuance(), initial_total_issuance + initial_balance - reducible_balance);
    assert_eq!(contract.active_issuance(), initial_total_issuance + initial_balance - reducible_balance);
}

/// Test the `burn_from` function for handling insufficient funds with `Precision::Exact`.
#[ink::test]
fn burn_from_exact_insufficient_funds() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    // Set up the initial conditions and parameters for the test
    let account = accounts.bob;
    let initial_balance = contract.minimum_balance() + 10;
    contract.mint(account, initial_balance).unwrap();
    let initial_total_issuance = contract.total_issuance();

    // Verify: Burn an amount greater than the account's balance with Exact precision returns Err
    let amount_to_burn = initial_balance + 10;
    let preservation = Preservation::Expendable;
    let precision = Precision::Exact;
    let force = Fortitude::Polite;
    assert_eq!(
        contract.burn_from(account, amount_to_burn, preservation, precision, force),
        Err(Error::InsufficientBalance)
    );

    // Verify: The balance and total issuance should remain unchanged
    assert_eq!(contract.balance(account), initial_balance);
    assert_eq!(contract.total_balance(account), initial_balance);
    assert_eq!(contract.total_issuance(), initial_total_issuance);
    assert_eq!(contract.active_issuance(), initial_total_issuance);
}

/// Test the `restore` function for successful restoration.
#[ink::test]
fn restore_success() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account_0 = accounts.bob;
    let account_1 = accounts.charlie;

    // Test: Restore an amount into each account
    let amount_0 = contract.minimum_balance();
    let amount_1 = contract.minimum_balance() + 5;
    let initial_total_issuance = contract.total_issuance();
    contract.restore(account_0, amount_0).unwrap();
    contract.restore(account_1, amount_1).unwrap();

    // Verify: Account balances are updated correctly
    assert_eq!(contract.total_balance(account_0), amount_0);
    assert_eq!(contract.total_balance(account_1), amount_1);
    assert_eq!(contract.balance(account_0), amount_0);
    assert_eq!(contract.balance(account_1), amount_1);

    // Verify: Total issuance is updated correctly
    assert_eq!(contract.total_issuance(), initial_total_issuance + amount_0 + amount_1);
    assert_eq!(contract.active_issuance(), initial_total_issuance + amount_0 + amount_1);
}

/// Test the `restore` function for handling balance overflow.
#[ink::test]
fn restore_overflow() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let initial_total_issuance = contract.total_issuance();
    let account = accounts.bob;
    let amount = Balance::MAX - 5 - initial_total_issuance;

    // Restore just below the maximum balance
    contract.restore(account, amount).unwrap();

    // Verify: Restoring beyond the maximum balance returns an Err
    assert_eq!(contract.restore(account, 10), Err(Error::Overflow));

    // Verify: The balance and total issuance did not change
    assert_eq!(contract.total_balance(account), amount);
    assert_eq!(contract.balance(account), amount);
    assert_eq!(contract.total_issuance(), initial_total_issuance + amount);
    assert_eq!(contract.active_issuance(), initial_total_issuance + amount);
}

/// Test the `restore` function for handling restoration below the minimum balance.
#[ink::test]
fn restore_below_minimum() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    // Skip if there is no minimum balance
    if contract.minimum_balance() == 0 {
        return Ok(());
    }

    let account = accounts.bob;
    let amount = contract.minimum_balance() - 1;
    let initial_total_issuance = contract.total_issuance();

    // Verify: Restoring below the minimum balance returns Err
    assert_eq!(contract.restore(account, amount), Err(Error::ExistentialDeposit));

    // Verify: noop
    assert_eq!(contract.total_balance(account), 0);
    assert_eq!(contract.balance(account), 0);
    assert_eq!(contract.total_issuance(), initial_total_issuance);
    assert_eq!(contract.active_issuance(), initial_total_issuance);
}

/// Test the `shelve` function for successful shelving.
#[ink::test]
fn shelve_success() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let initial_total_issuance = contract.total_issuance();

    // Setup account
    let account = accounts.bob;
    let initial_balance = contract.minimum_balance() + 10;

    contract.restore(account, initial_balance).unwrap();

    // Test: Shelve an amount from the account
    let amount_to_shelve = 5;
    contract.shelve(account, amount_to_shelve).unwrap();

    // Verify: The balance and total issuance should be reduced by the shelved amount
    assert_eq!(contract.balance(account), initial_balance - amount_to_shelve);
    assert_eq!(contract.total_balance(account), initial_balance - amount_to_shelve);
    assert_eq!(contract.total_issuance(), initial_total_issuance + initial_balance - amount_to_shelve);
    assert_eq!(contract.active_issuance(), initial_total_issuance + initial_balance - amount_to_shelve);
}

/// Test the `shelve` function for handling insufficient funds.
#[ink::test]
fn shelve_insufficient_funds() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let initial_total_issuance = contract.total_issuance();

    // Set up the initial conditions and parameters for the test
    let account = accounts.bob;
    let initial_balance = contract.minimum_balance() + 10;
    contract.restore(account, initial_balance).unwrap();

    // Verify: Shelving greater than the balance returns Err
    let amount_to_shelve = initial_balance + 10;
    assert_eq!(contract.shelve(account, amount_to_shelve), Err(Error::InsufficientBalance));

    // Verify: The balance and total issuance should remain unchanged
    assert_eq!(contract.balance(account), initial_balance);
    assert_eq!(contract.total_balance(account), initial_balance);
    assert_eq!(contract.total_issuance(), initial_total_issuance + initial_balance);
    assert_eq!(contract.active_issuance(), initial_total_issuance + initial_balance);
}

/// Test the `transfer` function for a successful transfer.
#[ink::test]
fn transfer_success() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let initial_total_issuance = contract.total_issuance();
    let account_0 = accounts.bob;
    let account_1 = accounts.charlie;
    let initial_balance = contract.minimum_balance() + 10;
    contract.set_balance(account_0, initial_balance);
    contract.set_balance(account_1, initial_balance);

    // Test: Transfer an amount from account_0 to account_1
    test::set_caller::<ink::env::DefaultEnvironment>(account_0);
    let transfer_amount = 3;
    contract.transfer(account_1, transfer_amount).unwrap();

    // Verify: Account balances are updated correctly
    assert_eq!(contract.total_balance(account_0), initial_balance - transfer_amount);
    assert_eq!(contract.total_balance(account_1), initial_balance + transfer_amount);
    assert_eq!(contract.balance(account_0), initial_balance - transfer_amount);
    assert_eq!(contract.balance(account_1), initial_balance + transfer_amount);

    // Verify: Total issuance doesn't change
    assert_eq!(contract.total_issuance(), initial_total_issuance + initial_balance * 2);
    assert_eq!(contract.active_issuance(), initial_total_issuance + initial_balance * 2);
}

/// Test the `transfer` function with `Expendable` for transferring the entire balance.
#[ink::test]
fn transfer_expendable_all() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let initial_total_issuance = contract.total_issuance();
    let account_0 = accounts.bob;
    let account_1 = accounts.charlie;
    let initial_balance = contract.minimum_balance() + 10;
    contract.set_balance(account_0, initial_balance);
    contract.set_balance(account_1, initial_balance);

    // Test: Transfer entire balance from account_0 to account_1
    test::set_caller::<ink::env::DefaultEnvironment>(account_0);
    let transfer_amount = initial_balance;
    contract.transfer(account_1, transfer_amount).unwrap();

    // Verify: Account balances are updated correctly
    assert_eq!(contract.total_balance(account_0), 0);
    assert_eq!(contract.total_balance(account_1), initial_balance * 2);
    assert_eq!(contract.balance(account_0), 0);
    assert_eq!(contract.balance(account_1), initial_balance * 2);

    // Verify: Total issuance doesn't change
    assert_eq!(contract.total_issuance(), initial_total_issuance + initial_balance * 2);
    assert_eq!(contract.active_issuance(), initial_total_issuance + initial_balance * 2);
}

/// Test the transfer function with Expendable for transferring amounts that leaves
/// an account with less than the minimum balance.
#[ink::test]
fn transfer_expendable_dust_no_trap() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    if contract.existential_deposit() == 0 {
        return Ok(());
    }

    let account_0 = accounts.bob;
    let account_1 = accounts.charlie;
    let initial_balance = contract.existential_deposit() + 10;
    
    contract.set_balance(account_0, initial_balance);
    contract.set_balance(account_1, initial_balance);

    let initial_total_issuance = contract.total_issuance();

    // Test: Transfer balance leaving dust
    test::set_caller::<ink::env::DefaultEnvironment>(account_0);
    let transfer_amount = 11;
    contract.transfer(account_1, transfer_amount).unwrap();

    // Verify: Account balances are updated correctly
    assert_eq!(contract.total_balance(account_0), 0);
    assert_eq!(contract.total_balance(account_1), initial_balance + transfer_amount);
    assert_eq!(contract.balance(account_0), 0);
    assert_eq!(contract.balance(account_1), initial_balance + transfer_amount);

    // Verify: Total issuance is reduced by the dust amount
    assert_eq!(
        contract.total_issuance(),
        initial_total_issuance - contract.existential_deposit() + 1
    );
    assert_eq!(
        contract.active_issuance(),
        initial_total_issuance - contract.existential_deposit() + 1
    );
}

/// Test the transfer function with dust trap enabled.
#[ink::test]
fn transfer_expendable_dust_with_trap() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    
    let dust_trap = accounts.django;
    let mut contract = new_contract(10, 5, Some(dust_trap));
    
    if contract.existential_deposit() == 0 {
        return Ok(());
    }

    let account_0 = accounts.bob;
    let account_1 = accounts.charlie;
    let initial_balance = contract.existential_deposit() + 10;
    
    contract.set_balance(account_0, initial_balance);
    contract.set_balance(account_1, initial_balance);

    let initial_total_issuance = contract.total_issuance();
    let initial_dust_trap_balance = contract.total_balance(dust_trap);

    // Test: Transfer balance leaving dust
    test::set_caller::<ink::env::DefaultEnvironment>(account_0);
    let transfer_amount = 11;
    contract.transfer(account_1, transfer_amount).unwrap();

    // Verify: Account balances are updated correctly
    assert_eq!(contract.total_balance(account_0), 0);
    assert_eq!(contract.total_balance(account_1), initial_balance + transfer_amount);

    // Verify: Total issuance doesn't change
    assert_eq!(contract.total_issuance(), initial_total_issuance);
    assert_eq!(contract.active_issuance(), initial_total_issuance);

    // Verify: Dust is collected into dust trap
    assert_eq!(
        contract.total_balance(dust_trap),
        initial_dust_trap_balance + contract.minimum_balance() - 1
    );
}

/// Test the `transfer_keep_alive` function for protecting accounts.
#[ink::test]
fn transfer_protect_preserve() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    // This test means nothing if there is no minimum balance
    if contract.existential_deposit() == 0 {
        return Ok(());
    }

    let initial_total_issuance = contract.total_issuance();
    let account_0 = accounts.bob;
    let account_1 = accounts.charlie;
    let initial_balance = contract.existential_deposit() + 10;
    contract.set_balance(account_0, initial_balance);
    contract.set_balance(account_1, initial_balance);

    // Verify: Transfer keep_alive entire balance from account_0 to account_1 should Err
    test::set_caller::<ink::env::DefaultEnvironment>(account_0);
    let transfer_amount = initial_balance;
    assert_eq!(
        contract.transfer_keep_alive(account_1, transfer_amount),
        Err(Error::Expendability)
    );

    // Verify: Noop
    assert_eq!(contract.total_balance(account_0), initial_balance);
    assert_eq!(contract.total_balance(account_1), initial_balance);
    assert_eq!(contract.balance(account_0), initial_balance);
    assert_eq!(contract.balance(account_1), initial_balance);
    assert_eq!(contract.total_issuance(), initial_total_issuance + initial_balance * 2);
    assert_eq!(contract.active_issuance(), initial_total_issuance + initial_balance * 2);

    // Verify: Transfer with explicit Preserve should also fail
    assert_eq!(
        contract.transfer_with_preservation(account_1, transfer_amount, Preservation::Preserve),
        Err(Error::Expendability)
    );

    // Verify: Noop
    assert_eq!(contract.total_balance(account_0), initial_balance);
    assert_eq!(contract.total_balance(account_1), initial_balance);
    assert_eq!(contract.balance(account_0), initial_balance);
    assert_eq!(contract.balance(account_1), initial_balance);
    assert_eq!(contract.total_issuance(), initial_total_issuance + initial_balance * 2);
    assert_eq!(contract.active_issuance(), initial_total_issuance + initial_balance * 2);
}

/// Test the set_balance function for successful minting.
#[ink::test]
fn set_balance_mint_success() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let initial_total_issuance = contract.total_issuance();
    let account = accounts.bob;
    let initial_balance = contract.minimum_balance() + 10;
    contract.mint(account, initial_balance).unwrap();

    // Test: Increase the account balance with set_balance
    let increase_amount: Balance = 5;
    let new = contract.set_balance(account, initial_balance + increase_amount);

    // Verify: set_balance returned the new balance
    let expected_new = initial_balance + increase_amount;
    assert_eq!(new, expected_new);

    // Verify: Balance and issuance is updated correctly
    assert_eq!(contract.total_balance(account), expected_new);
    assert_eq!(contract.balance(account), expected_new);
    assert_eq!(contract.total_issuance(), initial_total_issuance + expected_new);
    assert_eq!(contract.active_issuance(), initial_total_issuance + expected_new);
}

/// Test the set_balance function for successful burning.
#[ink::test]
fn set_balance_burn_success() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let initial_total_issuance = contract.total_issuance();
    let account = accounts.bob;
    let initial_balance = contract.minimum_balance() + 10;
    contract.mint(account, initial_balance).unwrap();

    // Test: Decrease the account balance with set_balance
    let burn_amount: Balance = 5;
    let new = contract.set_balance(account, initial_balance - burn_amount);

    // Verify: set_balance returned the new balance
    let expected_new = initial_balance - burn_amount;
    assert_eq!(new, expected_new);

    // Verify: Balance and issuance is updated correctly
    assert_eq!(contract.total_balance(account), expected_new);
    assert_eq!(contract.balance(account), expected_new);
    assert_eq!(contract.total_issuance(), initial_total_issuance + expected_new);
    assert_eq!(contract.active_issuance(), initial_total_issuance + expected_new);
}

/// Test the can_deposit function for returning a success value.
#[ink::test]
fn can_deposit_success() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    let initial_balance = contract.minimum_balance() + 10;
    contract.mint(account, initial_balance).unwrap();

    // Test: can_deposit a reasonable amount
    let ret = contract.can_deposit(account, 5, Provenance::Minted);

    // Verify: Returns success
    assert_eq!(ret, DepositConsequence::Success);
}

/// Test the can_deposit function for returning a minimum balance error.
#[ink::test]
fn can_deposit_below_minimum() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let contract = new_contract(10, 5, None);
    
    // can_deposit always returns Success for amount 0
    if contract.minimum_balance() < 2 {
        return Ok(());
    }

    let account = accounts.bob;

    // Test: can_deposit below the minimum
    let ret = contract.can_deposit(account, contract.minimum_balance() - 1, Provenance::Minted);

    // Verify: Returns BelowMinimum
    assert_eq!(ret, DepositConsequence::BelowMinimum);
}

/// Test the can_deposit function for returning an overflow error.
#[ink::test]
fn can_deposit_overflow() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;

    // Test: Try deposit over the max balance
    let initial_balance = Balance::MAX - 5 - contract.total_issuance();
    contract.mint(account, initial_balance).unwrap();
    let ret = contract.can_deposit(account, 10, Provenance::Minted);

    // Verify: Returns Overflow
    assert_eq!(ret, DepositConsequence::Overflow);
}

/// Test the can_withdraw function for returning a success value.
#[ink::test]
fn can_withdraw_success() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    let initial_balance = contract.minimum_balance() + 10;
    contract.mint(account, initial_balance).unwrap();

    // Test: can_withdraw a reasonable amount
    let ret = contract.can_withdraw(account, 5);

    // Verify: Returns success
    assert_eq!(ret, WithdrawConsequence::Success);
}

/// Test the can_withdraw function for withdrawal resulting in a reduced balance of zero.
#[ink::test]
fn can_withdraw_reduced_to_zero() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    if contract.minimum_balance() == 0 {
        return Ok(());
    }

    let account = accounts.bob;
    let initial_balance = contract.minimum_balance();
    contract.mint(account, initial_balance).unwrap();

    // Verify: can_withdraw below the minimum balance returns ReducedToZero
    let ret = contract.can_withdraw(account, 1);
    assert_eq!(ret, WithdrawConsequence::ReducedToZero(contract.minimum_balance() - 1));
}

/// Test the can_withdraw function for returning a low balance error.
#[ink::test]
fn can_withdraw_balance_low() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    if contract.minimum_balance() == 0 {
        return Ok(());
    }

    let account = accounts.bob;
    let other_account = accounts.charlie;
    let initial_balance = contract.minimum_balance() + 5;
    contract.mint(account, initial_balance).unwrap();
    contract.mint(other_account, initial_balance * 2).unwrap();

    // Verify: can_withdraw more than the account balance returns BalanceLow
    let ret = contract.can_withdraw(account, initial_balance + 1);
    assert_eq!(ret, WithdrawConsequence::BalanceLow);
}

/// Test the reducible_balance function with Preservation::Expendable.
#[ink::test]
fn reducible_balance_expendable() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    let initial_balance = contract.minimum_balance() + 10;
    contract.mint(account, initial_balance).unwrap();

    // Verify: reducible_balance returns the full balance
    let ret = contract.reducible_balance(account, Preservation::Expendable, Fortitude::Polite);
    assert_eq!(ret, initial_balance);
}

/// Test the reducible_balance function with Preservation::Protect and Preservation::Preserve.
#[ink::test]
fn reducible_balance_protect_preserve() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    let initial_balance = contract.minimum_balance() + 10;
    contract.mint(account, initial_balance).unwrap();

    // Verify: reducible_balance returns the full balance - min balance
    let ret = contract.reducible_balance(account, Preservation::Protect, Fortitude::Polite);
    assert_eq!(ret, initial_balance - contract.minimum_balance());
    let ret = contract.reducible_balance(account, Preservation::Preserve, Fortitude::Polite);
    assert_eq!(ret, initial_balance - contract.minimum_balance());
}