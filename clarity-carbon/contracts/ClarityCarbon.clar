;; ClarityCarbon - Tokenized Carbon Credits Smart Contract
;; This contract allows organizations to mint, trade, and retire carbon credits
;; with transparent tracking and automatic verification.

;; Define contract constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-invalid-project (err u102))
(define-constant err-invalid-credit-amount (err u103))
(define-constant err-insufficient-balance (err u104))
(define-constant err-credit-retired (err u105))

;; Add these constants for input validation
(define-constant max-uint u340282366920938463463374607431768211455)
(define-constant min-project-id u1)

;; Helper function to validate project ID
(define-private (is-valid-project-id (project-id uint))
  (and 
    (>= project-id min-project-id)
    (<= project-id max-uint)
  )
)

;; Define data structures

;; Project represents a carbon offset project
(define-map projects
  { project-id: uint }
  {
    name: (string-ascii 100),
    description: (string-utf8 500),
    location: (string-ascii 100),
    methodology: (string-ascii 100),
    verifier: principal,
    status: (string-ascii 20),
    creation-block: uint,
    total-credits: uint
  }
)

;; Credit ownership tracking
(define-map credit-balances
  { owner: principal, project-id: uint }
  { amount: uint }
)

;; Retired credits tracking
(define-map retired-credits
  { owner: principal, project-id: uint, retirement-id: uint }
  {
    amount: uint,
    retirement-block: uint,
    retirement-note: (string-utf8 200)
  }
)

;; Track total retired credits per project
(define-map project-retired-totals
  { project-id: uint }
  { total-retired: uint }
)

;; Track next retirement ID
(define-data-var next-retirement-id uint u1)

;; Track project verifiers
(define-map verifiers
  { address: principal }
  { name: (string-ascii 100), status: (string-ascii 20) }
)

;; Functions

;; Register a new verifier
(define-public (register-verifier (verifier-address principal) (name (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (is-eq verifier-address tx-sender)) err-not-authorized)
    (asserts! (> (len name) u0) err-invalid-project)
    (map-set verifiers
      { address: verifier-address }
      { name: name, status: "active" }
    )
    (ok true)
  )
)

;; Register a new carbon offset project
(define-public (register-project 
    (project-id uint) 
    (name (string-ascii 100))
    (description (string-utf8 500))
    (location (string-ascii 100))
    (methodology (string-ascii 100))
    (verifier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-valid-project-id project-id) err-invalid-project)
    (asserts! (> (len name) u0) err-invalid-project)
    (asserts! (> (len description) u0) err-invalid-project)
    (asserts! (> (len location) u0) err-invalid-project)
    (asserts! (> (len methodology) u0) err-invalid-project)
    (asserts! (not (is-eq verifier tx-sender)) err-not-authorized)
    ;; Ensure verifier is registered
    (asserts! (is-some (map-get? verifiers { address: verifier })) err-not-authorized)
    (asserts! (is-none (map-get? projects { project-id: project-id })) err-invalid-project)
    (map-set projects
      { project-id: project-id }
      {
        name: name,
        description: description,
        location: location,
        methodology: methodology,
        verifier: verifier,
        status: "pending",
        creation-block: block-height,
        total-credits: u0
      }
    )
    (ok true)
  )
)

;; Verify a project (can only be called by the assigned verifier)
(define-public (verify-project (project-id uint))
  (begin
    (asserts! (is-valid-project-id project-id) err-invalid-project)
    (let ((project (unwrap! (map-get? projects { project-id: project-id }) err-invalid-project)))
      (asserts! (is-eq tx-sender (get verifier project)) err-not-authorized)
      (map-set projects
        { project-id: project-id }
        (merge project { status: "verified" })
      )
      (ok true)
    )
  )
)

