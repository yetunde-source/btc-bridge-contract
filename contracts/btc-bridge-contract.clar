;; title: btc-bridge-contract
;; summary: Enables secure cross-chain transfers between Bitcoin and Stacks networks
;; description: This contract facilitates the secure transfer of assets between the Bitcoin and Stacks blockchains. It includes functionality for initiating and confirming deposits, managing validators, and handling withdrawals. The contract ensures the integrity and security of cross-chain transactions through a series of validation checks and error handling mechanisms.

;; traits
(define-trait bridgeable-token-trait
    (
        (transfer (uint principal principal) (response bool uint))
        (get-balance (principal) (response uint uint))
    )
)


;; constants
;; Error codes
(define-constant ERROR-NOT-AUTHORIZED u1000)
(define-constant ERROR-INVALID-AMOUNT u1001)
(define-constant ERROR-INSUFFICIENT-BALANCE u1002)
(define-constant ERROR-INVALID-BRIDGE-STATUS u1003)
(define-constant ERROR-INVALID-SIGNATURE u1004)
(define-constant ERROR-ALREADY-PROCESSED u1005)
(define-constant ERROR-BRIDGE-PAUSED u1006)
(define-constant ERROR-INVALID-VALIDATOR-ADDRESS u1007)
(define-constant ERROR-INVALID-RECIPIENT-ADDRESS u1008)
(define-constant ERROR-INVALID-BTC-ADDRESS u1009)
(define-constant ERROR-INVALID-TX-HASH u1010)
(define-constant ERROR-INVALID-SIGNATURE-FORMAT u1011)

;; Constants
(define-constant CONTRACT-DEPLOYER tx-sender)
(define-constant MIN-DEPOSIT-AMOUNT u100000)
(define-constant MAX-DEPOSIT-AMOUNT u1000000000)
(define-constant REQUIRED-CONFIRMATIONS u6)

;; data vars
(define-data-var bridge-paused bool false)
(define-data-var total-bridged-amount uint u0)
(define-data-var last-processed-height uint u0)

;; data maps
(define-map deposits 
    { tx-hash: (buff 32) }
    {
        amount: uint,
        recipient: principal,
        processed: bool,
        confirmations: uint,
        timestamp: uint,
        btc-sender: (buff 33)
    }
)

(define-map validators principal bool)
(define-map validator-signatures
    { tx-hash: (buff 32), validator: principal }
    { signature: (buff 65), timestamp: uint }
)

(define-map bridge-balances principal uint)

;; public functions
;; Initializes the bridge by setting the paused state to false. Only the contract deployer can call this function.
(define-public (initialize-bridge)
    (begin
        (asserts! (is-eq tx-sender CONTRACT-DEPLOYER) (err ERROR-NOT-AUTHORIZED))
        (var-set bridge-paused false)
        (ok true)
    )
)

;; Pauses the bridge. Only the contract deployer can call this function.
(define-public (pause-bridge)
    (begin
        (asserts! (is-eq tx-sender CONTRACT-DEPLOYER) (err ERROR-NOT-AUTHORIZED))
        (var-set bridge-paused true)
        (ok true)
    )
)

;; Resumes the bridge if it is paused. Only the contract deployer can call this function.
(define-public (resume-bridge)
    (begin
        (asserts! (is-eq tx-sender CONTRACT-DEPLOYER) (err ERROR-NOT-AUTHORIZED))
        (asserts! (var-get bridge-paused) (err ERROR-INVALID-BRIDGE-STATUS))
        (var-set bridge-paused false)
        (ok true)
    )
)

;; Adds a validator to the bridge. Only the contract deployer can call this function.
(define-public (add-validator (validator principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-DEPLOYER) (err ERROR-NOT-AUTHORIZED))
        (asserts! (is-valid-principal validator) (err ERROR-INVALID-VALIDATOR-ADDRESS))
        (map-set validators validator true)
        (ok true)
    )
)

;; Removes a validator from the bridge. Only the contract deployer can call this function.
(define-public (remove-validator (validator principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-DEPLOYER) (err ERROR-NOT-AUTHORIZED))
        (asserts! (is-valid-principal validator) (err ERROR-INVALID-VALIDATOR-ADDRESS))
        (map-set validators validator false)
        (ok true)
    )
)