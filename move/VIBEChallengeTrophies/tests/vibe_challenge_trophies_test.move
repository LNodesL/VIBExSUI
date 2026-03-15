#[test_only]
module vibe_challenge_trophies::vibe_challenge_trophies_test {
    use std::string;
    use vibe_challenge_trophies::vibe_challenge_trophies::{Self as trophies, Registry};
    use sui::test_scenario::{Self as scenario};

    #[test]
    fun test_create_registry_add_points_balance() {
        let owner = @0x1;
        let user_a = @0x2;
        let mut scenario_val = scenario::begin(owner);

        // Tx 1: owner creates shared Registry
        trophies::create_registry(scenario::ctx(&mut scenario_val));
        scenario::next_tx(&mut scenario_val, owner);

        // Tx 2: owner adds points to user_a with comment
        let mut registry = scenario::take_shared<Registry>(&scenario_val);
        trophies::add_points(
            &mut registry,
            user_a,
            100,
            string::utf8(b"CTF win"),
            scenario::ctx(&mut scenario_val),
        );
        scenario::return_shared(registry);
        scenario::next_tx(&mut scenario_val, owner);

        // Tx 3: anyone queries balance_of(user_a)
        let registry = scenario::take_shared<Registry>(&scenario_val);
        assert!(trophies::balance_of(&registry, user_a) == 100, 0);
        assert!(trophies::balance_of(&registry, @0x9) == 0, 1);
        scenario::return_shared(registry);
        scenario::next_tx(&mut scenario_val, user_a);

        // Tx 4: user_a checks my_balance
        let registry = scenario::take_shared<Registry>(&scenario_val);
        assert!(trophies::my_balance(&registry, scenario::ctx(&mut scenario_val)) == 100, 0);
        scenario::return_shared(registry);

        scenario::end(scenario_val);
    }

    #[test]
    fun test_add_points_batch() {
        let owner = @0x1;
        let a = @0xa;
        let b = @0xb;
        let mut scenario_val = scenario::begin(owner);

        trophies::create_registry(scenario::ctx(&mut scenario_val));
        scenario::next_tx(&mut scenario_val, owner);

        let mut users = std::vector::empty();
        std::vector::push_back(&mut users, a);
        std::vector::push_back(&mut users, b);
        let mut amounts = std::vector::empty();
        std::vector::push_back(&mut amounts, 50u64);
        std::vector::push_back(&mut amounts, 75u64);
        let mut comments = std::vector::empty();
        std::vector::push_back(&mut comments, string::utf8(b"Geoguessing"));
        std::vector::push_back(&mut comments, string::utf8(b"CTF"));

        let mut registry = scenario::take_shared<Registry>(&scenario_val);
        trophies::add_points_batch(
            &mut registry,
            &users,
            &amounts,
            &comments,
            scenario::ctx(&mut scenario_val),
        );
        scenario::return_shared(registry);
        scenario::next_tx(&mut scenario_val, owner);

        let registry = scenario::take_shared<Registry>(&scenario_val);
        assert!(trophies::balance_of(&registry, a) == 50, 0);
        assert!(trophies::balance_of(&registry, b) == 75, 1);
        scenario::return_shared(registry);

        scenario::end(scenario_val);
    }
}
