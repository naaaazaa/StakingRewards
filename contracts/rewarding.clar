;; Staking Rewards Token Contract
;; A smart contract for staking tokens and earning rewards over time

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-insufficient-balance (err u103))
(define-constant err-no-stake (err u104))
(define-constant err-contract-paused (err u105))

;; Data Variables
(define-data-var contract-paused bool false)
(define-data-var total-staked uint u0)
(define-data-var reward-rate uint u100) ;; 1% per period (in basis points)
(define-data-var min-stake-amount uint u1000000) ;; 1 token (6 decimals)
(define-data-var reward-pool uint u0)

;; Data Maps
(define-map stakes 
  principal 
  {
    amount: uint,
    start-block: uint,
    last-claim-block: uint
  }
)

(define-map user-rewards principal uint)

;; SIP-010 Token Trait (simplified)
(define-trait sip-010-token
  (
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    (get-balance (principal) (response uint uint))
  )
)

;; Private Functions

(define-private (calculate-rewards (staker principal) (current-block uint))
  (match (map-get? stakes staker)
    stake-info
    (let
      (
        (blocks-since-last-claim (- current-block (get last-claim-block stake-info)))
        (staked-amount (get amount stake-info))
        (reward-per-block (/ (* staked-amount (var-get reward-rate)) u10000))
      )
      (* reward-per-block blocks-since-last-claim)
    )
    u0
  )
)

(define-private (update-user-rewards (staker principal))
  (let
    (
      (current-rewards (default-to u0 (map-get? user-rewards staker)))
      (new-rewards (calculate-rewards staker block-height))
      (total-rewards (+ current-rewards new-rewards))
    )
    (map-set user-rewards staker total-rewards)
    total-rewards
  )
)

;; Public Functions

;; Stake tokens
(define-public (stake (amount uint))
  (let
    (
      (staker tx-sender)
      (current-stake (default-to {amount: u0, start-block: u0, last-claim-block: u0} 
                                 (map-get? stakes staker)))
    )
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (>= amount (var-get min-stake-amount)) err-invalid-amount)
    
    ;; Update rewards before modifying stake
    (update-user-rewards staker)
    
    ;; Update stake information
    (map-set stakes staker 
      {
        amount: (+ (get amount current-stake) amount),
        start-block: (if (is-eq (get amount current-stake) u0) block-height (get start-block current-stake)),
        last-claim-block: block-height
      }
    )
    
    ;; Update total staked
    (var-set total-staked (+ (var-get total-staked) amount))
    
    (ok amount)
  )
)

;; Unstake tokens
(define-public (unstake (amount uint))
  (let
    (
      (staker tx-sender)
      (stake-info (unwrap! (map-get? stakes staker) err-no-stake))
      (staked-amount (get amount stake-info))
    )
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (<= amount staked-amount) err-insufficient-balance)
    
    ;; Update rewards before modifying stake
    (update-user-rewards staker)
    
    ;; Update stake information
    (if (is-eq amount staked-amount)
      ;; Remove stake completely
      (map-delete stakes staker)
      ;; Reduce stake amount
      (map-set stakes staker 
        {
          amount: (- staked-amount amount),
          start-block: (get start-block stake-info),
          last-claim-block: block-height
        }
      )
    )
    
    ;; Update total staked
    (var-set total-staked (- (var-get total-staked) amount))
    
    (ok amount)
  )
)

;; Claim rewards
(define-public (claim-rewards)
  (let
    (
      (staker tx-sender)
      (stake-info (unwrap! (map-get? stakes staker) err-no-stake))
      (current-rewards (calculate-rewards staker block-height))
      (total-rewards (+ current-rewards (default-to u0 (map-get? user-rewards staker))))
    )
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (> total-rewards u0) err-invalid-amount)
    (asserts! (>= (var-get reward-pool) total-rewards) err-insufficient-balance)
    
    ;; Update last claim block
    (map-set stakes staker 
      (merge stake-info {last-claim-block: block-height})
    )
    
    ;; Reset user rewards
    (map-delete user-rewards staker)
    
    ;; Reduce reward pool
    (var-set reward-pool (- (var-get reward-pool) total-rewards))
    
    (ok total-rewards)
  )
)

;; Add to reward pool (owner only)
(define-public (add-to-reward-pool (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set reward-pool (+ (var-get reward-pool) amount))
    (ok amount)
  )
)

;; Update reward rate (owner only)
(define-public (set-reward-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set reward-rate new-rate)
    (ok new-rate)
  )
)

;; Update minimum stake amount (owner only)
(define-public (set-min-stake-amount (new-amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set min-stake-amount new-amount)
    (ok new-amount)
  )
)

;; Pause/unpause contract (owner only)
(define-public (set-contract-paused (paused bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set contract-paused paused)
    (ok paused)
  )
)

;; Read-only Functions

(define-read-only (get-stake-info (staker principal))
  (map-get? stakes staker)
)

(define-read-only (get-pending-rewards (staker principal))
  (let
    (
      (current-rewards (calculate-rewards staker block-height))
      (accumulated-rewards (default-to u0 (map-get? user-rewards staker)))
    )
    (+ current-rewards accumulated-rewards)
  )
)

(define-read-only (get-total-staked)
  (var-get total-staked)
)

(define-read-only (get-reward-rate)
  (var-get reward-rate)
)

(define-read-only (get-min-stake-amount)
  (var-get min-stake-amount)
)

(define-read-only (get-reward-pool)
  (var-get reward-pool)
)

(define-read-only (is-contract-paused)
  (var-get contract-paused)
)

(define-read-only (get-contract-owner)
  contract-owner
)