/// Tests issuing and resolving [`Credit`] imbalances with `issue` and `resolve`.
#[ink::test]
fn balanced_issue_and_resolve_credit() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;
    assert_eq!(contract.total_issuance(), 0);
    assert_eq!(contract.balance(account), 0);

    // Account that doesn't exist yet can't be credited below the minimum balance
    let amount = contract.minimum_balance() - 1;
    // In our contract, mint enforces minimum balance for new accounts
    assert_eq!(contract.mint(account, amount), Err(Error::ExistentialDeposit));
    // Total issuance should remain unchanged
    assert_eq!(contract.total_issuance(), 0);
    assert_eq!(contract.balance(account), 0);

    // Credit account with minimum balance
    let amount = contract.minimum_balance();
    contract.mint(account, amount).unwrap();
    assert_eq!(contract.total_issuance(), contract.minimum_balance());
    assert_eq!(contract.balance(account), contract.minimum_balance());

    // Now that account has been created, it can be credited with an amount below the minimum
    // balance.
    let total_issuance_before = contract.total_issuance();
    let balance_before = contract.balance(account);
    let amount = contract.minimum_balance() - 1;
    contract.mint(account, amount).unwrap();
    assert_eq!(contract.total_issuance(), total_issuance_before + amount);
    assert_eq!(contract.balance(account), balance_before + amount);
}

/// Tests issuing and resolving debt imbalances with burning operations.
#[ink::test]
fn balanced_rescind_and_settle_debt() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    // Credit account with some balance
    let account = accounts.bob;
    let initial_bal = contract.minimum_balance() + 10;
    contract.mint(account, initial_bal).unwrap();
    assert_eq!(contract.total_issuance(), initial_bal);
    assert_eq!(contract.balance(account), initial_bal);

    // Burn some balance
    let burn_amount = 2;
    let burned = contract.burn_from(
        account,
        burn_amount,
        Preservation::Expendable,
        Precision::Exact,
        Fortitude::Polite,
    ).unwrap();
    assert_eq!(burned, burn_amount);
    assert_eq!(contract.total_issuance(), initial_bal - burn_amount);
    assert_eq!(contract.balance(account), initial_bal - burn_amount);

    // Preservation::Preserve will not allow the account to be dusted on burn
    let balance_before = contract.balance(account);
    let total_issuance_before = contract.total_issuance();
    let burn_amount = balance_before - contract.minimum_balance() + 1;
    
    assert_eq!(
        contract.burn_from(
            account,
            burn_amount,
            Preservation::Preserve,
            Precision::Exact,
            Fortitude::Polite,
        ),
        Err(Error::Expendability)
    );
    // Operation failed, everything should be unchanged
    assert_eq!(contract.total_issuance(), total_issuance_before);
    assert_eq!(contract.balance(account), balance_before);

    // Preservation::Expendable allows the account to be dusted on burn
    let burned = contract.burn_from(
        account,
        burn_amount,
        Preservation::Expendable,
        Precision::Exact,
        Fortitude::Polite,
    ).unwrap();
    assert_eq!(burned, burn_amount);
    // The account is dusted
    assert_eq!(contract.total_issuance(), 0);
    assert_eq!(contract.balance(account), 0);
}

/// Tests minting (deposit equivalent).
#[ink::test]
fn balanced_deposit() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    // Cannot deposit < minimum balance into non-existent account
    let account = accounts.bob;
    let amount = contract.minimum_balance() - 1;
    assert_eq!(contract.mint(account, amount), Err(Error::ExistentialDeposit));
    assert_eq!(contract.total_issuance(), 0);
    assert_eq!(contract.balance(account), 0);

    // Can deposit minimum balance into non-existent account
    let amount = contract.minimum_balance();
    contract.mint(account, amount).unwrap();
    assert_eq!(contract.total_issuance(), amount);
    assert_eq!(contract.balance(account), amount);

    // Depositing amount that would overflow fails
    let amount = Balance::MAX;
    let balance_before = contract.balance(account);
    let total_issuance_before = contract.total_issuance();
    assert_eq!(contract.mint(account, amount), Err(Error::Overflow));
    assert_eq!(contract.total_issuance(), total_issuance_before);
    assert_eq!(contract.balance(account), balance_before);

    // Test restore for overflow saturation behavior
    let balance_before = contract.balance(account);
    let max_additional = Balance::MAX - balance_before;
    
    // Restore up to max
    contract.restore(account, max_additional).unwrap();
    assert_eq!(contract.total_issuance(), Balance::MAX);
    assert_eq!(contract.balance(account), Balance::MAX);
}

/// Tests withdrawal (burn with preservation).
#[ink::test]
fn balanced_withdraw() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account = accounts.bob;

    // Init an account with some balance
    let initial_balance = contract.minimum_balance() + 10;
    contract.mint(account, initial_balance).unwrap();
    assert_eq!(contract.total_issuance(), initial_balance);
    assert_eq!(contract.balance(account), initial_balance);

    // Withdrawing an amount smaller than the balance works when Precision::Exact
    let amount = 1;
    let burned = contract.burn_from(
        account,
        amount,
        Preservation::Expendable,
        Precision::Exact,
        Fortitude::Polite,
    ).unwrap();
    assert_eq!(burned, amount);
    assert_eq!(contract.total_issuance(), initial_balance - amount);
    assert_eq!(contract.balance(account), initial_balance - amount);

    // Withdrawing an amount greater than the balance fails when Precision::Exact
    let balance_before = contract.balance(account);
    let amount = balance_before + 1;
    assert_eq!(
        contract.burn_from(
            account,
            amount,
            Preservation::Expendable,
            Precision::Exact,
            Fortitude::Polite,
        ),
        Err(Error::InsufficientBalance)
    );
    assert_eq!(contract.total_issuance(), balance_before);
    assert_eq!(contract.balance(account), balance_before);

    // Withdrawing an amount greater than the balance works when Precision::BestEffort
    let balance_before = contract.balance(account);
    let amount = balance_before + 1;
    let burned = contract.burn_from(
        account,
        amount,
        Preservation::Expendable,
        Precision::BestEffort,
        Fortitude::Polite,
    ).unwrap();
    assert_eq!(burned, balance_before);
    assert_eq!(contract.total_issuance(), 0);
    assert_eq!(contract.balance(account), 0);
}

/// Test pair creation with Credit/Debt imbalances.
#[ink::test]
fn balanced_pair() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    contract.set_total_issuance(50).unwrap();

    // Pair zero balance works
    let (credit, debt) = contract.pair(0).unwrap();
    assert_eq!(debt.peek(), 0);
    assert_eq!(credit.peek(), 0);

    // Pair with non-zero balance: the credit and debt cancel each other out
    let balance = 10;
    let (credit, debt) = contract.pair(balance).unwrap();
    assert_eq!(credit.peek(), balance);
    assert_eq!(debt.peek(), balance);

    // Creating a pair that could increase total_issuance beyond the max value returns an error
    let max_value = Balance::MAX;
    let distance_from_max_value = 5;
    contract.set_total_issuance(max_value - distance_from_max_value).unwrap();
    assert!(contract.pair(distance_from_max_value + 5).is_err());
}