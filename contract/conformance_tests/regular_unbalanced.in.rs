/// Tests `set_balance` (write_balance equivalent).
#[ink::test]
fn unbalanced_write_balance() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    // Setup some accounts to test varying initial balances
    let account_0_ed = accounts.bob;
    let account_1_gt_ed = accounts.charlie;
    let account_2_empty = accounts.django;
    contract.mint(account_0_ed, contract.minimum_balance()).unwrap();
    contract.mint(account_1_gt_ed, contract.minimum_balance() + 5).unwrap();

    // Test setting the balances of each account by gt the minimum balance succeeds
    let amount = contract.minimum_balance() + 10;
    contract.set_balance(account_0_ed, amount);
    contract.set_balance(account_1_gt_ed, amount);
    contract.set_balance(account_2_empty, amount);
    assert_eq!(contract.balance(account_0_ed), amount);
    assert_eq!(contract.balance(account_1_gt_ed), amount);
    assert_eq!(contract.balance(account_2_empty), amount);

    // Test setting the balances to below the minimum balance
    // Our set_balance will set to the requested amount regardless
    let amount = contract.minimum_balance() - 1;
    if contract.minimum_balance() == 1 {
        contract.set_balance(account_0_ed, amount);
        contract.set_balance(account_1_gt_ed, amount);
        contract.set_balance(account_2_empty, amount);
        assert_eq!(contract.balance(account_0_ed), amount);
        assert_eq!(contract.balance(account_1_gt_ed), amount);
        assert_eq!(contract.balance(account_2_empty), amount);
    } else if contract.minimum_balance() > 1 {
        // set_balance will reduce to the amount, even if below ED
        // The accounts would be reaped on next operation
        contract.set_balance(account_0_ed, amount);
        contract.set_balance(account_1_gt_ed, amount);
        contract.set_balance(account_2_empty, amount);
        // Our implementation doesn't immediately reap, so balances are set
        assert_eq!(contract.balance(account_0_ed), amount);
        assert_eq!(contract.balance(account_1_gt_ed), amount);
        assert_eq!(contract.balance(account_2_empty), amount);
    }
}

/// Tests `burn_from` with `Preservation::Expendable` (decrease_balance equivalent).
#[ink::test]
fn unbalanced_decrease_balance_expendable() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    // Setup account with some balance
    let account_0 = accounts.bob;
    let account_0_initial_balance = contract.minimum_balance() + 10;
    contract.mint(account_0, account_0_initial_balance).unwrap();

    // Decreasing the balance still above the minimum balance should not reap the account
    let amount = 1;
    let burned = contract.burn_from(
        account_0,
        amount,
        Preservation::Expendable,
        Precision::Exact,
        Fortitude::Polite,
    ).unwrap();
    assert_eq!(burned, amount);
    assert_eq!(contract.balance(account_0), account_0_initial_balance - amount);

    // Decreasing the balance below funds available should fail when Precision::Exact
    let balance_before = contract.balance(account_0);
    assert_eq!(
        contract.burn_from(
            account_0,
            account_0_initial_balance,
            Preservation::Expendable,
            Precision::Exact,
            Fortitude::Polite,
        ),
        Err(Error::InsufficientBalance)
    );
    // Balance unchanged
    assert_eq!(contract.balance(account_0), balance_before);

    // And reap the account when Precision::BestEffort
    let burned = contract.burn_from(
        account_0,
        account_0_initial_balance,
        Preservation::Expendable,
        Precision::BestEffort,
        Fortitude::Polite,
    ).unwrap();
    assert_eq!(burned, balance_before);
    // Account reaped
    assert_eq!(contract.balance(account_0), 0);
}

