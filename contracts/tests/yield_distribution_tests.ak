// =============================================================================
// PropFi Yield Distribution Tests
// =============================================================================

use aiken/interval
use cardano/address
use cardano/assets
use cardano/transaction.{Input, NoDatum, Output, OutputReference, Transaction}
use propfi/types.{
  AssetClass, ClaimYield, DepositYield, EmergencyWithdraw, YieldTreasuryDatum,
}
use validators/yield_distribution

// =============================================================================
// Mocks & Helpers
// =============================================================================

const mock_stablecoin_policy =
  #"11111111111111111111111111111111111111111111111111111111"

const mock_stablecoin_name = #"5553444d"

// USDM

const mock_property_policy =
  #"22222222222222222222222222222222222222222222222222222222"

const mock_property_name = #"50524f504649"

// PROPFI

const mock_manager = #"00000000000000000000000000000000000000000000000000000001"

const mock_holder = #"00000000000000000000000000000000000000000000000000000002"

fn mock_treasury_datum() -> YieldTreasuryDatum {
  YieldTreasuryDatum {
    property_token: AssetClass {
      policy_id: mock_property_policy,
      asset_name: mock_property_name,
    },
    total_fractions: 1000,
    accumulated_yield: 0,
    last_distribution: 0,
    stablecoin_asset: AssetClass {
      policy_id: mock_stablecoin_policy,
      asset_name: mock_stablecoin_name,
    },
    manager: mock_manager,
  }
}

fn mock_treasury_with_yield(yield_amount: Int) -> YieldTreasuryDatum {
  YieldTreasuryDatum {
    ..mock_treasury_datum(),
    accumulated_yield: yield_amount,
  }
}

fn mock_tx() -> Transaction {
  transaction.placeholder()
}

