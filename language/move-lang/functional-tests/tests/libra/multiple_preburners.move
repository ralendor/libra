// Test the end-to-end preburn-burn flow with two different preburners (alice and bob) that are
// distinct from the burner (the association). Use a third, non-privileged account (carol) to check
// that only preburners can preburn and only the associaton can burn.

//! account: alice, 0Coin1
//! account: bob, 0Coin1
//! account: carol, 0Coin1
//! account: dawn, 0Coin2

// allocate funds to alice, bob and carol
//! sender: association
//! max-gas: 1000000
//! gas-price: 0
script {
use 0x0::Coin1;
use 0x0::Libra;
use 0x0::LibraAccount;
fun main(account: &signer) {
    LibraAccount::deposit(account, {{alice}}, Libra::mint<Coin1::T>(account, 200));
    LibraAccount::deposit(account, {{bob}}, Libra::mint<Coin1::T>(account, 200));
    LibraAccount::deposit(account, {{carol}}, Libra::mint<Coin1::T>(account, 200));
}
}

// check: EXECUTED

// publish preburn resource to alice's account
//! new-transaction
//! sender: alice
//! max-gas: 1000000
//! gas-price: 0
//! gas-currency: Coin1
script {
use 0x0::Coin1;
use 0x0::Libra;
fun main(account: &signer) {
    Libra::publish_preburn(account, Libra::new_preburn<Coin1::T>())
}
}

// check: EXECUTED

// perform a preburn of 100 from alice's account
//! new-transaction
//! sender: alice
//! max-gas: 1000000
//! gas-price: 0
//! gas-currency: Coin1
script {
use 0x0::LibraAccount;
use 0x0::Coin1;
use 0x0::Libra;
use 0x0::Transaction;
fun main(account: &signer) {
    let coin = LibraAccount::withdraw_from<Coin1::T>(account, 100);
    Libra::preburn_to<Coin1::T>(account, coin);
    Transaction::assert(Libra::preburn_value<Coin1::T>() == 100, 8001)
}
}

// check: PreburnEvent
// check: EXECUTED

// preburn resource to bob's account
//! new-transaction
//! sender: bob
//! max-gas: 1000000
//! gas-price: 0
//! gas-currency: Coin1
script {
use 0x0::Coin1;
use 0x0::Libra;
fun main(account: &signer) {
    Libra::publish_preburn(account, Libra::new_preburn<Coin1::T>())
}
}

// check: EXECUTED

// perform a preburn of 200 from bob's account
//! new-transaction
//! sender: bob
//! max-gas: 1000000
//! gas-price: 0
//! gas-currency: Coin1
script {
use 0x0::LibraAccount;
use 0x0::Coin1;
use 0x0::Libra;
use 0x0::Transaction;
fun main(account: &signer) {
    let coin = LibraAccount::withdraw_from<Coin1::T>(account, 200);
    Libra::preburn_to<Coin1::T>(account, coin);
    Transaction::assert(Libra::preburn_value<Coin1::T>() == 300, 8002)
}
}

// check: PreburnEvent
// check: EXECUTED

// ensure that the non-privileged user carol cannot preburn.
// will fail with MISSING_DATA because sender doesn't have a Preburn resource
//! new-transaction
//! sender: carol
//! max-gas: 1000000
//! gas-price: 0
//! gas-currency: Coin1
script {
use 0x0::LibraAccount;
use 0x0::Coin1;
use 0x0::Libra;
fun main(account: &signer) {
    let coin = LibraAccount::withdraw_from<Coin1::T>(account, 200);
    Libra::preburn_to<Coin1::T>(account, coin);
}
}

// check: Keep
// check: MISSING_DATA

// ensure that the non-privileged user carol cannot burn.
// will fail with MISSING_DATA because sender doesn't have the mint capability
//! new-transaction
//! sender: carol
//! max-gas: 1000000
//! gas-price: 0
//! gas-currency: Coin1
script {
use 0x0::Coin1;
use 0x0::Libra;
fun main(account: &signer) {
    Libra::burn<Coin1::T>(account, {{bob}})
}
}

// check: Keep
// check: MISSING_DATA

