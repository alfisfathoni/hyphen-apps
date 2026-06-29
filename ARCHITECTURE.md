# HYPEN E-Commerce Project: Architecture & Data Flow Documentation

This document provides a professional, deep-dive technical overview of the **HYPEN** full-stack e-commerce ecosystem. HYPEN is a secondhand goods and apparel marketplace featuring real-time chat, a peer-to-peer price bargaining (negotiation) engine, automated shipping calculation, and secure transaction workflows.

---

## 1. System Architecture Overview

HYPEN is built using a decoupled client-server architecture. The backend serves as a stateless REST API and WebSocket gateway, and the frontend is a multi-platform Flutter mobile application.

```mermaid
graph TD
    %% Clients
    subgraph Clients ["Client Layer (Frontend)"]
        FlutterApp["Flutter Mobile Client (Dart)"]
    end

    %% API Gateway & Sockets
    subgraph Services ["Application Layer (Backend)"]
        ExpressApp["Express.js Server (Node.js)"]
        SocketServer["Socket.io WebSocket Server"]
    end

    %% Database
    subgraph Database ["Data Layer"]
        MySQL[("MySQL Database (hypen_db)")]
    end

    %% External Services
    subgraph External ["Third-Party Service Integration"]
        Midtrans["Midtrans API (Payment Gateway)"]
        RajaOngkir["RajaOngkir API (Shipping Costs)"]
        Cloudinary["Cloudinary API (Image Storage)"]
        GoogleOAuth["Google Auth API (OAuth 2.0)"]
    end

    %% Connections
    FlutterApp -- HTTPS Requests --> ExpressApp
    FlutterApp -- WebSocket Connection --> SocketServer
    ExpressApp -- Query / Transactions --> MySQL
    SocketServer -- Read/Write Messages --> MySQL
    
    %% API Interactions
    ExpressApp -- Charge & Status Webhooks --> Midtrans
    ExpressApp -- Domestic Rate Calculator --> RajaOngkir
    ExpressApp -- Direct Image Upload --> Cloudinary
    ExpressApp -- Verify Google Token ID --> GoogleOAuth
```

---

## 2. Technology Stack

### Backend Core
* **Runtime & Framework**: Node.js & Express.js (v5.2+)
* **Database Driver**: `mysql2/promise` (connection pooling with max 10 concurrent connections)
* **Real-time Engine**: `socket.io` (v4.8+) for real-time messaging, typing indicators, and read confirmations
* **Security & Auth**: `bcrypt` (password hashing) and `jsonwebtoken` (v9.0+) for stateless JWT sessions
* **Media Hosting**: `cloudinary` SDK for product and profile image cloud storage
* **Third-Party Integrations**:
  * **Midtrans Snap SDK**: Secure payment link generation and payment callback handler
  * **RajaOngkir API**: Domestic city destination searching and weight-based rate calculation
  * **Nodemailer**: SMTP provider integrations for OTP emails
* **API Documentation**: `swagger-ui-express` (Swagger Spec v2.0 in `swagger.json`)

### Frontend Core
* **Core SDK**: Flutter & Dart (SDK ^3.10.8)
* **Networking Client**: `dio` (v5.9.2) - customized with request interceptors for automatic JWT injection and response interceptors for immediate `401 Unauthorized` token invalidation and auto-logout
* **Secure Storage**: `flutter_secure_storage` for local keychain encryption of tokens
* **State Management**: `ChangeNotifier` with Singleton Pattern managers, decoupling widget UI states from business operations
* **Authentication Plugins**: `google_sign_in` for OAuth-based social login
* **Sockets Client**: `socket_io_client` (v2.0.3) for persistence of full-duplex socket tunnels
* **Web Views**: `webview_flutter` for rendering Midtrans Snap payment screens inline

---

## 3. Database Schema & Data Models

The MySQL schema (`hypen_db`) consists of 15 relational tables. Many relationships map cascade deletions, ensuring references remain intact when users or listings are deleted.

