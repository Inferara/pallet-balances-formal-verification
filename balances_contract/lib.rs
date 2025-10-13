#![cfg_attr(not(feature = "std"), no_std, no_main)]

#[ink::contract]
mod balances_contract {
    use ink::prelude::vec::Vec;
    use ink::storage::Mapping;

    /// Account data structure similar to pallet_balances
    #[derive(Debug, Clone, Copy, PartialEq, Eq, scale::Encode, scale::Decode, Default)]
    #[cfg_attr(
        feature = "std",
        derive(scale_info::TypeInfo, ink::storage::traits::StorageLayout)
    )]
    pub struct AccountData {
        /// The free balance available to the account
        pub free: Balance,
        /// Balance that is reserved and cannot be spent
        pub reserved: Balance,
        /// Balance that is frozen (locked but can be used for fees)
        pub frozen: Balance,
    }

    /// Balance lock structure
    #[derive(Debug, Clone, Copy, PartialEq, Eq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub struct BalanceLock {
        /// Identifier for this lock
        pub id: [u8; 8],
        /// Amount locked
        pub amount: Balance,
    }

    /// Represents a positive imbalance (credit) - tokens that exist but aren't yet assigned
    #[derive(Debug, Clone, Copy, PartialEq, Eq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub struct CreditImbalance {
        amount: Balance,
    }

    /// Represents a negative imbalance (debt) - tokens that are owed but don't exist yet
    #[derive(Debug, Clone, Copy, PartialEq, Eq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub struct DebtImbalance {
        amount: Balance,
    }

    impl CreditImbalance {
        pub fn peek(&self) -> Balance {
            self.amount
        }
    }

    impl DebtImbalance {
        pub fn peek(&self) -> Balance {
            self.amount
        }
    }

    /// Preservation mode for transfers and burns
    #[derive(Debug, Clone, Copy, PartialEq, Eq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub enum Preservation {
        /// Account can be killed (balance can go to zero)
        Expendable,
        /// Account must stay above existential deposit
        Preserve,
        /// Similar to Preserve
        Protect,
    }

    /// Precision mode for operations
    #[derive(Debug, Clone, Copy, PartialEq, Eq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub enum Precision {
        /// Operation must process exact amount or fail
        Exact,
        /// Operation processes as much as possible
        BestEffort,
    }

    /// Fortitude level for operations
    #[derive(Debug, Clone, Copy, PartialEq, Eq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub enum Fortitude {
        /// Regular operation respecting locks
        Polite,
        /// Forced operation ignoring some restrictions
        Force,
    }

    /// Provenance of a deposit
    #[derive(Debug, Clone, Copy, PartialEq, Eq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub enum Provenance {
        /// New tokens minted
        Minted,
        /// Tokens from existing account
        Extant,
    }

    /// Result of checking if deposit is possible
    #[derive(Debug, Clone, Copy, PartialEq, Eq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub enum DepositConsequence {
        /// Deposit can proceed
        Success,
        /// Would cause overflow
        Overflow,
        /// Below minimum balance
        BelowMinimum,
        /// Account cannot exist
        CannotCreate,
        /// Unknown error
        UnknownAsset,
    }

    /// Result of checking if withdrawal is possible
    #[derive(Debug, Clone, Copy, PartialEq, Eq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    #[allow(clippy::cast_possible_truncation)]
    /// Suppression of weird Clippy error
    pub enum WithdrawConsequence {
        /// Withdrawal can proceed
        Success,
        /// Account has insufficient balance
        BalanceLow,
        /// Would reduce account to zero (dust)
        ReducedToZero(Balance),
        /// Withdrawal would kill account but not allowed
        WouldDie,
        /// Account doesn't exist
        UnknownAsset,
        /// Funds are locked
        Frozen,
    }

    /// Events emitted by the contract
    #[ink(event)]
    pub struct Transfer {
        #[ink(topic)]
        from: Option<AccountId>,
        #[ink(topic)]
        to: Option<AccountId>,
        value: Balance,
    }

    #[ink(event)]
    pub struct Endowed {
        #[ink(topic)]
        account: AccountId,
        free_balance: Balance,
    }

    #[ink(event)]
    pub struct DustLost {
        #[ink(topic)]
        account: AccountId,
        amount: Balance,
    }

    #[ink(event)]
    pub struct Reserved {
        #[ink(topic)]
        who: AccountId,
        amount: Balance,
    }

    #[ink(event)]
    pub struct Unreserved {
        #[ink(topic)]
        who: AccountId,
        amount: Balance,
    }

    #[ink(event)]
    pub struct Locked {
        #[ink(topic)]
        who: AccountId,
        amount: Balance,
    }

    #[ink(event)]
    pub struct Unlocked {
        #[ink(topic)]
        who: AccountId,
        amount: Balance,
    }

    #[ink(event)]
    pub struct Burned {
        #[ink(topic)]
        who: AccountId,
        amount: Balance,
    }

    #[ink(event)]
    pub struct Restored {
        #[ink(topic)]
        who: AccountId,
        amount: Balance,
    }

    #[ink(event)]
    pub struct Shelved {
        #[ink(topic)]
        who: AccountId,
        amount: Balance,
    }

    /// Custom errors
    #[derive(Debug, PartialEq, Eq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub enum Error {
        /// Insufficient balance for the operation
        InsufficientBalance,
        /// Balance below existential deposit
        ExistentialDeposit,
        /// Account liquidity restrictions prevent withdrawal
        LiquidityRestrictions,
        /// Transfer would kill account
        Expendability,
        /// Arithmetic overflow
        Overflow,
        /// Too many locks on account
        TooManyLocks,
        /// Operation not allowed
        NotAllowed,
    }

    pub type Result<T> = core::result::Result<T, Error>;

    /// Storage structure
    #[ink(storage)]
    pub struct BalancesContract {
        /// Total token supply
        total_issuance: Balance,
        /// Active issuance (total - inactive/deactivated)
        active_issuance: Balance,
        /// Mapping from account to their balance data
        accounts: Mapping<AccountId, AccountData>,
        /// Locks on accounts
        locks: Mapping<AccountId, Vec<BalanceLock>>,
        /// Existential deposit - minimum balance to keep account alive
        existential_deposit: Balance,
        /// Maximum number of locks per account
        max_locks: u32,
        /// Contract owner
        owner: AccountId,
        /// Optional dust trap account
        dust_trap: Option<AccountId>,
    }

    impl BalancesContract {
        /// Constructor that initializes the contract with initial supply
        #[ink(constructor)]
        pub fn new(existential_deposit: Balance, max_locks: u32) -> Self {
            let caller = Self::env().caller();
            Self {
                total_issuance: 0,
                active_issuance: 0,
                accounts: Mapping::default(),
                locks: Mapping::default(),
                existential_deposit,
                max_locks,
                owner: caller,
                dust_trap: None,
            }
        }

        /// Constructor with dust trap
        #[ink(constructor)]
        pub fn new_with_dust_trap(
            existential_deposit: Balance,
            max_locks: u32,
            dust_trap: AccountId,
        ) -> Self {
            let caller = Self::env().caller();
            Self {
                total_issuance: 0,
                active_issuance: 0,
                accounts: Mapping::default(),
                locks: Mapping::default(),
                existential_deposit,
                max_locks,
                owner: caller,
                dust_trap: Some(dust_trap),
            }
        }

        /// Default constructor
        #[ink(constructor)]
        pub fn default() -> Self {
            Self::new(1, 10)
        }

        /// Get the total token supply
        #[ink(message)]
        pub fn total_issuance(&self) -> Balance {
            self.total_issuance
        }

        /// Get the active issuance (total - deactivated)
        #[ink(message)]
        pub fn active_issuance(&self) -> Balance {
            self.active_issuance
        }

        /// Get the existential deposit
        #[ink(message)]
        pub fn existential_deposit(&self) -> Balance {
            self.existential_deposit
        }

        /// Get the minimum balance (same as existential deposit)
        #[ink(message)]
        pub fn minimum_balance(&self) -> Balance {
            self.existential_deposit
        }

        /// Get account data for an account
        #[ink(message)]
        pub fn account(&self, who: AccountId) -> AccountData {
            self.accounts.get(who).unwrap_or_default()
        }

        /// Get the free balance of an account
        #[ink(message)]
        pub fn free_balance(&self, who: AccountId) -> Balance {
            self.account(who).free
        }

        /// Get balance (same as free_balance for compatibility)
        #[ink(message)]
        pub fn balance(&self, who: AccountId) -> Balance {
            self.free_balance(who)
        }

        /// Get the reserved balance of an account
        #[ink(message)]
        pub fn reserved_balance(&self, who: AccountId) -> Balance {
            self.account(who).reserved
        }

        /// Get the total balance (free + reserved) of an account
        #[ink(message)]
        pub fn total_balance(&self, who: AccountId) -> Balance {
            let account = self.account(who);
            account.free.saturating_add(account.reserved)
        }

        /// Get usable balance (free - frozen)
        #[ink(message)]
        pub fn usable_balance(&self, who: AccountId) -> Balance {
            let account = self.account(who);
            account.free.saturating_sub(account.frozen)
        }

        /// Create a pair of matching credit and debt imbalances
        /// This is useful for operations that need to temporarily adjust balances
        #[ink(message)]
        pub fn pair(&self, amount: Balance) -> Result<(CreditImbalance, DebtImbalance)> {
            if amount == 0 {
                return Ok((CreditImbalance { amount: 0 }, DebtImbalance { amount: 0 }));
            }

            // Check if creating this credit would overflow total_issuance
            self.total_issuance
                .checked_add(amount)
                .ok_or(Error::Overflow)?;

            Ok((CreditImbalance { amount }, DebtImbalance { amount }))
        }

        /// Resolve a credit imbalance by depositing into an account
        #[ink(message)]
        pub fn resolve_credit(&mut self, who: AccountId, credit: CreditImbalance) -> Result<()> {
            if credit.amount == 0 {
                return Ok(());
            }

            // The credit represents tokens that should be added to total issuance
            self.mint(who, credit.amount)
        }

        /// Settle a debt imbalance by withdrawing from an account
        #[ink(message)]
        pub fn settle_debt(
            &mut self,
            who: AccountId,
            debt: DebtImbalance,
            preservation: Preservation,
        ) -> Result<CreditImbalance> {
            if debt.amount == 0 {
                return Ok(CreditImbalance { amount: 0 });
            }

            // Try to burn the debt amount
            let burned = self.burn_from(
                who,
                debt.amount,
                preservation,
                Precision::BestEffort,
                Fortitude::Polite,
            )?;

            // If we couldn't burn the full amount, return the unburned portion as credit
            let remaining = debt.amount.saturating_sub(burned);
            Ok(CreditImbalance { amount: remaining })
        }

        /// Get reducible balance considering preservation mode
        #[ink(message)]
        pub fn reducible_balance(
            &self,
            who: AccountId,
            preservation: Preservation,
            _force: Fortitude,
        ) -> Balance {
            let account = self.account(who);
            let usable = account.free.saturating_sub(account.frozen);

            match preservation {
                Preservation::Expendable => usable,
                Preservation::Preserve | Preservation::Protect => {
                    usable.saturating_sub(self.existential_deposit)
                }
            }
        }

        /// Check if a deposit can be made
        #[ink(message)]
        pub fn can_deposit(
            &self,
            who: AccountId,
            amount: Balance,
            _provenance: Provenance,
        ) -> DepositConsequence {
            if amount == 0 {
                return DepositConsequence::Success;
            }

            let account = self.account(who);

            // Check if this would cause overflow
            if let Some(new_balance) = account.free.checked_add(amount) {
                if let Some(_new_total) = self.total_issuance.checked_add(amount) {
                    // Check minimum balance for new accounts
                    if account.free == 0 && new_balance < self.existential_deposit {
                        return DepositConsequence::BelowMinimum;
                    }
                    DepositConsequence::Success
                } else {
                    DepositConsequence::Overflow
                }
            } else {
                DepositConsequence::Overflow
            }
        }

        /// Check if a withdrawal can be made
        #[ink(message)]
        pub fn can_withdraw(&self, who: AccountId, amount: Balance) -> WithdrawConsequence {
            if amount == 0 {
                return WithdrawConsequence::Success;
            }

            let account = self.account(who);
            let usable = account.free.saturating_sub(account.frozen);

            if usable < amount {
                return WithdrawConsequence::BalanceLow;
            }

            let new_balance = match account.free.checked_sub(amount) {
                Some(b) => b,
                None => return WithdrawConsequence::BalanceLow,
            };

            if new_balance < self.existential_deposit && new_balance > 0 {
                return WithdrawConsequence::ReducedToZero(new_balance);
            }

            WithdrawConsequence::Success
        }

        /// Write balance directly, returning any dust that was removed
        /// This is a low-level operation that bypasses normal checks
        #[ink(message)]
        pub fn write_balance(
            &mut self,
            who: AccountId,
            amount: Balance,
        ) -> Result<Option<Balance>> {
            let caller = self.env().caller();
            if caller != self.owner {
                return Err(Error::NotAllowed);
            }

            let mut account = self.account(who);
            let old_balance = account.free;

            // Check if new balance is below existential deposit
            if amount > 0 && amount < self.existential_deposit {
                // Reap the account and return the dust
                let dust = amount;
                account.free = 0;

                // Update total issuance
                if old_balance > amount {
                    self.total_issuance = self
                        .total_issuance
                        .saturating_sub(old_balance.saturating_sub(amount));
                    self.active_issuance = self
                        .active_issuance
                        .saturating_sub(old_balance.saturating_sub(amount));
                } else {
                    let diff = amount.saturating_sub(old_balance);
                    self.total_issuance = self.total_issuance.saturating_add(diff);
                    self.active_issuance = self.active_issuance.saturating_add(diff);
                }

                self.accounts.insert(who, &account);
                return Ok(Some(dust));
            }

            // Set the new balance
            account.free = amount;

            // Update total issuance based on the difference
            if old_balance > amount {
                let diff = old_balance.saturating_sub(amount);
                self.total_issuance = self.total_issuance.saturating_sub(diff);
                self.active_issuance = self.active_issuance.saturating_sub(diff);
            } else {
                let diff = amount.saturating_sub(old_balance);
                self.total_issuance = self
                    .total_issuance
                    .checked_add(diff)
                    .ok_or(Error::Overflow)?;
                self.active_issuance = self
                    .active_issuance
                    .checked_add(diff)
                    .ok_or(Error::Overflow)?;
            }

            self.accounts.insert(who, &account);
            Ok(None)
        }

        /// Decrease balance (Unbalanced trait equivalent)
        #[ink(message)]
        pub fn decrease_balance(
            &mut self,
            who: AccountId,
            amount: Balance,
            precision: Precision,
            preservation: Preservation,
            fortitude: Fortitude,
        ) -> Result<Balance> {
            self.burn_from(who, amount, preservation, precision, fortitude)
        }

        /// Increase balance (Unbalanced trait equivalent)
        #[ink(message)]
        pub fn increase_balance(
            &mut self,
            who: AccountId,
            amount: Balance,
            precision: Precision,
        ) -> Result<Balance> {
            if amount == 0 {
                return Ok(0);
            }

            let mut account = self.account(who);

            // Check minimum balance for new accounts
            if account.free == 0 && amount < self.existential_deposit {
                return match precision {
                    Precision::Exact => Err(Error::ExistentialDeposit),
                    Precision::BestEffort => Ok(0),
                };
            }

            // Check for overflow
            let new_balance = match account.free.checked_add(amount) {
                Some(b) => b,
                None => {
                    return match precision {
                        Precision::Exact => Err(Error::Overflow),
                        Precision::BestEffort => {
                            // Saturate at max value
                            let actual = Balance::MAX.saturating_sub(account.free);
                            account.free = Balance::MAX;
                            self.total_issuance = self.total_issuance.saturating_add(actual);
                            self.active_issuance = self.active_issuance.saturating_add(actual);
                            self.accounts.insert(who, &account);
                            Ok(actual)
                        }
                    };
                }
            };

            // Check total issuance overflow
            if self.total_issuance.checked_add(amount).is_none() {
                return match precision {
                    Precision::Exact => Err(Error::Overflow),
                    Precision::BestEffort => {
                        let actual = Balance::MAX.saturating_sub(self.total_issuance);
                        account.free = account.free.saturating_add(actual);
                        self.total_issuance = Balance::MAX;
                        self.active_issuance = self.active_issuance.saturating_add(actual);
                        self.accounts.insert(who, &account);
                        Ok(actual)
                    }
                };
            }

            account.free = new_balance;
            self.total_issuance = self.total_issuance.saturating_add(amount);
            self.active_issuance = self.active_issuance.saturating_add(amount);
            self.accounts.insert(who, &account);

            self.env().emit_event(Endowed {
                account: who,
                free_balance: account.free,
            });

            Ok(amount)
        }

        /// Set total issuance directly (low-level operation)
        #[ink(message)]
        pub fn set_total_issuance(&mut self, amount: Balance) -> Result<()> {
            let caller = self.env().caller();
            if caller != self.owner {
                return Err(Error::NotAllowed);
            }

            let old_total = self.total_issuance;
            self.total_issuance = amount;

            // Adjust active issuance proportionally, or set it equal if starting from zero
            if old_total == 0 {
                self.active_issuance = amount;
            } else {
                // Keep the same ratio of active to total, or cap at new total
                self.active_issuance = self.active_issuance.min(amount);
            }

            Ok(())
        }

        /// Deactivate some issuance
        /// This removes the amount from active circulation but keeps it in total issuance
        #[ink(message)]
        pub fn deactivate(&mut self, amount: Balance) -> Result<()> {
            let caller = self.env().caller();
            if caller != self.owner {
                return Err(Error::NotAllowed);
            }

            // Saturating subtraction - can't go below zero
            self.active_issuance = self.active_issuance.saturating_sub(amount);
            Ok(())
        }

        /// Reactivate some issuance
        /// This adds the amount back to active circulation, capped at total issuance
        #[ink(message)]
        pub fn reactivate(&mut self, amount: Balance) -> Result<()> {
            let caller = self.env().caller();
            if caller != self.owner {
                return Err(Error::NotAllowed);
            }

            // Add to active issuance but cap at total issuance
            self.active_issuance = self
                .active_issuance
                .saturating_add(amount)
                .min(self.total_issuance);
            Ok(())
        }

        /// Mint new tokens to an account (only owner)
        #[ink(message)]
        pub fn mint(&mut self, to: AccountId, amount: Balance) -> Result<()> {
            let caller = self.env().caller();
            if caller != self.owner {
                return Err(Error::NotAllowed);
            }

            self.mint_into(to, amount)
        }

        /// Internal mint function
        fn mint_into(&mut self, to: AccountId, amount: Balance) -> Result<()> {
            if amount == 0 {
                return Ok(());
            }

            self.total_issuance = self
                .total_issuance
                .checked_add(amount)
                .ok_or(Error::Overflow)?;
            self.active_issuance = self
                .active_issuance
                .checked_add(amount)
                .ok_or(Error::Overflow)?;

            let mut account = self.account(to);

            // Check minimum balance for new accounts
            if account.free == 0 && amount < self.existential_deposit {
                self.total_issuance = self.total_issuance.saturating_sub(amount);
                self.active_issuance = self.active_issuance.saturating_sub(amount);
                return Err(Error::ExistentialDeposit);
            }

            account.free = account.free.checked_add(amount).ok_or(Error::Overflow)?;

            self.accounts.insert(to, &account);

            self.env().emit_event(Endowed {
                account: to,
                free_balance: account.free,
            });

            Ok(())
        }

        /// Burn tokens from an account
        #[ink(message)]
        pub fn burn_from(
            &mut self,
            who: AccountId,
            amount: Balance,
            preservation: Preservation,
            precision: Precision,
            force: Fortitude,
        ) -> Result<Balance> {
            if amount == 0 {
                return Ok(0);
            }

            let mut account = self.account(who);
            let reducible = self.reducible_balance(who, preservation, force);

            let actual_burn = match precision {
                Precision::Exact => {
                    if reducible < amount {
                        // Check if this is due to preservation requirements
                        let usable = account.free.saturating_sub(account.frozen);
                        if usable >= amount {
                            // We have the balance, but preservation prevents it
                            return Err(Error::Expendability);
                        }
                        return Err(Error::InsufficientBalance);
                    }
                    amount
                }
                Precision::BestEffort => amount.min(reducible),
            };

            if actual_burn == 0 {
                return Ok(0);
            }

            // Check if the burn would violate preservation BEFORE doing it
            let new_balance = account
                .free
                .checked_sub(actual_burn)
                .ok_or(Error::InsufficientBalance)?;

            if new_balance < self.existential_deposit && new_balance > 0 {
                match preservation {
                    Preservation::Expendable => {
                        // Will handle dust after burn
                    }
                    Preservation::Preserve | Preservation::Protect => {
                        return Err(Error::Expendability);
                    }
                }
            }

            account.free = new_balance;

            // Handle dust for Expendable case
            if account.free < self.existential_deposit && account.free > 0 {
                self.handle_dust(who, &mut account)?;
            }

            self.total_issuance = self.total_issuance.saturating_sub(actual_burn);
            self.active_issuance = self.active_issuance.saturating_sub(actual_burn);
            self.accounts.insert(who, &account);

            self.env().emit_event(Burned {
                who,
                amount: actual_burn,
            });

            Ok(actual_burn)
        }

        /// Restore balance (mint without ED check, typically used for system operations)
        #[ink(message)]
        pub fn restore(&mut self, who: AccountId, amount: Balance) -> Result<()> {
            if amount == 0 {
                return Ok(());
            }

            let mut account = self.account(who);

            // Check minimum balance for new accounts
            if account.free == 0 && amount < self.existential_deposit {
                return Err(Error::ExistentialDeposit);
            }

            self.total_issuance = self
                .total_issuance
                .checked_add(amount)
                .ok_or(Error::Overflow)?;
            self.active_issuance = self
                .active_issuance
                .checked_add(amount)
                .ok_or(Error::Overflow)?;

            account.free = account.free.checked_add(amount).ok_or(Error::Overflow)?;

            self.accounts.insert(who, &account);

            self.env().emit_event(Restored { who, amount });

            Ok(())
        }

        /// Shelve balance (burn without affecting total issuance tracking)
        #[ink(message)]
        pub fn shelve(&mut self, who: AccountId, amount: Balance) -> Result<()> {
            if amount == 0 {
                return Ok(());
            }

            let mut account = self.account(who);

            if account.free < amount {
                return Err(Error::InsufficientBalance);
            }

            account.free = account
                .free
                .checked_sub(amount)
                .ok_or(Error::InsufficientBalance)?;

            self.total_issuance = self.total_issuance.saturating_sub(amount);
            self.active_issuance = self.active_issuance.saturating_sub(amount);
            self.accounts.insert(who, &account);

            self.env().emit_event(Shelved { who, amount });

            Ok(())
        }

        /// Set balance directly (combines mint/burn as needed)
        #[ink(message)]
        pub fn set_balance(&mut self, who: AccountId, amount: Balance) -> Balance {
            let mut account = self.account(who);
            let current = account.free;

            if amount == current {
                return amount;
            }

            if amount > current {
                // Mint
                let to_mint = amount.saturating_sub(current);
                if let Some(new_issuance) = self.total_issuance.checked_add(to_mint) {
                    if let Some(new_balance) = account.free.checked_add(to_mint) {
                        self.total_issuance = new_issuance;
                        self.active_issuance = self.active_issuance.saturating_add(to_mint);
                        account.free = new_balance;
                        self.accounts.insert(who, &account);
                        return new_balance;
                    }
                }
            } else {
                // Burn
                let to_burn = current.saturating_sub(amount);
                if let Some(new_balance) = account.free.checked_sub(to_burn) {
                    self.total_issuance = self.total_issuance.saturating_sub(to_burn);
                    self.active_issuance = self.active_issuance.saturating_sub(to_burn);
                    account.free = new_balance;
                    self.accounts.insert(who, &account);
                    return new_balance;
                }
            }

            current
        }

        /// Transfer tokens from caller to another account
        #[ink(message)]
        pub fn transfer(&mut self, to: AccountId, amount: Balance) -> Result<()> {
            let from = self.env().caller();
            self.do_transfer(from, to, amount, Preservation::Expendable)
        }

        /// Transfer keeping the sender alive (won't go below ED)
        #[ink(message)]
        pub fn transfer_keep_alive(&mut self, to: AccountId, amount: Balance) -> Result<()> {
            let from = self.env().caller();
            self.do_transfer(from, to, amount, Preservation::Preserve)
        }

        /// Transfer with explicit preservation mode
        #[ink(message)]
        pub fn transfer_with_preservation(
            &mut self,
            to: AccountId,
            amount: Balance,
            preservation: Preservation,
        ) -> Result<()> {
            let from = self.env().caller();
            self.do_transfer(from, to, amount, preservation)
        }

        /// Internal transfer function
        fn do_transfer(
            &mut self,
            from: AccountId,
            to: AccountId,
            amount: Balance,
            preservation: Preservation,
        ) -> Result<()> {
            if amount == 0 {
                return Ok(());
            }

            let mut from_account = self.account(from);
            let mut to_account = self.account(to);

            // Check if sender has enough usable balance
            let usable = from_account.free.saturating_sub(from_account.frozen);
            if usable < amount {
                return Err(Error::LiquidityRestrictions);
            }

            // Check preservation mode
            match preservation {
                Preservation::Preserve | Preservation::Protect => {
                    let new_from_balance = from_account
                        .free
                        .checked_sub(amount)
                        .ok_or(Error::InsufficientBalance)?;
                    if new_from_balance < self.existential_deposit {
                        return Err(Error::Expendability);
                    }
                }
                Preservation::Expendable => {
                    // Allow going to zero
                }
            }

            // Perform transfer
            from_account.free = from_account
                .free
                .checked_sub(amount)
                .ok_or(Error::InsufficientBalance)?;
            to_account.free = to_account.free.checked_add(amount).ok_or(Error::Overflow)?;

            // Handle dust
            if from_account.free < self.existential_deposit && from_account.free > 0 {
                match preservation {
                    Preservation::Expendable => {
                        self.handle_dust(from, &mut from_account)?;
                    }
                    Preservation::Preserve | Preservation::Protect => {
                        // This shouldn't happen due to earlier check, but be safe
                        return Err(Error::Expendability);
                    }
                }
            }

            self.accounts.insert(from, &from_account);
            self.accounts.insert(to, &to_account);

            self.env().emit_event(Transfer {
                from: Some(from),
                to: Some(to),
                value: amount,
            });

            Ok(())
        }

        /// Handle dust collection
        fn handle_dust(&mut self, who: AccountId, account: &mut AccountData) -> Result<()> {
            let dust_amount = account.free;

            if let Some(dust_trap) = self.dust_trap {
                // Transfer dust to dust trap
                let mut trap_account = self.account(dust_trap);
                trap_account.free = trap_account
                    .free
                    .checked_add(dust_amount)
                    .ok_or(Error::Overflow)?;
                self.accounts.insert(dust_trap, &trap_account);
                account.free = 0;
            } else {
                // Remove dust from total issuance
                self.env().emit_event(DustLost {
                    account: who,
                    amount: dust_amount,
                });
                self.total_issuance = self.total_issuance.saturating_sub(dust_amount);
                self.active_issuance = self.active_issuance.saturating_sub(dust_amount);
                account.free = 0;
            }

            Ok(())
        }

        /// Reserve some balance from an account
        #[ink(message)]
        pub fn reserve(&mut self, who: AccountId, amount: Balance) -> Result<()> {
            if amount == 0 {
                return Ok(());
            }

            let mut account = self.account(who);
            let usable = account.free.saturating_sub(account.frozen);

            if usable < amount {
                return Err(Error::InsufficientBalance);
            }

            account.free = account
                .free
                .checked_sub(amount)
                .ok_or(Error::InsufficientBalance)?;
            account.reserved = account
                .reserved
                .checked_add(amount)
                .ok_or(Error::Overflow)?;

            self.accounts.insert(who, &account);

            self.env().emit_event(Reserved { who, amount });

            Ok(())
        }

        /// Unreserve some balance for an account
        #[ink(message)]
        pub fn unreserve(&mut self, who: AccountId, amount: Balance) -> Result<Balance> {
            if amount == 0 {
                return Ok(0);
            }

            let mut account = self.account(who);
            let actual = amount.min(account.reserved);

            account.reserved = account.reserved.saturating_sub(actual);
            account.free = account.free.checked_add(actual).ok_or(Error::Overflow)?;

            self.accounts.insert(who, &account);

            self.env().emit_event(Unreserved {
                who,
                amount: actual,
            });

            Ok(actual)
        }

        /// Set a lock on an account
        #[ink(message)]
        pub fn set_lock(&mut self, who: AccountId, id: [u8; 8], amount: Balance) -> Result<()> {
            let mut locks = self.locks.get(who).unwrap_or_default();

            // Find existing lock or add new one
            let mut found = false;
            for lock in locks.iter_mut() {
                if lock.id == id {
                    lock.amount = amount;
                    found = true;
                    break;
                }
            }

            if !found {
                if locks.len() >= self.max_locks as usize {
                    return Err(Error::TooManyLocks);
                }
                locks.push(BalanceLock { id, amount });
            }

            // Update frozen amount
            let max_lock = locks.iter().map(|l| l.amount).max().unwrap_or(0);
            let mut account = self.account(who);
            let old_frozen = account.frozen;
            account.frozen = max_lock;

            self.locks.insert(who, &locks);
            self.accounts.insert(who, &account);

            if account.frozen > old_frozen {
                self.env().emit_event(Locked {
                    who,
                    amount: account.frozen.saturating_sub(old_frozen),
                });
            }

            Ok(())
        }

        /// Remove a lock from an account
        #[ink(message)]
        pub fn remove_lock(&mut self, who: AccountId, id: [u8; 8]) -> Result<()> {
            let mut locks = self.locks.get(who).unwrap_or_default();
            locks.retain(|lock| lock.id != id);

            let max_lock = locks.iter().map(|l| l.amount).max().unwrap_or(0);
            let mut account = self.account(who);
            let old_frozen = account.frozen;
            account.frozen = max_lock;

            if locks.is_empty() {
                self.locks.remove(who);
            } else {
                self.locks.insert(who, &locks);
            }
            self.accounts.insert(who, &account);

            if old_frozen > account.frozen {
                self.env().emit_event(Unlocked {
                    who,
                    amount: old_frozen.saturating_sub(account.frozen),
                });
            }

            Ok(())
        }

        /// Set the dust trap account
        #[ink(message)]
        pub fn set_dust_trap(&mut self, dust_trap: Option<AccountId>) -> Result<()> {
            let caller = self.env().caller();
            if caller != self.owner {
                return Err(Error::NotAllowed);
            }
            self.dust_trap = dust_trap;
            Ok(())
        }

        /// Get the dust trap account
        #[ink(message)]
        pub fn dust_trap(&self) -> Option<AccountId> {
            self.dust_trap
        }
    }

    // Non-inline module declarations inside the procedural macro are forbidden, so we `include!` our tests.
    #[cfg(test)]
    mod tests {
        use super::*;
        use ink::env::test;

        #[cfg(windows)]
        include!("conformance_tests\\inspect_mutate.in.rs");
        #[cfg(windows)]
        include!("conformance_tests\\regular_balanced.in.rs");
        #[cfg(windows)]
        include!("conformance_tests\\regular_mutate.in.rs");
        #[cfg(windows)]
        include!("conformance_tests\\regular_unbalanced.in.rs");

        #[cfg(not(windows))]
        include!("conformance_tests/inspect_mutate.in.rs");
        #[cfg(not(windows))]
        include!("conformance_tests/regular_balanced.in.rs");
        #[cfg(not(windows))]
        include!("conformance_tests/regular_mutate.in.rs");
        #[cfg(not(windows))]
        include!("conformance_tests/regular_unbalanced.in.rs");
    }
}