;; Mint new carbon credits for a verified project
(define-public (mint-credits (project-id uint) (amount uint))
  (begin
    (asserts! (is-valid-project-id project-id) err-invalid-project)
    (asserts! (> amount u0) err-invalid-credit-amount)
    (let (
      (project (unwrap! (map-get? projects { project-id: project-id }) err-invalid-project))
      (current-balance (default-to { amount: u0 } (map-get? credit-balances { owner: tx-sender, project-id: project-id })))
      )
      ;; Check project is verified
      (asserts! (is-eq (get status project) "verified") err-not-authorized)
      ;; Only project verifier can mint credits
      (asserts! (is-eq tx-sender (get verifier project)) err-not-authorized)
      ;; Amount must be positive
      (asserts! (> amount u0) err-invalid-credit-amount)
      
      ;; Update project total credits
      (map-set projects
        { project-id: project-id }
        (merge project { total-credits: (+ (get total-credits project) amount) })
      )
      
      ;; Update verifier's credit balance
      (map-set credit-balances
        { owner: tx-sender, project-id: project-id }
        { amount: (+ (get amount current-balance) amount) }
      )
      
      (ok true)
    )
  )
)

;; Transfer carbon credits to another principal
(define-public (transfer-credits (project-id uint) (amount uint) (recipient principal))
  (let (
    (sender-balance (default-to { amount: u0 } (map-get? credit-balances { owner: tx-sender, project-id: project-id })))
    (recipient-balance (default-to { amount: u0 } (map-get? credit-balances { owner: recipient, project-id: project-id })))
    )
    
    ;; Check sender has sufficient balance
    (asserts! (>= (get amount sender-balance) amount) err-insufficient-balance)
    ;; Amount must be positive
    (asserts! (> amount u0) err-invalid-credit-amount)
    
    ;; Update sender balance
    (map-set credit-balances
      { owner: tx-sender, project-id: project-id }
      { amount: (- (get amount sender-balance) amount) }
    )
    
    ;; Update recipient balance
    (map-set credit-balances
      { owner: recipient, project-id: project-id }
      { amount: (+ (get amount recipient-balance) amount) }
    )
    
    (ok true)
  )
)

;; Retire carbon credits (permanently remove from circulation)
(define-public (retire-credits (project-id uint) (amount uint) (retirement-note (string-utf8 200)))
  (let (
    (owner-balance (default-to { amount: u0 } (map-get? credit-balances { owner: tx-sender, project-id: project-id })))
    (retirement-id (var-get next-retirement-id))
    (project-retired (default-to { total-retired: u0 } (map-get? project-retired-totals { project-id: project-id })))
    )
    
    ;; Check owner has sufficient balance
    (asserts! (>= (get amount owner-balance) amount) err-insufficient-balance)
    ;; Amount must be positive
    (asserts! (> amount u0) err-invalid-credit-amount)
    
    ;; Update owner balance
    (map-set credit-balances
      { owner: tx-sender, project-id: project-id }
      { amount: (- (get amount owner-balance) amount) }
    )
    
    ;; Record retirement
    (map-set retired-credits
      { owner: tx-sender, project-id: project-id, retirement-id: retirement-id }
      {
        amount: amount,
        retirement-block: block-height,
        retirement-note: retirement-note
      }
    )
    
    ;; Update project retired totals
    (map-set project-retired-totals
      { project-id: project-id }
      { total-retired: (+ (get total-retired project-retired) amount) }
    )
    
    ;; Increment retirement ID counter
    (var-set next-retirement-id (+ retirement-id u1))
    
    (ok retirement-id)
  )
)

;; Read-only functions

;; Get project details
(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

;; Get credit balance for a principal and project
(define-read-only (get-balance (owner principal) (project-id uint))
  (default-to { amount: u0 } (map-get? credit-balances { owner: owner, project-id: project-id }))
)

;; Get retirement details
(define-read-only (get-retirement (owner principal) (project-id uint) (retirement-id uint))
  (map-get? retired-credits { owner: owner, project-id: project-id, retirement-id: retirement-id })
)

;; Get total retired credits for a project
(define-read-only (get-project-retired-total (project-id uint))
  (default-to { total-retired: u0 } (map-get? project-retired-totals { project-id: project-id }))
)

;; Get verifier details
(define-read-only (get-verifier (address principal))
  (map-get? verifiers { address: address })
)
