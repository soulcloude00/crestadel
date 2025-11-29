/**
 * PropFi Transaction Builder
 * Builds Cardano transactions for property fractionalization and marketplace operations
 * Uses MeshJS SDK with Blockfrost Provider
 */

import {
  MeshTxBuilder,
  MeshWallet,
  BlockfrostProvider,  // Using Blockfrost API
  resolveScriptHash,
  serializePlutusScript,
  deserializeAddress,
  serializeAddressObj,
  mConStr0,
  mConStr1,
  stringToHex,
  hexToString,
} from '@meshsdk/core';

import * as fs from 'fs';
import * as path from 'path';

// ============================================================================
// Configuration
// ============================================================================

export const NETWORK = 'preprod';

// Blockfrost configuration
export const BLOCKFROST_CONFIG = {
  network: NETWORK as 'preprod' | 'preview' | 'mainnet',
  projectId: 'preprod3EhVdYxWz9oD5XP1TVbbdLxbN4jCNwBe',
};

// Stablecoin configuration for Preprod testnet
export const STABLECOIN_CONFIG = {
  USDM: {
    policyId: 'c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad',
    assetName: stringToHex('USDM'),
    decimals: 6,
  },
  iUSD: {
    policyId: 'f66d78b4a3cb3d37afa0ec36461e51ecbde00f26c8f0a68f94b69880',
    assetName: stringToHex('iUSD'),
    decimals: 6,
  },
};

// CIP-68 Token Labels
export const CIP68_REFERENCE_LABEL = '000643b0'; // (100) Reference Token
export const CIP68_USER_TOKEN_LABEL = '000de140'; // (222) User/Fraction Token

// ============================================================================
// Types
// ============================================================================

export interface PropertyMetadata {
  name: string;
  description: string;
  image: string; // IPFS CID or URL
  location: string;
  totalValue: number; // in stablecoin units
  totalFractions: number;
  pricePerFraction: number;
  legalDocumentCID?: string; // IPFS CID for legal documents
}

export interface PropertyDatum {
  owner: string; // PubKeyHash
  price: number;
  fractionToken: {
    policyId: string;
    assetName: string;
  };
  totalFractions: number;
  metadata: PropertyMetadata;
}

export interface MarketplaceDatum {
  seller: string; // PubKeyHash
  price: number; // Price per fraction in stablecoin
  stablecoinAsset: {
    policyId: string;
    assetName: string;
  };
  fractionAsset: {
    policyId: string;
    assetName: string;
  };
  fractionAmount: number;
}

export interface ContractConfig {
  fractionalizeScriptHash: string;
  fractionalizeScriptCbor: string;
  cip68MintingPolicyId: string;
  cip68MintingPolicyCbor: string;
  marketplaceScriptHash: string;
  marketplaceScriptCbor: string;
  syndicateScriptHash: string;
  syndicateScriptCbor: string;
  yieldTreasuryScriptHash: string;
  yieldTreasuryScriptCbor: string;
}

// ============================================================================
// Contract Loading
// ============================================================================

let contractConfig: ContractConfig | null = null;

/**
 * Load contract configuration from plutus.json
 */
export function loadContracts(): ContractConfig {
  if (contractConfig) return contractConfig;

  const plutusJsonPath = path.join(__dirname, '../../contracts/plutus.json');

  if (!fs.existsSync(plutusJsonPath)) {
    throw new Error('plutus.json not found. Run `aiken build` first.');
  }

  const plutusJson = JSON.parse(fs.readFileSync(plutusJsonPath, 'utf-8'));

  const getValidator = (title: string) => {
    const v = plutusJson.validators.find((v: any) => v.title === title);
    if (!v) {
      console.warn(`Validator ${title} not found - using placeholder`);
      return { hash: 'placeholder', compiledCode: '' };
    }
    return v;
  };

  const fractionalize = getValidator('fractionalize.fractionalize.spend');
  const cip68Minting = getValidator('fractionalize.cip68_minting.mint');
  const marketplace = getValidator('fractionalize.marketplace.spend');
  const syndicate = getValidator('syndicate.syndicate_escrow.spend');
  const yieldTreasury = getValidator('yield_distribution.yield_treasury.spend');

  contractConfig = {
    fractionalizeScriptHash: fractionalize.hash,
    fractionalizeScriptCbor: fractionalize.compiledCode,
    cip68MintingPolicyId: cip68Minting.hash,
    cip68MintingPolicyCbor: cip68Minting.compiledCode,
    marketplaceScriptHash: marketplace.hash,
    marketplaceScriptCbor: marketplace.compiledCode,
    syndicateScriptHash: syndicate.hash,
    syndicateScriptCbor: syndicate.compiledCode,
    yieldTreasuryScriptHash: yieldTreasury.hash,
    yieldTreasuryScriptCbor: yieldTreasury.compiledCode,
  };

  return contractConfig;
}

