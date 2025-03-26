module MyModule::GamifiedStaking {
    use std::signer;
    use std::error;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    const EALREADY_INITIALIZED: u64 = 1;
    const ESTAKE_NOT_FOUND: u64 = 2;
    const EINSUFFICIENT_BALANCE: u64 = 3;

    struct Stake has key {
        total_staked: u64,
    }

    struct StakingPool has key {
        coins: coin::Coin<AptosCoin>,
    }

    // Initialize stake for a user
    public entry fun init_stake(user: &signer) {
        let user_addr = signer::address_of(user);
        if (!exists<Stake>(user_addr)) {
            move_to(user, Stake { total_staked: 0 });
        };
    }

    // Initialize staking pool
    public entry fun init_pool(owner: &signer) {
        let owner_addr = signer::address_of(owner);
        if (!exists<StakingPool>(owner_addr)) {
            move_to(owner, StakingPool { coins: coin::zero<AptosCoin>() });
        };
    }

    // Function to stake tokens
    public entry fun stake_tokens(user: &signer, amount: u64) 
    acquires Stake, StakingPool {
        let user_addr = signer::address_of(user);
        let pool_addr = signer::address_of(user); // Using same account for pool
        
        assert!(coin::balance<AptosCoin>(user_addr) >= amount, 
            error::invalid_argument(EINSUFFICIENT_BALANCE));
        
        if (!exists<Stake>(user_addr)) {
            move_to(user, Stake { total_staked: 0 });
        };

        let stake_ref = borrow_global_mut<Stake>(user_addr);
        stake_ref.total_staked = stake_ref.total_staked + amount;

        let coins = coin::withdraw<AptosCoin>(user, amount);
        let pool_ref = borrow_global_mut<StakingPool>(pool_addr);
        coin::merge(&mut pool_ref.coins, coins);
    }

    // Function to claim rewards
    public entry fun claim_rewards(user: &signer) 
    acquires Stake, StakingPool {
        let user_addr = signer::address_of(user);
        let pool_addr = signer::address_of(user);
        
        assert!(exists<Stake>(user_addr), error::not_found(ESTAKE_NOT_FOUND));

        let stake = borrow_global<Stake>(user_addr);
        let reward = stake.total_staked / 10;
        
        let pool_ref = borrow_global_mut<StakingPool>(pool_addr);
        assert!(coin::value(&pool_ref.coins) >= reward, 
            error::invalid_argument(EINSUFFICIENT_BALANCE));

        let reward_coins = coin::extract(&mut pool_ref.coins, reward);
        coin::deposit<AptosCoin>(user_addr, reward_coins);
    }
}