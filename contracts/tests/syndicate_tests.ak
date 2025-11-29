use aiken/interval
use cardano/address
use cardano/assets
use cardano/transaction.{NoDatum, Output, OutputReference, Transaction}
use propfi/types.{
  AssetClass, ClaimRefund, Deposit, EscrowDatum, Finalize, Fundraising,
  InvestmentLimits, Lock, Locked, Refund, Refunded,
}
use validators/syndicate

// =============================================================================
// Mocks & Helpers
// =============================================================================

const mock_policy_id =
  #"11111111111111111111111111111111111111111111111111111111"

const mock_asset_name = #"5553444d"

// USDM

const mock_fraction_policy =
  #"22222222222222222222222222222222222222222222222222222222"

const mock_fraction_name = #"50524f504649"

// "PROPFI"

fn mock_limits() -> InvestmentLimits {
  InvestmentLimits {
    min_investment: 100,
    max_investment: 5000,
    max_percentage: 50,
  }
}

fn mock_datum() -> EscrowDatum {
  EscrowDatum {
    state: Fundraising,
    target: 10000,
    current_raised: 0,
    deadline: 100,
    investors: [],
    seller: #"00000000000000000000000000000000000000000000000000000001",
    stablecoin_asset: AssetClass {
      policy_id: mock_policy_id,
      asset_name: mock_asset_name,
    },
    fraction_token: AssetClass {
      policy_id: mock_fraction_policy,
      asset_name: mock_fraction_name,
    },
    duna_hash: #"",
    limits: mock_limits(),
  }
}

fn mock_datum_with_raised(raised: Int) -> EscrowDatum {
  EscrowDatum { ..mock_datum(), current_raised: raised }
}

