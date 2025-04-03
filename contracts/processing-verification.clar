;; Processing Verification Contract
;; Validates eco-friendly manufacturing methods

(define-data-var contract-owner principal tx-sender)

;; Data structures
(define-map processing-steps
  { step-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    eco-friendly: bool,
    water-usage: uint,
    energy-usage: uint,
    chemicals-used: (list 10 (string-ascii 50)),
    registered-by: principal,
    registration-date: uint
  }
)

(define-map batch-processing
  { batch-process-id: uint }
  {
    batch-id: uint,
    step-id: uint,
    processor: principal,
    location: (string-ascii 100),
    timestamp: uint,
    verified: bool,
    verifier: (optional principal)
  }
)

(define-data-var last-step-id uint u0)
(define-data-var last-batch-process-id uint u0)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-STEP-EXISTS u101)
(define-constant ERR-STEP-NOT-FOUND u102)
(define-constant ERR-BATCH-PROCESS-EXISTS u103)
(define-constant ERR-BATCH-PROCESS-NOT-FOUND u104)

;; Functions
(define-public (register-processing-step
    (name (string-ascii 50))
    (description (string-ascii 200))
    (eco-friendly bool)
    (water-usage uint)
    (energy-usage uint)
    (chemicals-used (list 10 (string-ascii 50))))
  (let ((new-id (+ (var-get last-step-id) u1)))
    (asserts! (or (is-eq tx-sender (var-get contract-owner))) (err ERR-NOT-AUTHORIZED))
    (map-insert processing-steps
      { step-id: new-id }
      {
        name: name,
        description: description,
        eco-friendly: eco-friendly,
        water-usage: water-usage,
        energy-usage: energy-usage,
        chemicals-used: chemicals-used,
        registered-by: tx-sender,
        registration-date: (unwrap-panic (get-block-info? time u0))
      }
    )
    (var-set last-step-id new-id)
    (ok new-id)
  )
)

(define-public (record-batch-processing (batch-id uint) (step-id uint) (processor principal) (location (string-ascii 100)))
  (let ((new-id (+ (var-get last-batch-process-id) u1)))
    (asserts! (is-some (map-get? processing-steps { step-id: step-id })) (err ERR-STEP-NOT-FOUND))
    (map-insert batch-processing
      { batch-process-id: new-id }
      {
        batch-id: batch-id,
        step-id: step-id,
        processor: processor,
        location: location,
        timestamp: (unwrap-panic (get-block-info? time u0)),
        verified: false,
        verifier: none
      }
    )
    (var-set last-batch-process-id new-id)
    (ok new-id)
  )
)

(define-public (verify-batch-processing (batch-process-id uint))
  (let ((process (unwrap! (map-get? batch-processing { batch-process-id: batch-process-id }) (err ERR-BATCH-PROCESS-NOT-FOUND))))
    (asserts! (or (is-eq tx-sender (var-get contract-owner))) (err ERR-NOT-AUTHORIZED))
    (map-set batch-processing
      { batch-process-id: batch-process-id }
      (merge process {
        verified: true,
        verifier: (some tx-sender)
      })
    )
    (ok true)
  )
)

(define-read-only (get-processing-step (step-id uint))
  (match (map-get? processing-steps { step-id: step-id })
    step (ok step)
    (err ERR-STEP-NOT-FOUND)
  )
)

(define-read-only (get-batch-processing (batch-process-id uint))
  (match (map-get? batch-processing { batch-process-id: batch-process-id })
    process (ok process)
    (err ERR-BATCH-PROCESS-NOT-FOUND)
  )
)

;; Admin functions
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    (var-set contract-owner new-owner)
    (ok true)
  )
)