// ============================================================================
// Transaction Builder Class
// ============================================================================

export class PropFiTransactionBuilder {
  private provider: BlockfrostProvider;
  private contracts: ContractConfig;

  constructor() {
    // Using Blockfrost API
    this.provider = new BlockfrostProvider(BLOCKFROST_CONFIG.projectId);
    this.contracts = loadContracts();
  }

  /**
   * Get the marketplace script address
   */
  getMarketplaceAddress(): string {
    // Generate address from script hash
    const scriptHash = this.contracts.marketplaceScriptHash;
    // For testnet, use network ID 0
    return `addr_test1wz${scriptHash}`; // Simplified - use proper encoding in production
  }

  /**
   * Get the fractionalize script address
   */
  getFractionalizeAddress(): string {
    const scriptHash = this.contracts.fractionalizeScriptHash;
    return `addr_test1wz${scriptHash}`; // Simplified - use proper encoding in production
  }

  /**
   * Build CIP-68 Reference Token Datum
   */
  buildReferenceDatum(metadata: PropertyMetadata): object {
    // CIP-68 reference datum structure
    return mConStr0([
      // Metadata map - all values as strings/hex
      new Map<string, string | number>([
        [stringToHex('name'), stringToHex(metadata.name)],
        [stringToHex('description'), stringToHex(metadata.description)],
        [stringToHex('image'), stringToHex(metadata.image)],
        [stringToHex('location'), stringToHex(metadata.location)],
        [stringToHex('total_value'), metadata.totalValue],
        [stringToHex('total_fractions'), metadata.totalFractions],
        [stringToHex('price_per_fraction'), metadata.pricePerFraction],
      ]),
      1, // Version
    ]);
  }

  /**
   * Build Property Datum for fractionalize validator
   */
  buildPropertyDatum(datum: PropertyDatum): object {
    return mConStr0([
      datum.owner,
      datum.price,
      mConStr0([datum.fractionToken.policyId, datum.fractionToken.assetName]),
      datum.totalFractions,
      mConStr0([
        stringToHex(datum.metadata.name),
        stringToHex(datum.metadata.description),
        stringToHex(datum.metadata.location),
        datum.metadata.totalValue,
        datum.metadata.totalFractions,
      ]),
    ]);
  }

  /**
   * Build Marketplace Datum
   */
  buildMarketplaceDatum(datum: MarketplaceDatum): object {
    return mConStr0([
      datum.seller,
      datum.price,
      mConStr0([datum.stablecoinAsset.policyId, datum.stablecoinAsset.assetName]),
      mConStr0([datum.fractionAsset.policyId, datum.fractionAsset.assetName]),
      datum.fractionAmount,
    ]);
  }