fn mock_locked_datum() -> EscrowDatum {
  EscrowDatum {
    ..mock_datum(),
    state: Locked,
    current_raised: 10000,
    investors: [
      (#"00000000000000000000000000000000000000000000000000000002", 5000),
      (#"00000000000000000000000000000000000000000000000000000003", 5000),
    ],
  }
}

fn mock_refunded_datum() -> EscrowDatum {
  EscrowDatum {
    ..mock_datum(),
    state: Refunded,
    current_raised: 5000,
    investors: [
      (#"00000000000000000000000000000000000000000000000000000002", 3000),
      (#"00000000000000000000000000000000000000000000000000000003", 2000),
    ],
  }
}

fn mock_tx() -> Transaction {
  transaction.placeholder()
}

fn mock_utxo_ref() -> OutputReference {
  OutputReference { transaction_id: #"00", output_index: 0 }
}

// =============================================================================
// Deposit Tests
// =============================================================================

test deposit_success() {
  let datum = mock_datum()
  let redeemer = Deposit { amount: 1000 }

  // Mock output back to script with stablecoin
  let script_output =
    Output {
      address: address.from_script(#"00"),
      value: assets.from_asset(mock_policy_id, mock_asset_name, 1000),
      datum: NoDatum,
      reference_script: None,
    }

  // Set validity range before deadline
  let tx =
    Transaction {
      ..mock_tx(),
      outputs: [script_output],
      validity_range: interval.before(50),
    }

  syndicate.syndicate_escrow.spend(Some(datum), redeemer, mock_utxo_ref(), tx)
}

test deposit_fails_below_minimum() fail {
  let datum = mock_datum()
  // Amount below min_investment (100)
  let redeemer = Deposit { amount: 50 }

  let script_output =
    Output {
      address: address.from_script(#"00"),
      value: assets.from_asset(mock_policy_id, mock_asset_name, 50),
      datum: NoDatum,
      reference_script: None,
    }

  let tx =
    Transaction {
      ..mock_tx(),
      outputs: [script_output],
      validity_range: interval.before(50),
    }

  syndicate.syndicate_escrow.spend(Some(datum), redeemer, mock_utxo_ref(), tx)
}

test deposit_fails_above_maximum() fail {
  let datum = mock_datum()
  // Amount above max_investment (5000)
  let redeemer = Deposit { amount: 6000 }

  let script_output =
    Output {
      address: address.from_script(#"00"),
      value: assets.from_asset(mock_policy_id, mock_asset_name, 6000),
      datum: NoDatum,
      reference_script: None,
    }

  let tx =
    Transaction {
      ..mock_tx(),
      outputs: [script_output],
      validity_range: interval.before(50),
    }

  syndicate.syndicate_escrow.spend(Some(datum), redeemer, mock_utxo_ref(), tx)
}

test deposit_fails_exceeds_50_percent() fail {
  let datum = mock_datum()
  // 50% of 10000 target = 5000, so 5001 should fail
  let redeemer = Deposit { amount: 5001 }

  let script_output =
    Output {
      address: address.from_script(#"00"),
      value: assets.from_asset(mock_policy_id, mock_asset_name, 5001),
      datum: NoDatum,
      reference_script: None,
    }

  let tx =
    Transaction {
      ..mock_tx(),
      outputs: [script_output],
      validity_range: interval.before(50),
    }

  syndicate.syndicate_escrow.spend(Some(datum), redeemer, mock_utxo_ref(), tx)
}

// =============================================================================
// Lock Tests
// =============================================================================

test lock_success_when_target_met() {
  let datum = mock_datum_with_raised(10000)
  let redeemer = Lock

  let script_output =
    Output {
      address: address.from_script(#"00"),
      value: assets.from_asset(mock_policy_id, mock_asset_name, 10000),
      datum: NoDatum,
      reference_script: None,
    }

  let tx = Transaction { ..mock_tx(), outputs: [script_output] }

  syndicate.syndicate_escrow.spend(Some(datum), redeemer, mock_utxo_ref(), tx)
}

test lock_fails_when_target_not_met() fail {
  let datum = mock_datum_with_raised(5000)
  let redeemer = Lock

  let script_output =
    Output {
      address: address.from_script(#"00"),
      value: assets.from_asset(mock_policy_id, mock_asset_name, 5000),
      datum: NoDatum,
      reference_script: None,
    }

  let tx = Transaction { ..mock_tx(), outputs: [script_output] }

  syndicate.syndicate_escrow.spend(Some(datum), redeemer, mock_utxo_ref(), tx)
}

// =============================================================================
// Finalize Tests
// =============================================================================

test finalize_success() {
  let datum = mock_locked_datum()
  let redeemer = Finalize

  // Mock output to seller with sufficient funds
  let seller_output =
    Output {
      address: address.from_verification_key(datum.seller),
      value: assets.from_asset(mock_policy_id, mock_asset_name, 10000),
      datum: NoDatum,
      reference_script: None,
    }

  // Mock outputs to investors
  let investor1_output =
    Output {
      address: address.from_verification_key(
        #"00000000000000000000000000000000000000000000000000000002",
      ),
      value: assets.from_asset(mock_fraction_policy, mock_fraction_name, 500),
      datum: NoDatum,
      reference_script: None,
    }

  let investor2_output =
    Output {
      address: address.from_verification_key(
        #"00000000000000000000000000000000000000000000000000000003",
      ),
      value: assets.from_asset(mock_fraction_policy, mock_fraction_name, 500),
      datum: NoDatum,
      reference_script: None,
    }

  let tx =
    Transaction {
      ..mock_tx(),
      outputs: [seller_output, investor1_output, investor2_output],
    }

  syndicate.syndicate_escrow.spend(Some(datum), redeemer, mock_utxo_ref(), tx)
}

test finalize_fails_when_not_locked() fail {
  // Datum is in Fundraising state, not Locked
  let datum = mock_datum_with_raised(10000)
  let redeemer = Finalize

  let seller_output =
    Output {
      address: address.from_verification_key(datum.seller),
      value: assets.from_asset(mock_policy_id, mock_asset_name, 10000),
      datum: NoDatum,
      reference_script: None,
    }

  let tx = Transaction { ..mock_tx(), outputs: [seller_output] }

  syndicate.syndicate_escrow.spend(Some(datum), redeemer, mock_utxo_ref(), tx)
}

// =============================================================================
// Refund Tests
// =============================================================================

test refund_success() {
  let datum = mock_datum_with_raised(5000)
  let redeemer = Refund

  // Mock time after deadline
  let validity_range = interval.after(101)

  let tx = Transaction { ..mock_tx(), validity_range }

  syndicate.syndicate_escrow.spend(Some(datum), redeemer, mock_utxo_ref(), tx)
}

test refund_fails_before_deadline() fail {
  let datum = mock_datum_with_raised(5000)
  let redeemer = Refund

  // Time before deadline
  let validity_range = interval.after(50)

  let tx = Transaction { ..mock_tx(), validity_range }

  syndicate.syndicate_escrow.spend(Some(datum), redeemer, mock_utxo_ref(), tx)
}

// =============================================================================
// ClaimRefund Tests
// =============================================================================

test claim_refund_success() {
  let datum = mock_refunded_datum()
  let investor_pkh = #"00000000000000000000000000000000000000000000000000000002"
  let redeemer = ClaimRefund { investor: investor_pkh }

  // Output to investor with their refund
  let investor_output =
    Output {
      address: address.from_verification_key(investor_pkh),
      value: assets.from_asset(mock_policy_id, mock_asset_name, 3000),
      datum: NoDatum,
      reference_script: None,
    }

  let tx =
    Transaction {
      ..mock_tx(),
      outputs: [investor_output],
      extra_signatories: [investor_pkh],
    }

  syndicate.syndicate_escrow.spend(Some(datum), redeemer, mock_utxo_ref(), tx)
}

test claim_refund_fails_not_in_refunded_state() fail {
  // Datum is in Fundraising state
  let datum = mock_datum()
  let investor_pkh = #"00000000000000000000000000000000000000000000000000000002"
  let redeemer = ClaimRefund { investor: investor_pkh }

  let investor_output =
    Output {
      address: address.from_verification_key(investor_pkh),
      value: assets.from_asset(mock_policy_id, mock_asset_name, 1000),
      datum: NoDatum,
      reference_script: None,
    }

  let tx =
    Transaction {
      ..mock_tx(),
      outputs: [investor_output],
      extra_signatories: [investor_pkh],
    }

  syndicate.syndicate_escrow.spend(Some(datum), redeemer, mock_utxo_ref(), tx)
}