fn mock_utxo_ref() -> OutputReference {
  OutputReference { transaction_id: #"00", output_index: 0 }
}

// =============================================================================
// Deposit Yield Tests
// =============================================================================

test deposit_yield_success() {
  let datum = mock_treasury_datum()
  let deposit_amount = 10000
  let redeemer = DepositYield { amount: deposit_amount }

  // Output with deposited stablecoins
  let treasury_output =
    Output {
      address: address.from_script(#"00"),
      value: assets.from_asset(
        mock_stablecoin_policy,
        mock_stablecoin_name,
        deposit_amount,
      ),
      datum: NoDatum,
      reference_script: None,
    }

  let tx =
    Transaction {
      ..mock_tx(),
      outputs: [treasury_output],
      extra_signatories: [mock_manager],
    }

  yield_distribution.yield_treasury.spend(
    Some(datum),
    redeemer,
    mock_utxo_ref(),
    tx,
  )
}

test deposit_yield_fails_without_manager_signature() fail {
  let datum = mock_treasury_datum()
  let redeemer = DepositYield { amount: 10000 }

  let treasury_output =
    Output {
      address: address.from_script(#"00"),
      value: assets.from_asset(
        mock_stablecoin_policy,
        mock_stablecoin_name,
        10000,
      ),
      datum: NoDatum,
      reference_script: None,
    }

  // No manager signature
  let tx = Transaction { ..mock_tx(), outputs: [treasury_output] }

  yield_distribution.yield_treasury.spend(
    Some(datum),
    redeemer,
    mock_utxo_ref(),
    tx,
  )
}

test deposit_yield_fails_with_zero_amount() fail {
  let datum = mock_treasury_datum()
  let redeemer = DepositYield { amount: 0 }

  let treasury_output =
    Output {
      address: address.from_script(#"00"),
      value: assets.from_asset(mock_stablecoin_policy, mock_stablecoin_name, 0),
      datum: NoDatum,
      reference_script: None,
    }

  let tx =
    Transaction {
      ..mock_tx(),
      outputs: [treasury_output],
      extra_signatories: [mock_manager],
    }

  yield_distribution.yield_treasury.spend(
    Some(datum),
    redeemer,
    mock_utxo_ref(),
    tx,
  )
}

// =============================================================================
// Claim Yield Tests
// =============================================================================

test claim_yield_success() {
  let datum = mock_treasury_with_yield(10000)
  // Holder has 100 out of 1000 fractions = 10%
  let fraction_amount = 100
  // Expected yield = 10% of 10000 = 1000
  let expected_yield = 1000
  let redeemer = ClaimYield { holder: mock_holder, fraction_amount }

  // Holder receives their yield share
  let holder_output =
    Output {
      address: address.from_verification_key(mock_holder),
      value: assets.from_asset(
        mock_stablecoin_policy,
        mock_stablecoin_name,
        expected_yield,
      ),
      datum: NoDatum,
      reference_script: None,
    }

  // Treasury retains remaining yield
  let treasury_output =
    Output {
      address: address.from_script(#"00"),
      value: assets.from_asset(
        mock_stablecoin_policy,
        mock_stablecoin_name,
        datum.accumulated_yield - expected_yield,
      ),
      datum: NoDatum,
      reference_script: None,
    }

  // Input with property tokens to prove ownership
  let token_input =
    Input {
      output_reference: mock_utxo_ref(),
      output: Output {
        address: address.from_verification_key(mock_holder),
        value: assets.from_asset(
          mock_property_policy,
          mock_property_name,
          fraction_amount,
        ),
        datum: NoDatum,
        reference_script: None,
      },
    }

  let tx =
    Transaction {
      ..mock_tx(),
      inputs: [token_input],
      outputs: [holder_output, treasury_output],
      extra_signatories: [mock_holder],
    }

  yield_distribution.yield_treasury.spend(
    Some(datum),
    redeemer,
    mock_utxo_ref(),
    tx,
  )
}

test claim_yield_fails_without_holder_signature() fail {
  let datum = mock_treasury_with_yield(10000)
  let redeemer = ClaimYield { holder: mock_holder, fraction_amount: 100 }

  let holder_output =
    Output {
      address: address.from_verification_key(mock_holder),
      value: assets.from_asset(
        mock_stablecoin_policy,
        mock_stablecoin_name,
        1000,
      ),
      datum: NoDatum,
      reference_script: None,
    }

  let treasury_output =
    Output {
      address: address.from_script(#"00"),
      value: assets.from_asset(
        mock_stablecoin_policy,
        mock_stablecoin_name,
        9000,
      ),
      datum: NoDatum,
      reference_script: None,
    }

  let token_input =
    Input {
      output_reference: mock_utxo_ref(),
      output: Output {
        address: address.from_verification_key(mock_holder),
        value: assets.from_asset(mock_property_policy, mock_property_name, 100),
        datum: NoDatum,
        reference_script: None,
      },
    }

  // No holder signature
  let tx =
    Transaction {
      ..mock_tx(),
      inputs: [token_input],
      outputs: [holder_output, treasury_output],
    }

  yield_distribution.yield_treasury.spend(
    Some(datum),
    redeemer,
    mock_utxo_ref(),
    tx,
  )
}

test claim_yield_fails_without_token_ownership() fail {
  let datum = mock_treasury_with_yield(10000)
  let redeemer = ClaimYield { holder: mock_holder, fraction_amount: 100 }

  let holder_output =
    Output {
      address: address.from_verification_key(mock_holder),
      value: assets.from_asset(
        mock_stablecoin_policy,
        mock_stablecoin_name,
        1000,
      ),
      datum: NoDatum,
      reference_script: None,
    }

  let treasury_output =
    Output {
      address: address.from_script(#"00"),
      value: assets.from_asset(
        mock_stablecoin_policy,
        mock_stablecoin_name,
        9000,
      ),
      datum: NoDatum,
      reference_script: None,
    }

  // No token input - holder doesn't prove ownership
  let tx =
    Transaction {
      ..mock_tx(),
      outputs: [holder_output, treasury_output],
      extra_signatories: [mock_holder],
    }

  yield_distribution.yield_treasury.spend(
    Some(datum),
    redeemer,
    mock_utxo_ref(),
    tx,
  )
}

// =============================================================================
// Emergency Withdraw Tests
// =============================================================================

test emergency_withdraw_success_after_30_days() {
  let datum =
    YieldTreasuryDatum {
      ..mock_treasury_with_yield(10000),
      last_distribution: 0,
    }
  let redeemer = EmergencyWithdraw

  // 31 days in milliseconds = 31 * 86_400_000 = 2,678,400,000
  let thirty_one_days = 2_678_400_000
  let validity_range = interval.after(thirty_one_days)

  let tx =
    Transaction {
      ..mock_tx(),
      validity_range,
      extra_signatories: [mock_manager],
    }

  yield_distribution.yield_treasury.spend(
    Some(datum),
    redeemer,
    mock_utxo_ref(),
    tx,
  )
}

test emergency_withdraw_fails_before_30_days() fail {
  let datum =
    YieldTreasuryDatum {
      ..mock_treasury_with_yield(10000),
      last_distribution: 0,
    }
  let redeemer = EmergencyWithdraw

  // Only 10 days passed
  let ten_days = 10 * 86_400_000
  let validity_range = interval.after(ten_days)

  let tx =
    Transaction {
      ..mock_tx(),
      validity_range,
      extra_signatories: [mock_manager],
    }

  yield_distribution.yield_treasury.spend(
    Some(datum),
    redeemer,
    mock_utxo_ref(),
    tx,
  )
}

test emergency_withdraw_fails_without_manager() fail {
  let datum = mock_treasury_with_yield(10000)
  let redeemer = EmergencyWithdraw

  let thirty_one_days = 2_678_400_000
  let validity_range = interval.after(thirty_one_days)

  // No manager signature
  let tx = Transaction { ..mock_tx(), validity_range }

  yield_distribution.yield_treasury.spend(
    Some(datum),
    redeemer,
    mock_utxo_ref(),
    tx,
  )
}
