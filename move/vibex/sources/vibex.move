module vibex::vibex {

    /// Minimal shared object: a counter and label for the VIBExSUI starter.
    public struct Vibex has key, store {
        id: UID,
        value: u64,
        label: std::string::String,
    }

    /// Create and share the initial Vibex object (e.g. call once after publish).
    public fun new(value: u64, label: std::string::String, ctx: &mut sui::tx_context::TxContext) {
        let vibex = Vibex {
            id: object::new(ctx),
            value,
            label,
        };
        transfer::share_object(vibex);
    }

    /// Increment the counter (takes a mutable reference to the shared object).
    public fun increment(self: &mut Vibex) {
        self.value = self.value + 1;
    }

    /// Get the current value.
    public fun value(self: &Vibex): u64 {
        self.value
    }
}
