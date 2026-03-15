/// VIBE Challenge Trophies: non-transferable challenge points for CTF, Geoguessing, etc.
/// Owner can add points (single or batch) with optional ledger comments; anyone can query balance.
module vibe_challenge_trophies::vibe_challenge_trophies {

    use std::string::String;
    use sui::display;
    use sui::package::{Self as pkg, Publisher};
    use sui::table::{Self, Table};

    const ENotOwner: u64 = 1;
    const EBatchLengthMismatch: u64 = 2;

    /// One-time witness for claiming Publisher (module initializer).
    public struct VIBE_CHALLENGE_TROPHIES has drop {}

    /// Single ledger entry: amount added and optional comment.
    public struct LedgerEntry has store, drop {
        amount: u64,
        comment: String,
    }

    /// Per-address balance and history.
    public struct BalanceRecord has store {
        total: u64,
        entries: vector<LedgerEntry>,
    }

    /// Shared registry: owner + address -> BalanceRecord.
    public struct Registry has key {
        id: sui::object::UID,
        owner: address,
        balances: Table<address, BalanceRecord>,
    }

    /// Module init: claim Publisher and transfer to deployer for Display setup.
    fun init(otw: VIBE_CHALLENGE_TROPHIES, ctx: &mut TxContext) {
        pkg::claim_and_keep(otw, ctx);
    }

    /// Create the shared Registry; sender becomes owner. Call once after publish.
    public fun create_registry(ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        let balances = table::new<address, BalanceRecord>(ctx);
        let registry = Registry {
            id: sui::object::new(ctx),
            owner: sender,
            balances,
        };
        transfer::share_object(registry);
    }

    /// Add challenge points to one user with optional comment. Owner only; additive.
    public fun add_points(
        registry: &mut Registry,
        user: address,
        amount: u64,
        comment: String,
        ctx: &mut TxContext,
    ) {
        assert!(tx_context::sender(ctx) == registry.owner, ENotOwner);
        add_points_internal(registry, user, amount, comment);
    }

    /// Add points to multiple users in one tx. in one tx. Owner only. Vectors must have same length.
    public fun add_points_batch(
        registry: &mut Registry,
        users: &vector<address>,
        amounts: &vector<u64>,
        comments: &vector<String>,
        ctx: &mut TxContext,
    ) {
        assert!(tx_context::sender(ctx) == registry.owner, ENotOwner);
        let n = std::vector::length(users);
        assert!(std::vector::length(amounts) == n && std::vector::length(comments) == n, EBatchLengthMismatch);
        let mut i = 0u64;
        while (i < n) {
            let user = *std::vector::borrow(users, i);
            let amount = *std::vector::borrow(amounts, i);
            let comment = *std::vector::borrow(comments, i);
            add_points_internal(registry, user, amount, comment);
            i = i + 1;
        };
    }

    /// Internal: add amount and ledger entry for user.
    fun add_points_internal(registry: &mut Registry, user: address, amount: u64, comment: String) {
        let entry = LedgerEntry { amount, comment };
        if (table::contains(&registry.balances, user)) {
            let record = table::borrow_mut(&mut registry.balances, user);
            record.total = record.total + amount;
            std::vector::push_back(&mut record.entries, entry);
        } else {
            let mut entries = std::vector::empty();
            std::vector::push_back(&mut entries, entry);
            let record = BalanceRecord { total: amount, entries };
            table::add(&mut registry.balances, user, record);
        };
    }

    /// Read balance for any address; 0 if never awarded.
    public fun balance_of(registry: &Registry, user: address): u64 {
        if (table::contains(&registry.balances, user)) {
            table::borrow(&registry.balances, user).total
        } else {
            0
        }
    }

    /// Read balance for the transaction sender.
    public fun my_balance(registry: &Registry, ctx: &TxContext): u64 {
        balance_of(registry, tx_context::sender(ctx))
    }

    /// Create Display<Registry> for token-like metadata (name, image). Call with Publisher once after deploy.
    #[allow(lint(self_transfer))]
    public fun create_display_for_registry(pub: &Publisher, ctx: &mut TxContext) {
        let mut d = display::new<Registry>(pub, ctx);
        d.add(std::string::utf8(b"name"), std::string::utf8(b"VIBE Challenge Trophies"));
        d.add(std::string::utf8(b"description"), std::string::utf8(b"Non-transferable challenge points for CTF, Geoguessing & contests"));
        d.add(std::string::utf8(b"image_url"), std::string::utf8(b"https://vibe.example/trophies.png"));
        d.add(std::string::utf8(b"thumbnail_url"), std::string::utf8(b"https://vibe.example/trophies-thumb.png"));
        transfer::public_transfer(d, tx_context::sender(ctx));
    }
}