  /**
   * Fractionalize a property - Mint CIP-68 tokens
   * @param walletAddress - Owner's wallet address
   * @param propertyId - Unique property identifier (hex string)
   * @param metadata - Property metadata
   * @param totalFractions - Number of fraction tokens to mint
   */
  async fractionalizeProperty(
    walletAddress: string,
    propertyId: string,
    metadata: PropertyMetadata,
    totalFractions: number
  ): Promise<string> {
    const txBuilder = new MeshTxBuilder({
      fetcher: this.provider,
      evaluator: this.provider,
    });

    // Build token names with CIP-68 prefixes
    const referenceTokenName = CIP68_REFERENCE_LABEL + propertyId;
    const userTokenName = CIP68_USER_TOKEN_LABEL + propertyId;

    // Get owner's pubkey hash
    const ownerPkh = deserializeAddress(walletAddress).pubKeyHash;

    // Build the minting redeemer (MintProperty { property_id })
    const mintRedeemer = mConStr0([propertyId]);

    // Build reference datum
    const refDatum = this.buildReferenceDatum(metadata);

    // Build property datum
    const propertyDatum = this.buildPropertyDatum({
      owner: ownerPkh,
      price: metadata.pricePerFraction,
      fractionToken: {
        policyId: this.contracts.cip68MintingPolicyId,
        assetName: userTokenName,
      },
      totalFractions,
      metadata,
    });

    // Build the transaction
    const unsignedTx = await txBuilder
      .mintPlutusScriptV2()
      .mint('1', this.contracts.cip68MintingPolicyId, referenceTokenName)
      .mintingScript(this.contracts.cip68MintingPolicyCbor)
      .mintRedeemerValue(mintRedeemer)
      .mint(totalFractions.toString(), this.contracts.cip68MintingPolicyId, userTokenName)
      .mintingScript(this.contracts.cip68MintingPolicyCbor)
      .mintRedeemerValue(mintRedeemer)
      // Send reference token to fractionalize script with datum
      .txOut(this.getFractionalizeAddress(), [
        { unit: 'lovelace', quantity: '2000000' },
        {
          unit: this.contracts.cip68MintingPolicyId + referenceTokenName,
          quantity: '1'
        },
      ])
      .txOutInlineDatumValue(propertyDatum)
      // Send user tokens to owner
      .txOut(walletAddress, [
        { unit: 'lovelace', quantity: '2000000' },
        {
          unit: this.contracts.cip68MintingPolicyId + userTokenName,
          quantity: totalFractions.toString()
        },
      ])
      .changeAddress(walletAddress)
      .selectUtxosFrom(await this.provider.fetchAddressUTxOs(walletAddress))
      .complete();

    return unsignedTx;
  }

  /**
   * List fraction tokens for sale on the marketplace
   * @param walletAddress - Seller's wallet address
   * @param fractionPolicyId - Policy ID of the fraction tokens
   * @param fractionAssetName - Asset name of the fraction tokens
   * @param amount - Number of fractions to list
   * @param pricePerFraction - Price per fraction in stablecoin units
   * @param stablecoin - Which stablecoin to accept ('USDM' or 'iUSD')
   */
  async listForSale(
    walletAddress: string,
    fractionPolicyId: string,
    fractionAssetName: string,
    amount: number,
    pricePerFraction: number,
    stablecoin: 'USDM' | 'iUSD' = 'USDM'
  ): Promise<string> {
    const txBuilder = new MeshTxBuilder({
      fetcher: this.provider,
      evaluator: this.provider,
    });

    const sellerPkh = deserializeAddress(walletAddress).pubKeyHash;
    const stablecoinConfig = STABLECOIN_CONFIG[stablecoin];

    // Build marketplace datum
    const marketplaceDatum = this.buildMarketplaceDatum({
      seller: sellerPkh,
      price: pricePerFraction * amount, // Total price
      stablecoinAsset: {
        policyId: stablecoinConfig.policyId,
        assetName: stablecoinConfig.assetName,
      },
      fractionAsset: {
        policyId: fractionPolicyId,
        assetName: fractionAssetName,
      },
      fractionAmount: amount,
    });

    const unsignedTx = await txBuilder
      // Send fractions to marketplace with datum
      .txOut(this.getMarketplaceAddress(), [
        { unit: 'lovelace', quantity: '2000000' },
        {
          unit: fractionPolicyId + fractionAssetName,
          quantity: amount.toString()
        },
      ])
      .txOutInlineDatumValue(marketplaceDatum)
      .changeAddress(walletAddress)
      .selectUtxosFrom(await this.provider.fetchAddressUTxOs(walletAddress))
      .complete();

    return unsignedTx;
  }