// ensure that the preburner bob cannot burn
//! new-transaction
//! sender: bob
//! max-gas: 1000000
//! gas-price: 0
//! gas-currency: Coin1
script {
use 0x0::Coin1;
use 0x0::Libra;
fun main(account: &signer) {
    Libra::burn<Coin1::T>(account, {{bob}})
}
}

// check: Keep
// check: MISSING_DATA

// burn bob's funds, then alice's
//! new-transaction
//! sender: blessed
//! max-gas: 1000000
//! gas-price: 0
script {
use 0x0::Coin1;
use 0x0::Libra;
use 0x0::Transaction;
fun main(account: &signer) {
    Libra::burn<Coin1::T>(account, {{bob}});
    Transaction::assert(Libra::preburn_value<Coin1::T>() == 100, 8003);
    Libra::burn<Coin1::T>(account, {{alice}});
    Transaction::assert(Libra::preburn_value<Coin1::T>() == 0, 8004)
}
}

// check: BurnEvent
// check: EXECUTED

// now, we will initiate a burn request from alice and have the association cancel/return it.
//! new-transaction
//! sender: alice
//! max-gas: 1000000
//! gas-price: 0
//! gas-currency: Coin1
script {
use 0x0::LibraAccount;
use 0x0::Coin1;
use 0x0::Libra;
use 0x0::Transaction;
fun main(account: &signer) {
    let coin = LibraAccount::withdraw_from<Coin1::T>(account, 100);
    Libra::preburn_to<Coin1::T>(account, coin);
    Transaction::assert(Libra::preburn_value<Coin1::T>() == 100, 8005)
}
}

// check: EXECUTED

// cancel Alice's request and return her funds
//! new-transaction
//! sender: blessed
//! max-gas: 1000000
//! gas-price: 0
script {
use 0x0::LibraAccount;
use 0x0::Coin1;
use 0x0::Libra;
use 0x0::Transaction;
fun main(account: &signer) {
    let old_balance = LibraAccount::balance<Coin1::T>({{alice}});
    LibraAccount::cancel_burn<Coin1::T>(account, {{alice}});
    Transaction::assert(Libra::preburn_value<Coin1::T>() == 0, 8006);
    Transaction::assert(LibraAccount::balance<Coin1::T>({{alice}}) == old_balance + 100, 8007)
}
}

// check: CancelBurnEvent
// check: EXECUTED

//! new-transaction
//! sender: blessed
//! max-gas: 1000000
script {
use 0x0::Coin2;
use 0x0::LibraAccount;
fun main(account: &signer) {
    LibraAccount::mint_to_address<Coin2::T>(account, {{dawn}}, 200);
}
}
// check: EXECUTED

// publish preburn resource for Coin2 to alice's account
//! new-transaction
//! sender: dawn
//! max-gas: 1000000
//! gas-currency: Coin2
script {
use 0x0::Coin2;
use 0x0::Libra;
use 0x0::LibraAccount;
fun main(account: &signer) {
    Libra::publish_preburn(account, Libra::new_preburn<Coin2::T>());
    let coin = LibraAccount::withdraw_from<Coin2::T>(account, 100);
    Libra::preburn_to<Coin2::T>(account, coin);
}
}

// Try to destroy the preburn, but it will fail since there is an
// outstanding preburn request.
//! new-transaction
//! sender: dawn
//! max-gas: 1000000
//! gas-currency: Coin2
script {
use 0x0::Coin2;
use 0x0::Libra;
fun main(account: &signer) {
    Libra::destroy_preburn(
        Libra::remove_preburn<Coin2::T>(account)
    );
}
}
// check: NATIVE_FUNCTION_ERROR
// check: 3

//! new-transaction
//! sender: blessed
//! max-gas: 1000000
script {
use 0x0::Coin2;
use 0x0::LibraAccount;
fun main(account: &signer) {
    LibraAccount::cancel_burn<Coin2::T>(account, {{dawn}});
}
}
// check: EXECUTED

// Now destroy the preburn
//! new-transaction
//! sender: dawn
//! max-gas: 1000000
//! gas-currency: Coin2
script {
use 0x0::Coin2;
use 0x0::Libra;
fun main(account: &signer) {
    Libra::destroy_preburn(
        Libra::remove_preburn<Coin2::T>(account)
    );
}
}
// check: EXECUTED