```mermaid
erDiagram
    USERS {
        VARCHAR id PK
        VARCHAR username
        VARCHAR email
        VARCHAR password
        ENUM role "user, seller, admin"
        TINYINT isVerified
        VARCHAR googleId
        ENUM authProvider "local, google"
        DATETIME createdAt
    }
    USER_PROFILES {
        INT id PK
        VARCHAR userId FK
        VARCHAR fullname
        VARCHAR phone
        DATE dateOfBirth
        TEXT location
        VARCHAR photoUrl
    }
    REFRESH_TOKENS {
        INT id PK
        VARCHAR userId FK
        TEXT token
        BIGINT expiry
    }
    PRODUCTS {
        VARCHAR id PK
        VARCHAR sellerID FK
        VARCHAR name
        TEXT description
        DECIMAL price
        VARCHAR category
        INT weight
        VARCHAR originCityId
        VARCHAR originCityLabel
        VARCHAR imageUrl
        ENUM status "pending, approved, rejected"
        ENUM item_condition "like_new, good, fair"
        TEXT defects
    }
    PRODUCT_SIZES {
        INT id PK
        VARCHAR productId FK
        VARCHAR size
        TINYINT stock "1=available, 0=sold"
    }
    ADDRESSES {
        VARCHAR id PK
        VARCHAR userId FK
        VARCHAR label
        VARCHAR recipientName
        VARCHAR phone
        TEXT address
        VARCHAR destinationCityId
        TINYINT isDefault
    }
    CART_ITEMS {
        INT id PK
        VARCHAR userId FK
        VARCHAR productId FK
        VARCHAR size
        DECIMAL price
        TINYINT quantity "always 1"
        DECIMAL totalPrice
    }
    ORDERS {
        VARCHAR id PK
        VARCHAR buyerID FK
        VARCHAR productId FK
        VARCHAR size
        DECIMAL price
        VARCHAR addressId FK
        ENUM status "pending, waiting_payment, waiting_confirmation, paid, shipped, delivered, cancelled"
    }
    SHIPMENTS {
        VARCHAR id PK
        VARCHAR orderId FK
        VARCHAR buyerID FK
        VARCHAR addressId FK
        VARCHAR courierCode
        VARCHAR service
        DECIMAL shippingCost
        ENUM status "pending, processing, shipped, delivered, cancelled"
    }
    PAYMENTS {
        VARCHAR id PK
        VARCHAR orderId FK
        VARCHAR buyerID FK
        DECIMAL amount
        VARCHAR paymentMethod
        ENUM status "pending, paid, failed, cancelled, expired"
        VARCHAR midtransOrderId
        TEXT snapToken
    }
    CHAT_ROOMS {
        VARCHAR id PK
        VARCHAR buyerId FK
        VARCHAR sellerId FK
        VARCHAR productId FK
        INT proposedPrice
        VARCHAR negotiationStatus "pending, accepted, rejected"
        VARCHAR proposedBy "buyer, seller"
    }
    CHAT_MESSAGES {
        VARCHAR id PK
        VARCHAR roomId FK
        VARCHAR senderId FK
        TEXT message
        VARCHAR imageUrl
        ENUM type "text, image"
        TINYINT isRead
    }

    USERS ||--|| USER_PROFILES : "has"
    USERS ||--o{ REFRESH_TOKENS : "has"
    USERS ||--o{ PRODUCTS : "seller"
    USERS ||--o{ ADDRESSES : "owns"
    USERS ||--o{ ORDERS : "buys"
    PRODUCTS ||--o{ PRODUCT_SIZES : "has"
    ORDERS ||--|| SHIPMENTS : "delivers"
    ORDERS ||--|| PAYMENTS : "billed-via"
    CHAT_ROOMS ||--o{ CHAT_MESSAGES : "contains"
    USERS ||--o{ CHAT_ROOMS : "participates-in"
    PRODUCTS ||--o{ CHAT_ROOMS : "negotiated-for"
```

---

## 4. Key Business Workflows & Data Flows

### A. Authentication & Registration Lifecycle
HYPEN supports traditional registration (with 6-digit OTP verification sent via email) and Google OAuth 2.0.

```mermaid
sequenceDiagram
    autonumber
    actor User as User Mobile
    participant Client as Flutter AuthManager
    participant Backend as Express AuthController
    participant Google as Google Auth API
    participant DB as MySQL DB
    participant Mail as Nodemailer SMTP

    %% Local Registration
    Note over User, Mail: Option 1: Local Registration with OTP Verification
    User->>Client: Input Credentials & Register
    Client->>Backend: POST /auth/register
    Backend->>DB: Store pending user, insert OTP into email_verifications
    Backend->>Mail: Send OTP to User's Email
    Backend-->>Client: Return Registration Success (verification required)
    User->>Client: Input OTP from email
    Client->>Backend: POST /auth/verify-email
    Backend->>DB: Validate OTP expiry, set users.isVerified = 1
    Backend-->>Client: Verification Success -> Redirect to Login

    %% Google Sign In
    Note over User, Google: Option 2: Google Social Login Flow
    User->>Client: Tap "Sign In with Google"
    Client->>Google: Retrieve OAuth ID Token
    Google-->>Client: OAuth ID Token returned
    Client->>Backend: POST /auth/google-signin {idToken}
    Backend->>Google: Verify token authenticity (google-auth-library)
    Google-->>Backend: Token payload (email, googleId, username)
    Backend->>DB: Find or create user (isVerified=1, authProvider='google')
    Backend->>Backend: Generate JWT Access & Refresh Token
    Backend-->>Client: Return JWT Tokens & User Metadata
    Client->>Client: Save Access Token to Secure Storage
```