  /**
   * Buy fractions from the marketplace
   * @param buyerAddress - Buyer's wallet address
   * @param listingUtxo - The UTxO containing the listing
   * @param datum - The marketplace datum
   */
  async buyFractions(
    buyerAddress: string,
    listingUtxo: { txHash: string; outputIndex: number },
    datum: MarketplaceDatum
  ): Promise<string> {
    const txBuilder = new MeshTxBuilder({
      fetcher: this.provider,
      evaluator: this.provider,
    });

    // Buy redeemer (constructor index 0)
    const buyRedeemer = mConStr0([]);

    // Fetch the listing UTxO
    const utxos = await this.provider.fetchAddressUTxOs(this.getMarketplaceAddress());
    const listingUtxoData = utxos.find(
      (u: any) => u.input.txHash === listingUtxo.txHash &&
        u.input.outputIndex === listingUtxo.outputIndex
    );

    if (!listingUtxoData) {
      throw new Error('Listing UTxO not found');
    }

    const unsignedTx = await txBuilder
      // Spend the marketplace UTxO
      .spendingPlutusScriptV2()
      .txIn(listingUtxo.txHash, listingUtxo.outputIndex)
      .spendingReferenceTxInInlineDatumPresent()
      .spendingReferenceTxInRedeemerValue(buyRedeemer)
      .txInScript(this.contracts.marketplaceScriptCbor)
      // Pay seller the stablecoin amount
      .txOut(datum.seller, [
        { unit: 'lovelace', quantity: '2000000' },
        {
          unit: datum.stablecoinAsset.policyId + datum.stablecoinAsset.assetName,
          quantity: datum.price.toString()
        },
      ])
      // Buyer receives the fractions
      .txOut(buyerAddress, [
        { unit: 'lovelace', quantity: '2000000' },
        {
          unit: datum.fractionAsset.policyId + datum.fractionAsset.assetName,
          quantity: datum.fractionAmount.toString()
        },
      ])
      .changeAddress(buyerAddress)
      .selectUtxosFrom(await this.provider.fetchAddressUTxOs(buyerAddress))
      .complete();

    return unsignedTx;
  }

  /**
   * Cancel a listing (seller only)
   */
  async cancelListing(
    sellerAddress: string,
    listingUtxo: { txHash: string; outputIndex: number }
  ): Promise<string> {
    const txBuilder = new MeshTxBuilder({
      fetcher: this.provider,
      evaluator: this.provider,
    });

    // Cancel redeemer (constructor index 1)
    const cancelRedeemer = mConStr1([]);

    const sellerPkh = deserializeAddress(sellerAddress).pubKeyHash;

    const unsignedTx = await txBuilder
      .spendingPlutusScriptV2()
      .txIn(listingUtxo.txHash, listingUtxo.outputIndex)
      .spendingReferenceTxInInlineDatumPresent()
      .spendingReferenceTxInRedeemerValue(cancelRedeemer)
      .txInScript(this.contracts.marketplaceScriptCbor)
      .requiredSignerHash(sellerPkh)
      .changeAddress(sellerAddress)
      .selectUtxosFrom(await this.provider.fetchAddressUTxOs(sellerAddress))
      .complete();

    return unsignedTx;
  }

  // ==========================================================================
  // Syndicate Escrow Operations
  // ==========================================================================

  /**
   * Build Syndicate Escrow Datum
   */
  buildSyndicateDatum(params: SyndicateDatumParams): object {
    // SyndicateState: Fundraising = 0, Locked = 1, Finalized = 2, Refunded = 3
    const stateIndex = ['Fundraising', 'Locked', 'Finalized', 'Refunded'].indexOf(params.state);
    
    // InvestmentLimits constructor
    const limits = mConStr0([
      params.limits.minInvestment,
      params.limits.maxInvestment,
      params.limits.maxPercentage,
    ]);

    // Stablecoin asset constructor
    const stablecoinAsset = mConStr0([
      params.stablecoinPolicyId,
      params.stablecoinAssetName,
    ]);

    // Fraction token asset constructor
    const fractionToken = mConStr0([
      params.fractionPolicyId,
      params.fractionAssetName,
    ]);

    // Investors list: List<(VerificationKeyHash, Int)>
    const investors = params.investors.map(inv => [inv.pkh, inv.amount]);

    // EscrowDatum constructor
    return mConStr0([
      mConStr0([]), // state - will be set by index
      params.target,
      params.currentRaised,
      params.deadline,
      investors,
      params.sellerPkh,
      stablecoinAsset,
      fractionToken,
      params.dunaHash,
      limits,
    ]);
  }

