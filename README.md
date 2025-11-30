# 🏙️ Crestadel

**Real World Asset Tokenization on Cardano**

Crestadel is a cutting-edge decentralized application (DApp) that bridges the gap between real estate and blockchain technology. Built on **Cardano** and leveraging **Hydra** for Layer 2 scaling, Crestadel allows users to invest in fractionalized real estate assets with near-instant settlement and negligible fees.

---

## 🏗️ Architecture

The system utilizes a hybrid architecture to ensure scalability and security.

```mermaid
graph TD
    User[User] -->|Interacts| Flutter[Flutter Frontend]
    Flutter -->|WebSocket| HydraClient[Hydra Client (JS)]
    HydraClient -->|State Channels| HydraNode[Hydra Node]
    HydraNode -->|Settlement| Cardano[Cardano L1]
    Flutter -->|Query| Blockfrost[Blockfrost/Koios]
    Blockfrost -->|Read Data| Cardano
```

---

## 🚀 User Journey: Investment Flow

Experience a seamless investment process from wallet connection to asset ownership.

```mermaid
sequenceDiagram
    participant U as User
    participant App as Flutter App
    participant W as Wallet (Nami/Eternl)
    participant H as Hydra Head

    U->>App: Connect Wallet
    App->>W: Request Access
    W-->>App: Access Granted
    U->>App: Select Property
    App->>U: Show Details & 3D Model
    U->>App: Click "Invest Now"
    App->>H: Check Head Status
    H-->>App: Status: Open
    App->>W: Sign Transaction
    W-->>App: Signed Tx
    App->>H: Submit Transaction (NewTx)
    H-->>App: Snapshot Confirmed
    App-->>U: "Investment Successful!"
```

---

## 🛠️ Tech Stack

```mermaid
mindmap
  root((Crestadel))
    Frontend
      Flutter
      Dart
      Provider
    Web Integration
      JavaScript
      Hydra Client
      WebGL (3D)
    Blockchain
      Cardano
      Hydra (L2)
      Aiken (Contracts)
      Lucid / MeshJS
```

---

## ✨ Key Features

-   **Fractional Ownership**: Buy and sell fractions of high-value real estate.
-   **Hydra Powered**: Lightning-fast transactions using Cardano's L2 scaling solution.
-   **3D Virtual Tours**: Interactive 3D models of properties directly in the app.
-   **Secure Wallet Integration**: Seamless connection with Nami, Eternl, and other Cardano wallets.
-   **Real-time Trading**: Trade property tokens instantly within open Hydra Heads.

---

## 📊 Tokenomics (Example)

```mermaid
pie title Asset Distribution
    "Residential" : 45
    "Commercial" : 30
    "Industrial" : 15
    "Land" : 10
```

---

## 🚦 Getting Started

1.  **Prerequisites**:
    -   Flutter SDK
    -   Cardano Wallet (Nami/Eternl)
    -   Running Hydra Node (for L2 features)

2.  **Installation**:
    ```bash
    git clone https://github.com/soulcloude00/dapp.git
    cd frontend
    flutter pub get
    ```

3.  **Run**:
    ```bash
    flutter run -d chrome
    ```