---

### B. Peer-to-Peer Bargaining (Price Negotiation) Flow
Because HYPEN sells secondhand goods, buyers can bargain directly with sellers within a specific chat window.

```mermaid
sequenceDiagram
    autonumber
    actor Buyer as Buyer Client
    participant RestAPI as Backend REST Server
    participant Sockets as Socket.io Server
    participant DB as MySQL DB
    actor Seller as Seller Client

    %% Proposing Price
    Buyer->>RestAPI: POST /chat/negotiate/propose {roomId, price}
    RestAPI->>DB: UPDATE chat_rooms SET proposedPrice=price, negotiationStatus='pending', proposedBy='buyer'
    RestAPI->>DB: INSERT INTO chat_messages (System Message: "Pembeli mengajukan penawaran baru...")
    RestAPI->>Sockets: getIo().to(roomId).emit('new_message')
    RestAPI->>Sockets: getIo().to(roomId).emit('negotiation_update')
    Sockets-->>Buyer: Broadcast system message & updated status
    Sockets-->>Seller: Broadcast system message & updated status

    %% Responding to Price
    Note over Seller, Buyer: Seller decides to accept the proposed price
    Seller->>RestAPI: POST /chat/negotiate/respond {roomId, action: 'accept'}
    RestAPI->>DB: UPDATE chat_rooms SET negotiationStatus='accepted'
    RestAPI->>DB: INSERT INTO chat_messages (System Message: "Penjual menyetujui penawaran harga...")
    RestAPI->>Sockets: getIo().to(roomId).emit('new_message')
    RestAPI->>Sockets: getIo().to(roomId).emit('negotiation_update')
    Sockets-->>Buyer: Broadcast accept message & status 'accepted'
    Sockets-->>Seller: Broadcast accept message & status 'accepted'

    %% Creating Order (Negotiated Price Validation)
    Note over Buyer, DB: Buyer proceeds to checkout product
    Buyer->>RestAPI: POST /order/create {productId}
    RestAPI->>DB: SELECT proposedPrice FROM chat_rooms WHERE buyerId=user AND status='accepted'
    alt Accepted Negotiation exists
        RestAPI->>RestAPI: Set finalPrice = proposedPrice (Overriding original product price)
    else No accepted negotiation
        RestAPI->>RestAPI: Set finalPrice = product.price (Default price)
    end
    RestAPI->>DB: INSERT INTO orders {..., price: finalPrice, status: 'pending'}
    RestAPI-->>Buyer: Order Created Successfully
```

---

### C. Checkout & Payment Flow (Midtrans & RajaOngkir Webhooks)
This flow coordinates domestic shipping cost APIs (RajaOngkir) and payment processing integrations (Midtrans).

```mermaid
sequenceDiagram
    autonumber
    actor Buyer as Buyer Mobile
    participant Backend as Backend Checkout API
    participant RO as RajaOngkir API
    participant DB as MySQL DB
    participant Midtrans as Midtrans API
    actor Admin as Admin Console

    %% Checkout Calculations
    Buyer->>Backend: POST /checkout {orderId, addressId, courierCode, service}
    Backend->>DB: Retrieve Product Origin City & Weight, Destination City
    Backend->>RO: POST /calculate/domestic-cost
    alt RajaOngkir response is successful
        RO-->>Backend: Service cost array
        Backend->>Backend: Select requested service cost
    else RajaOngkir API timeout / failure
        Backend->>Backend: Two-Tier Fallback (1st: RO raw, 2nd: default Rp 15.000)
    end
    Backend->>DB: INSERT INTO shipments {courierCode, cost, status: 'pending'}

    %% Midtrans Payment Link
    Backend->>Midtrans: Call Midtrans Snap SDK to create transaction
    Midtrans-->>Backend: Return Snap Token & Redirect payment SnapUrl
    Backend->>DB: INSERT INTO payments {midtransOrderId, amount, status: 'pending'}
    Backend->>DB: UPDATE orders SET status = 'waiting_payment'
    Backend-->>Buyer: Return SnapUrl & SnapToken
    Buyer->>Buyer: Open SnapUrl inside in-app WebView
    Buyer->>Midtrans: Complete payment (e.g. Bank Transfer, GoPay, QRIS)

    %% Settlement Webhook
    Midtrans->>Backend: POST /payment/webhook (Midtrans payment callback notification)
    alt Status: Settlement / Capture Accept
        Backend->>DB: UPDATE payments SET status = 'paid'
        Backend->>DB: UPDATE orders SET status = 'paid'
    else Status: Expire / Cancel / Deny
        Backend->>DB: UPDATE payments SET status = 'cancelled' / 'expired'
        Backend->>DB: UPDATE orders SET status = 'cancelled'
        Backend->>DB: UPDATE product_sizes SET stock = stock + 1 (Restore inventory)
    end
    Backend-->>Midtrans: Return 200 OK Response

    %% Shipping Process
    Note over Admin, Buyer: Admin ships order & updates status
    Admin->>Backend: PUT /shipping/:shipmentId/status {status: 'delivered'}
    Backend->>DB: UPDATE shipments SET status = 'delivered'
    Backend->>DB: UPDATE orders SET status = 'delivered'
    Backend-->>Buyer: Push Notification / Order Status reflects 'delivered'
```