  /**
   * Create a new syndicate for property acquisition
   */
  async createSyndicate(
    managerAddress: string,
    params: CreateSyndicateParams
  ): Promise<string> {
    const txBuilder = new MeshTxBuilder({
      fetcher: this.provider,
      evaluator: this.provider,
    });

    const managerPkh = deserializeAddress(managerAddress).pubKeyHash;

    const syndicateDatum = this.buildSyndicateDatum({
      state: 'Fundraising',
      target: params.target,
      currentRaised: 0,
      deadline: params.deadline,
      investors: [],
      sellerPkh: params.sellerPkh,
      stablecoinPolicyId: params.stablecoinPolicyId,
      stablecoinAssetName: params.stablecoinAssetName,
      fractionPolicyId: params.fractionPolicyId,
      fractionAssetName: params.fractionAssetName,
      dunaHash: params.dunaHash,
      limits: params.limits,
    });

    const syndicateAddress = this.getSyndicateAddress();

    const unsignedTx = await txBuilder
      .txOut(syndicateAddress, [
        { unit: 'lovelace', quantity: '5000000' }, // Min ADA
      ])
      .txOutInlineDatumValue(syndicateDatum)
      .requiredSignerHash(managerPkh)
      .changeAddress(managerAddress)
      .selectUtxosFrom(await this.provider.fetchAddressUTxOs(managerAddress))
      .complete();

    return unsignedTx;
  }

  /**
   * Deposit stablecoins into syndicate
   */
  async depositToSyndicate(
    investorAddress: string,
    amount: number,
    syndicateUtxo: { txHash: string; outputIndex: number },
    currentDatum: SyndicateDatumParams
  ): Promise<string> {
    const txBuilder = new MeshTxBuilder({
      fetcher: this.provider,
      evaluator: this.provider,
    });

    const investorPkh = deserializeAddress(investorAddress).pubKeyHash;

    // Deposit redeemer: Deposit { amount: Int }
    const depositRedeemer = mConStr0([amount]);

    // Update datum with new investment
    const updatedInvestors = [...currentDatum.investors, { pkh: investorPkh, amount }];
    const newRaised = currentDatum.currentRaised + amount;

    const updatedDatum = this.buildSyndicateDatum({
      ...currentDatum,
      currentRaised: newRaised,
      investors: updatedInvestors,
    });

    const stablecoinUnit = currentDatum.stablecoinPolicyId + currentDatum.stablecoinAssetName;

    const unsignedTx = await txBuilder
      .spendingPlutusScriptV2()
      .txIn(syndicateUtxo.txHash, syndicateUtxo.outputIndex)
      .spendingReferenceTxInInlineDatumPresent()
      .spendingReferenceTxInRedeemerValue(depositRedeemer)
      .txInScript(this.contracts.syndicateScriptCbor)
      // Continue the script with updated datum and increased value
      .txOut(this.getSyndicateAddress(), [
        { unit: 'lovelace', quantity: '5000000' },
        { unit: stablecoinUnit, quantity: newRaised.toString() },
      ])
      .txOutInlineDatumValue(updatedDatum)
      .requiredSignerHash(investorPkh)
      .changeAddress(investorAddress)
      .selectUtxosFrom(await this.provider.fetchAddressUTxOs(investorAddress))
      .complete();

    return unsignedTx;
  }

  /**
   * Get syndicate escrow script address
   */
  getSyndicateAddress(): string {
    const scriptHash = this.contracts.syndicateScriptHash || 'placeholder';
    return `addr_test1wz${scriptHash}`;
  }

  // ==========================================================================
  // Yield Distribution Operations
  // ==========================================================================

