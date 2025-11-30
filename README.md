# 🏙️ Crestadel

**Real World Asset Tokenization on Cardano**

Crestadel is a cutting-edge decentralized application (DApp) that bridges the gap between real estate and blockchain technology. Built on **Cardano** and leveraging **Hydra** for Layer 2 scaling, Crestadel allows users to invest in fractionalized real estate assets with near-instant settlement and negligible fees.

---
Click the link below to watch the demo:
[**▶️ Watch the Crestadel Walkthrough**](https://github.com/soulcloude00/crestadel/blob/main/Video%20Demonstration/VN20251130_113955.mp4)

## 🏗️ Architecture

The system utilizes a hybrid architecture to ensure scalability and security.

```mermaid
graph TD
    %% Define Styles
    classDef client fill:#e1f5fe,stroke:#01579b,stroke-width:2px;
    classDef l2 fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px;
    classDef l1 fill:#311b92,stroke:#000,stroke-width:2px,color:#fff;
    classDef api fill:#fff3e0,stroke:#e65100,stroke-width:2px;

    subgraph Client_Layer ["📱 Client Side"]
        User((User)) -->|Interacts| Flutter[Flutter Frontend]
    end

    subgraph Off_Chain ["⚡ Layer 2 & APIs"]
        Flutter -.->|WebSocket / JS Bridge| HydraClient[Hydra Client JS]
        Flutter -->|REST Query| Blockfrost[Blockfrost / Koios]
        HydraClient <-->|State Channels| HydraNode[Hydra Node]
    end

    subgraph On_Chain ["🔗 Cardano Layer 1"]
        HydraNode -->|Settlement / Commit| Cardano[(Cardano L1)]
        Blockfrost -.->|Read Ledger| Cardano
    end

    %% Apply Styles
    class User,Flutter client;
    class HydraClient,HydraNode l2;
    class Cardano l1;
    class Blockfrost api;
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