---

### D. Real-Time Chat & Synchronization Tunnel (WebSockets)
Socket.io keeps message threads alive instantly, updating unread counts and typing indicators.

```mermaid
sequenceDiagram
    autonumber
    actor ClientA as Client A (Buyer)
    participant SocketServer as Socket.io Server
    participant DB as MySQL DB
    actor ClientB as Client B (Seller)

    %% Connection
    ClientA->>SocketServer: connect()
    ClientB->>SocketServer: connect()
    ClientA->>SocketServer: emit('join_room', roomId)
    ClientB->>SocketServer: emit('join_room', roomId)

    %% Message sending
    ClientA->>SocketServer: emit('send_message', {roomId, messageText})
    SocketServer->>DB: INSERT INTO chat_messages (isRead=0, messageText)
    SocketServer->>SocketServer: Broadcast 'new_message' to roomId
    SocketServer-->>ClientB: Receive 'new_message' payload

    %% Typing Status
    ClientB->>SocketServer: emit('typing', {roomId, username})
    SocketServer-->>ClientA: emit('user_typing', {username})
    ClientB->>SocketServer: emit('stop_typing', {roomId})
    SocketServer-->>ClientA: emit('user_stop_typing')

    %% Read receipts
    ClientB->>SocketServer: emit('read_messages', {roomId, userId})
    SocketServer->>DB: UPDATE chat_messages SET isRead=1 WHERE roomId=roomId AND senderId!=userId
    SocketServer-->>ClientA: emit('messages_read', {roomId})
```

---

## 5. Security & Access Control

### JWT Authentication Protocol
1. **Access Tokens**: Short-lived JWT tokens signed using the application's unique `SECRET_KEY` config. Passed via request headers: `Authorization: Bearer <accessToken>`.
2. **Refresh Tokens**: Long-lived session hashes stored in the `refresh_tokens` database table, allowing clients to re-request new credentials without forcing the user to re-authenticate manually.
3. **Database Migration Hooks**: The application automatically inspects schemas and inserts default admin credentials (`admin123@gmail.com` / `admin123`) on bootstrap, securing password mutations using `bcrypt`.

### Role-Based Access Control Matrix

| Route Endpoint | Required Role | Description |
| :--- | :--- | :--- |
| `POST /product/create` | `user`, `seller` | Submits a product to be sold. Default status: `pending`. |
| `PUT /admin/product/:id/approve` | `admin` | Approves a listing, making it visible to public search filters. |
| `GET /admin/payments` | `admin` | Fetches payment history logs across the entire ecosystem. |
| `PUT /admin/shipping/:id/status` | `admin` | Dispatches shipments and flags order statuses to `delivered`. |
| `DELETE /chat/room/:id` | `admin` | Revokes access or purges abusive chat rooms. |

---

## 6. Frontend State & Network Architecture

### Manager Layer (Singleton State Management)
* **AuthManager**: Retains current profile variables (`role`, `isLoggedIn`, `photoUrl`). Clears caches and registers standard notification helpers upon executing `logout()`.
* **ChatManager**: Manages active connection parameters for Socket.io. Synchronously adds messages to local cache objects when receiving incoming events and triggers `markMessagesRead()` requests.
* **ProductManager / AddressManager**: Handles HTTP data caching with explicit `force` refetch triggers to reduce redundant payload sizes over mobile connections.

### Network Interceptors (Dio Service)
The `ApiClient` class acts as the centralized gateway for all API traffic:
1. **Request Interceptor**: Evaluates if a JWT token is stored inside the local Secure Storage key chain, injecting `Authorization: Bearer <token>` on matching requests automatically.
2. **Response Interceptor**: Monitors API health. If a `401 Unauthorized` token expiry response is returned, it intercepts the exception, triggers `AuthManager().logout()`, and cancels the session immediately.
3. **Connection Limits**: Imposes connection timeouts (10s) and receive timeouts (10s) to keep mobile client memory leakages minimal.