  /**
   * Build Yield Treasury Datum
   */
  buildYieldTreasuryDatum(params: YieldTreasuryDatumParams): object {
    const propertyToken = mConStr0([
      params.propertyPolicyId,
      params.propertyAssetName,
    ]);

    const stablecoinAsset = mConStr0([
      params.stablecoinPolicyId,
      params.stablecoinAssetName,
    ]);

    return mConStr0([
      propertyToken,
      params.totalFractions,
      params.accumulatedYield,
      params.lastDistribution,
      stablecoinAsset,
      params.managerPkh,
    ]);
  }

  /**
   * Create a new yield treasury for a property
   */
  async createYieldTreasury(
    managerAddress: string,
    params: CreateYieldTreasuryParams
  ): Promise<string> {
    const txBuilder = new MeshTxBuilder({
      fetcher: this.provider,
      evaluator: this.provider,
    });

    const managerPkh = deserializeAddress(managerAddress).pubKeyHash;

    const treasuryDatum = this.buildYieldTreasuryDatum({
      propertyPolicyId: params.propertyPolicyId,
      propertyAssetName: params.propertyAssetName,
      totalFractions: params.totalFractions,
      accumulatedYield: 0,
      lastDistribution: Date.now(),
      stablecoinPolicyId: params.stablecoinPolicyId,
      stablecoinAssetName: params.stablecoinAssetName,
      managerPkh: managerPkh,
    });

    const treasuryAddress = this.getYieldTreasuryAddress();

    const unsignedTx = await txBuilder
      .txOut(treasuryAddress, [
        { unit: 'lovelace', quantity: '5000000' },
      ])
      .txOutInlineDatumValue(treasuryDatum)
      .requiredSignerHash(managerPkh)
      .changeAddress(managerAddress)
      .selectUtxosFrom(await this.provider.fetchAddressUTxOs(managerAddress))
      .complete();

    return unsignedTx;
  }

  /**
   * Deposit rental yield into treasury
   */
  async depositYield(
    managerAddress: string,
    amount: number,
    treasuryUtxo: { txHash: string; outputIndex: number },
    currentDatum: YieldTreasuryDatumParams
  ): Promise<string> {
    const txBuilder = new MeshTxBuilder({
      fetcher: this.provider,
      evaluator: this.provider,
    });

    const managerPkh = deserializeAddress(managerAddress).pubKeyHash;

    // DepositYield redeemer: DepositYield { amount: Int }
    const depositRedeemer = mConStr0([amount]);

    const newAccumulated = currentDatum.accumulatedYield + amount;

    const updatedDatum = this.buildYieldTreasuryDatum({
      ...currentDatum,
      accumulatedYield: newAccumulated,
      lastDistribution: Date.now(),
    });

    const stablecoinUnit = currentDatum.stablecoinPolicyId + currentDatum.stablecoinAssetName;

    const unsignedTx = await txBuilder
      .spendingPlutusScriptV2()
      .txIn(treasuryUtxo.txHash, treasuryUtxo.outputIndex)
      .spendingReferenceTxInInlineDatumPresent()
      .spendingReferenceTxInRedeemerValue(depositRedeemer)
      .txInScript(this.contracts.yieldTreasuryScriptCbor)
      .txOut(this.getYieldTreasuryAddress(), [
        { unit: 'lovelace', quantity: '5000000' },
        { unit: stablecoinUnit, quantity: newAccumulated.toString() },
      ])
      .txOutInlineDatumValue(updatedDatum)
      .requiredSignerHash(managerPkh)
      .changeAddress(managerAddress)
      .selectUtxosFrom(await this.provider.fetchAddressUTxOs(managerAddress))
      .complete();

    return unsignedTx;
  }