/// Tests `burn_from` with `Preservation::Preserve` (decrease_balance equivalent).
#[ink::test]
fn unbalanced_decrease_balance_preserve() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    // Setup account with some balance
    let account_0 = accounts.bob;
    let account_0_initial_balance = contract.minimum_balance() + 10;
    contract.mint(account_0, account_0_initial_balance).unwrap();

    // Decreasing the balance below the minimum when Precision::Exact should fail
    let amount = 11;
    assert_eq!(
        contract.burn_from(
            account_0,
            amount,
            Preservation::Preserve,
            Precision::Exact,
            Fortitude::Polite,
        ),
        Err(Error::Expendability)
    );
    // Balance should not have changed
    assert_eq!(contract.balance(account_0), account_0_initial_balance);

    // Decreasing the balance below the minimum when Precision::BestEffort should reduce to
    // the maximum possible while preserving the account
    let amount = 11;
    let burned = contract.burn_from(
        account_0,
        amount,
        Preservation::Preserve,
        Precision::BestEffort,
        Fortitude::Polite,
    ).unwrap();
    assert_eq!(burned, account_0_initial_balance - contract.minimum_balance());
    assert_eq!(contract.balance(account_0), contract.minimum_balance());
}

/// Tests `mint` (increase_balance equivalent).
#[ink::test]
fn unbalanced_increase_balance() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    let account_0 = accounts.bob;
    assert_eq!(contract.balance(account_0), 0);

    // Increasing the balance below the ED errors when using mint
    if contract.minimum_balance() > 0 {
        assert_eq!(
            contract.mint(account_0, contract.minimum_balance() - 1),
            Err(Error::ExistentialDeposit)
        );
    }
    assert_eq!(contract.balance(account_0), 0);

    // Can increase if new balance is >= ED
    contract.mint(account_0, contract.minimum_balance()).unwrap();
    assert_eq!(contract.balance(account_0), contract.minimum_balance());
    
    contract.mint(account_0, 5).unwrap();
    assert_eq!(contract.balance(account_0), contract.minimum_balance() + 5);

    // Increasing by amount that would overflow fails
    assert_eq!(
        contract.mint(account_0, Balance::MAX),
        Err(Error::Overflow)
    );

    // Test restore for best-effort behavior on overflow
    let balance_before = contract.balance(account_0);
    let max_additional = Balance::MAX - balance_before;
    contract.restore(account_0, max_additional).unwrap();
    assert_eq!(contract.balance(account_0), Balance::MAX);
}

/// Tests `set_total_issuance`.
#[ink::test]
fn unbalanced_set_total_issuance() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    contract.set_total_issuance(1).unwrap();
    assert_eq!(contract.total_issuance(), 1);

    contract.set_total_issuance(0).unwrap();
    assert_eq!(contract.total_issuance(), 0);

    contract.set_total_issuance(contract.minimum_balance()).unwrap();
    assert_eq!(contract.total_issuance(), contract.minimum_balance());

    contract.set_total_issuance(contract.minimum_balance() + 5).unwrap();
    assert_eq!(contract.total_issuance(), contract.minimum_balance() + 5);

    if contract.minimum_balance() > 0 {
        contract.set_total_issuance(contract.minimum_balance() - 1).unwrap();
        assert_eq!(contract.total_issuance(), contract.minimum_balance() - 1);
    }
}

/// Tests `deactivate` and `reactivate`.
#[ink::test]
fn unbalanced_deactivate_and_reactivate() {
    let accounts = test::default_accounts::<ink::env::DefaultEnvironment>();
    test::set_caller::<ink::env::DefaultEnvironment>(accounts.alice);
    let mut contract = new_contract(10, 5, None);
    
    contract.set_total_issuance(10).unwrap();
    assert_eq!(contract.total_issuance(), 10);
    assert_eq!(contract.active_issuance(), 10);

    contract.deactivate(2).unwrap();
    assert_eq!(contract.total_issuance(), 10);
    assert_eq!(contract.active_issuance(), 8);

    // Saturates at total_issuance
    contract.reactivate(4).unwrap();
    assert_eq!(contract.total_issuance(), 10);
    assert_eq!(contract.active_issuance(), 10);

    // Decrements correctly after saturating at total_issuance
    contract.deactivate(1).unwrap();
    assert_eq!(contract.total_issuance(), 10);
    assert_eq!(contract.active_issuance(), 9);

    // Saturates at zero
    contract.deactivate(15).unwrap();
    assert_eq!(contract.total_issuance(), 10);
    assert_eq!(contract.active_issuance(), 0);

    // Increments correctly after saturating at zero
    contract.reactivate(1).unwrap();
    assert_eq!(contract.total_issuance(), 10);
    assert_eq!(contract.active_issuance(), 1);
}