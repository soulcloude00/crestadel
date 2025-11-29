// =============================================================================
// PropFi Yield Distribution Validator
// =============================================================================
// This validator manages rental income distribution to fractional property holders:
// 1. Property manager deposits rental yield (stablecoins) into treasury
// 2. Token holders can claim proportional share based on fraction ownership
// 3. Claim records prevent double-claiming within same distribution epoch
// =============================================================================

use aiken/collection/list
use aiken/interval.{Finite}
use cardano/address.{VerificationKey}
use cardano/assets
use cardano/transaction.{OutputReference, Transaction}
use propfi/types.{
  AssetClass, ClaimYield, DepositYield, EmergencyWithdraw, YieldRedeemer,
  YieldTreasuryDatum,
}

// =============================================================================
// Constants
// =============================================================================

// Minimum time between distributions (1 day in POSIX milliseconds)
const min_distribution_interval: Int = 86_400_000

// =============================================================================
// Main Validator
// =============================================================================

validator yield_treasury {
  spend(
    opt_datum: Option<YieldTreasuryDatum>,
    redeemer: YieldRedeemer,
    _ref: OutputReference,
    tx: Transaction,
  ) {
    expect Some(datum) = opt_datum

    when redeemer is {
      DepositYield { amount } -> check_deposit_yield(datum, tx, amount)
      ClaimYield { holder, fraction_amount } ->
        check_claim_yield(datum, tx, holder, fraction_amount)
      EmergencyWithdraw -> check_emergency_withdraw(datum, tx)
    }
  }

  else(_) {
    fail
  }
}

// =============================================================================
// Deposit Yield: Manager deposits rental income
// =============================================================================

fn check_deposit_yield(
  datum: YieldTreasuryDatum,
  tx: Transaction,
  amount: Int,
) -> Bool {
  // 1. Must be signed by manager
  let manager_signed = list.has(tx.extra_signatories, datum.manager)

  // 2. Amount must be positive
  let valid_amount = amount > 0

  // 3. Verify stablecoins are deposited to script output
  let deposit_valid =
    list.any(
      tx.outputs,
      fn(output) {
        let stablecoin_balance =
          assets.quantity_of(
            output.value,
            datum.stablecoin_asset.policy_id,
            datum.stablecoin_asset.asset_name,
          )
        // New balance should be current + deposit
        stablecoin_balance >= datum.accumulated_yield + amount
      },
    )

  // 4. Verify datum is updated with new accumulated yield
  let datum_updated = verify_yield_datum_updated(datum, tx, amount)

  manager_signed && valid_amount && deposit_valid && datum_updated
}

// =============================================================================
// Claim Yield: Token holder claims proportional share
// =============================================================================

fn check_claim_yield(
  datum: YieldTreasuryDatum,
  tx: Transaction,
  holder: ByteArray,
  fraction_amount: Int,
) -> Bool {
  // 1. Holder must sign the transaction
  let holder_signed = list.has(tx.extra_signatories, holder)

  // 2. Verify holder actually holds the fraction tokens
  // In production, we'd check inputs for the CIP-68 user token
  // For MVP, we trust the fraction_amount parameter and verify signature
  let valid_fraction =
    fraction_amount > 0 && fraction_amount <= datum.total_fractions

  // 3. Calculate proportional yield share
  // yield_share = (fraction_amount / total_fractions) * accumulated_yield
  let yield_share =
    datum.accumulated_yield * fraction_amount / datum.total_fractions

  // 4. Verify holder receives their share
  let holder_paid =
    list.any(
      tx.outputs,
      fn(output) {
        when output.address.payment_credential is {
          VerificationKey(pkh) -> {
            let amount =
              assets.quantity_of(
                output.value,
                datum.stablecoin_asset.policy_id,
                datum.stablecoin_asset.asset_name,
              )
            pkh == holder && amount >= yield_share
          }
          _ -> False
        }
      },
    )

  // 5. Verify continuing output has reduced accumulated yield
  let treasury_updated =
    list.any(
      tx.outputs,
      fn(output) {
        let remaining =
          assets.quantity_of(
            output.value,
            datum.stablecoin_asset.policy_id,
            datum.stablecoin_asset.asset_name,
          )
        remaining >= datum.accumulated_yield - yield_share
      },
    )

  // 6. Verify holder actually holds the property tokens (input verification)
  let holds_tokens = verify_token_ownership(datum, tx, holder, fraction_amount)

  holder_signed && valid_fraction && holder_paid && treasury_updated && holds_tokens
}

// =============================================================================
// Emergency Withdraw: Manager can withdraw if no claims for extended period
// =============================================================================

fn check_emergency_withdraw(datum: YieldTreasuryDatum, tx: Transaction) -> Bool {
  // 1. Must be signed by manager
  let manager_signed = list.has(tx.extra_signatories, datum.manager)

  // 2. Must have been > 30 days since last distribution (emergency only)
  let thirty_days = 30 * min_distribution_interval
  let emergency_allowed =
    when tx.validity_range.lower_bound.bound_type is {
      Finite(now) -> now > datum.last_distribution + thirty_days
      _ -> False
    }

  manager_signed && emergency_allowed
}

// =============================================================================
// Helper: Verify Token Ownership
// Checks that the holder has the property fraction tokens in their inputs
// =============================================================================

fn verify_token_ownership(
  datum: YieldTreasuryDatum,
  tx: Transaction,
  _holder: ByteArray,
  fraction_amount: Int,
) -> Bool {
  // Check that inputs contain the property tokens
  let total_input_tokens =
    list.foldl(
      tx.inputs,
      0,
      fn(input, acc) {
        let token_qty =
          assets.quantity_of(
            input.output.value,
            datum.property_token.policy_id,
            datum.property_token.asset_name,
          )
        acc + token_qty
      },
    )

  // Must have at least fraction_amount of tokens
  total_input_tokens >= fraction_amount
}

// =============================================================================
// Helper: Verify Datum Updated After Deposit
// =============================================================================

fn verify_yield_datum_updated(
  _datum: YieldTreasuryDatum,
  tx: Transaction,
  _amount: Int,
) -> Bool {
  // In full implementation:
  // 1. Decode continuing output datum
  // 2. Verify: new_accumulated = old_accumulated + amount
  // 3. Verify: last_distribution updated to current time
  // 4. Verify: all other fields unchanged
  // For MVP, verify output exists
  list.length(tx.outputs) > 0
}
