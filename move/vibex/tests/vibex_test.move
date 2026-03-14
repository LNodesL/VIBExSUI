#[test_only]
module vibex::vibex_test {
    use vibex::vibex::{Self, Vibex};
    use sui::test_scenario::{Self as scenario};

    #[test]
    fun test_vibex_value_and_increment() {
        let sender = @0x1;
        let mut scenario_val = scenario::begin(sender);

        // Tx 1: create and share Vibex
        vibex::new(42, std::string::utf8(b"test"), scenario::ctx(&mut scenario_val));
        scenario::next_tx(&mut scenario_val, sender);

        // Tx 2: read value
        let vibex = scenario::take_shared<Vibex>(&scenario_val);
        assert!(vibex::value(&vibex) == 42, 0);
        scenario::return_shared(vibex);
        scenario::next_tx(&mut scenario_val, sender);

        // Tx 3: increment and check
        let mut vibex = scenario::take_shared<Vibex>(&scenario_val);
        vibex::increment(&mut vibex);
        assert!(vibex::value(&vibex) == 43, 0);
        scenario::return_shared(vibex);

        scenario::end(scenario_val);
    }
}
