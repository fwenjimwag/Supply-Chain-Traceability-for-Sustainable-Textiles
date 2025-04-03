;; Consumer Verification Contract
;; Allows end users to confirm ethical claims

(define-data-var contract-owner principal tx-sender)

;; Data structures
(define-map product-verifications
  { verification-id: uint }
  {
    product-id: uint,
    qr-code-hash: (buff 32),
    url: (string-ascii 100),
    timestamp: uint
  }
)

(define-map consumer-scans
  { scan-id: uint }
  {
    verification-id: uint,
    consumer: principal,
    timestamp: uint,
    location: (optional (string-ascii 100))
  }
)

(define-map product-feedback
  { feedback-id: uint }
  {
    product-id: uint,
    consumer: principal,
    rating: uint,
    comment: (string-ascii 200),
    timestamp: uint
  }
)

(define-data-var last-verification-id uint u0)
(define-data-var last-scan-id uint u0)
(define-data-var last-feedback-id uint u0)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-VERIFICATION-EXISTS u101)
(define-constant ERR-VERIFICATION-NOT-FOUND u102)
(define-constant ERR-SCAN-EXISTS u103)
(define-constant ERR-SCAN-NOT-FOUND u104)
(define-constant ERR-FEEDBACK-EXISTS u105)
(define-constant ERR-FEEDBACK-NOT-FOUND u106)
(define-constant ERR-INVALID-RATING u107)

;; Functions
(define-public (create-product-verification
    (product-id uint)
    (qr-code-hash (buff 32))
    (url (string-ascii 100)))
  (let ((new-id (+ (var-get last-verification-id) u1)))
    (asserts! (or (is-eq tx-sender (var-get contract-owner))) (err ERR-NOT-AUTHORIZED))
    (map-insert product-verifications
      { verification-id: new-id }
      {
        product-id: product-id,
        qr-code-hash: qr-code-hash,
        url: url,
        timestamp: (unwrap-panic (get-block-info? time u0))
      }
    )
    (var-set last-verification-id new-id)
    (ok new-id)
  )
)

(define-public (record-consumer-scan
    (verification-id uint)
    (location (optional (string-ascii 100))))
  (let ((new-id (+ (var-get last-scan-id) u1)))
    (asserts! (is-some (map-get? product-verifications { verification-id: verification-id })) (err ERR-VERIFICATION-NOT-FOUND))
    (map-insert consumer-scans
      { scan-id: new-id }
      {
        verification-id: verification-id,
        consumer: tx-sender,
        timestamp: (unwrap-panic (get-block-info? time u0)),
        location: location
      }
    )
    (var-set last-scan-id new-id)
    (ok new-id)
  )
)

(define-public (submit-product-feedback
    (product-id uint)
    (rating uint)
    (comment (string-ascii 200)))
  (let ((new-id (+ (var-get last-feedback-id) u1)))
    (asserts! (<= rating u5) (err ERR-INVALID-RATING))
    (map-insert product-feedback
      { feedback-id: new-id }
      {
        product-id: product-id,
        consumer: tx-sender,
        rating: rating,
        comment: comment,
        timestamp: (unwrap-panic (get-block-info? time u0))
      }
    )
    (var-set last-feedback-id new-id)
    (ok new-id)
  )
)

(define-read-only (get-product-verification (verification-id uint))
  (match (map-get? product-verifications { verification-id: verification-id })
    verification (ok verification)
    (err ERR-VERIFICATION-NOT-FOUND)
  )
)

(define-read-only (get-consumer-scan (scan-id uint))
  (match (map-get? consumer-scans { scan-id: scan-id })
    scan (ok scan)
    (err ERR-SCAN-NOT-FOUND)
  )
)

(define-read-only (get-product-feedback (feedback-id uint))
  (match (map-get? product-feedback { feedback-id: feedback-id })
    feedback (ok feedback)
    (err ERR-FEEDBACK-NOT-FOUND)
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