  /**
   * Claim yield as a token holder
   */
  async claimYield(
    holderAddress: string,
    fractionAmount: number,
    treasuryUtxo: { txHash: string; outputIndex: number },
    tokenUtxo: { txHash: string; outputIndex: number },
    currentDatum: YieldTreasuryDatumParams
  ): Promise<string> {
    const txBuilder = new MeshTxBuilder({
      fetcher: this.provider,
      evaluator: this.provider,
    });

    const holderPkh = deserializeAddress(holderAddress).pubKeyHash;

    // Calculate proportional yield
    const yieldShare = Math.floor(
      (currentDatum.accumulatedYield * fractionAmount) / currentDatum.totalFractions
    );

    // ClaimYield redeemer: ClaimYield { holder, fraction_amount }
    const claimRedeemer = mConStr1([holderPkh, fractionAmount]);

    const remainingYield = currentDatum.accumulatedYield - yieldShare;

    const updatedDatum = this.buildYieldTreasuryDatum({
      ...currentDatum,
      accumulatedYield: remainingYield,
    });

    const stablecoinUnit = currentDatum.stablecoinPolicyId + currentDatum.stablecoinAssetName;

    const unsignedTx = await txBuilder
      // Spend treasury
      .spendingPlutusScriptV2()
      .txIn(treasuryUtxo.txHash, treasuryUtxo.outputIndex)
      .spendingReferenceTxInInlineDatumPresent()
      .spendingReferenceTxInRedeemerValue(claimRedeemer)
      .txInScript(this.contracts.yieldTreasuryScriptCbor)
      // Include token input as proof of ownership
      .txIn(tokenUtxo.txHash, tokenUtxo.outputIndex)
      // Updated treasury output
      .txOut(this.getYieldTreasuryAddress(), [
        { unit: 'lovelace', quantity: '5000000' },
        { unit: stablecoinUnit, quantity: remainingYield.toString() },
      ])
      .txOutInlineDatumValue(updatedDatum)
      // Holder receives their yield share
      .txOut(holderAddress, [
        { unit: 'lovelace', quantity: '2000000' },
        { unit: stablecoinUnit, quantity: yieldShare.toString() },
      ])
      .requiredSignerHash(holderPkh)
      .changeAddress(holderAddress)
      .selectUtxosFrom(await this.provider.fetchAddressUTxOs(holderAddress))
      .complete();

    return unsignedTx;
  }

  /**
   * Get yield treasury script address
   */
  getYieldTreasuryAddress(): string {
    const scriptHash = this.contracts.yieldTreasuryScriptHash || 'placeholder';
    return `addr_test1wz${scriptHash}`;
  }
}

// ============================================================================
// New Types for Syndicate and Yield Distribution
// ============================================================================

export interface InvestmentLimits {
  minInvestment: number;
  maxInvestment: number;
  maxPercentage: number; // e.g., 50 for 50%
}

export interface InvestorRecord {
  pkh: string;
  amount: number;
}

export type SyndicateState = 'Fundraising' | 'Locked' | 'Finalized' | 'Refunded';

export interface SyndicateDatumParams {
  state: SyndicateState;
  target: number;
  currentRaised: number;
  deadline: number; // POSIX timestamp
  investors: InvestorRecord[];
  sellerPkh: string;
  stablecoinPolicyId: string;
  stablecoinAssetName: string;
  fractionPolicyId: string;
  fractionAssetName: string;
  dunaHash: string;
  limits: InvestmentLimits;
}

export interface CreateSyndicateParams {
  target: number;
  deadline: number;
  sellerPkh: string;
  stablecoinPolicyId: string;
  stablecoinAssetName: string;
  fractionPolicyId: string;
  fractionAssetName: string;
  dunaHash: string;
  limits: InvestmentLimits;
}

export interface YieldTreasuryDatumParams {
  propertyPolicyId: string;
  propertyAssetName: string;
  totalFractions: number;
  accumulatedYield: number;
  lastDistribution: number; // POSIX timestamp
  stablecoinPolicyId: string;
  stablecoinAssetName: string;
  managerPkh: string;
}

export interface CreateYieldTreasuryParams {
  propertyPolicyId: string;
  propertyAssetName: string;
  totalFractions: number;
  stablecoinPolicyId: string;
  stablecoinAssetName: string;
}

// Export singleton instance
export const propFiTxBuilder = new PropFiTransactionBuilder();

export default PropFiTransactionBuilder;
