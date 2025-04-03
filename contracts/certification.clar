;; Certification Contract
;; Verifies compliance with sustainability standards

(define-data-var contract-owner principal tx-sender)

;; Data structures
(define-map standards
  { standard-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    criteria: (list 10 (string-ascii 100)),
    issuing-body: (string-ascii 100),
    registered-by: principal,
    registration-date: uint
  }
)

(define-map certifications
  { certification-id: uint }
  {
    product-id: uint,
    standard-id: uint,
    issue-date: uint,
    expiry-date: uint,
    certifier: principal,
    certification-proof: (string-ascii 200),
    active: bool
  }
)

(define-map products
  { product-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    manufacturer: principal,
    batch-ids: (list 10 uint),
    registered-by: principal,
    registration-date: uint
  }
)

(define-data-var last-standard-id uint u0)
(define-data-var last-certification-id uint u0)
(define-data-var last-product-id uint u0)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-STANDARD-EXISTS u101)
(define-constant ERR-STANDARD-NOT-FOUND u102)
(define-constant ERR-CERTIFICATION-EXISTS u103)
(define-constant ERR-CERTIFICATION-NOT-FOUND u104)
(define-constant ERR-PRODUCT-EXISTS u105)
(define-constant ERR-PRODUCT-NOT-FOUND u106)

;; Functions
(define-public (register-standard
    (name (string-ascii 50))
    (description (string-ascii 200))
    (criteria (list 10 (string-ascii 100)))
    (issuing-body (string-ascii 100)))
  (let ((new-id (+ (var-get last-standard-id) u1)))
    (asserts! (or (is-eq tx-sender (var-get contract-owner))) (err ERR-NOT-AUTHORIZED))
    (map-insert standards
      { standard-id: new-id }
      {
        name: name,
        description: description,
        criteria: criteria,
        issuing-body: issuing-body,
        registered-by: tx-sender,
        registration-date: (unwrap-panic (get-block-info? time u0))
      }
    )
    (var-set last-standard-id new-id)
    (ok new-id)
  )
)

(define-public (register-product
    (name (string-ascii 50))
    (description (string-ascii 200))
    (manufacturer principal)
    (batch-ids (list 10 uint)))
  (let ((new-id (+ (var-get last-product-id) u1)))
    (asserts! (or (is-eq tx-sender (var-get contract-owner)) (is-eq tx-sender manufacturer)) (err ERR-NOT-AUTHORIZED))
    (map-insert products
      { product-id: new-id }
      {
        name: name,
        description: description,
        manufacturer: manufacturer,
        batch-ids: batch-ids,
        registered-by: tx-sender,
        registration-date: (unwrap-panic (get-block-info? time u0))
      }
    )
    (var-set last-product-id new-id)
    (ok new-id)
  )
)

(define-public (issue-certification
    (product-id uint)
    (standard-id uint)
    (expiry-date uint)
    (certification-proof (string-ascii 200)))
  (let ((new-id (+ (var-get last-certification-id) u1)))
    (asserts! (or (is-eq tx-sender (var-get contract-owner))) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-some (map-get? standards { standard-id: standard-id })) (err ERR-STANDARD-NOT-FOUND))
    (asserts! (is-some (map-get? products { product-id: product-id })) (err ERR-PRODUCT-NOT-FOUND))
    (map-insert certifications
      { certification-id: new-id }
      {
        product-id: product-id,
        standard-id: standard-id,
        issue-date: (unwrap-panic (get-block-info? time u0)),
        expiry-date: expiry-date,
        certifier: tx-sender,
        certification-proof: certification-proof,
        active: true
      }
    )
    (var-set last-certification-id new-id)
    (ok new-id)
  )
)

(define-public (revoke-certification (certification-id uint))
  (let ((cert (unwrap! (map-get? certifications { certification-id: certification-id }) (err ERR-CERTIFICATION-NOT-FOUND))))
    (asserts! (or (is-eq tx-sender (var-get contract-owner)) (is-eq tx-sender (get certifier cert))) (err ERR-NOT-AUTHORIZED))
    (map-set certifications
      { certification-id: certification-id }
      (merge cert { active: false })
    )
    (ok true)
  )
)

(define-read-only (get-standard (standard-id uint))
  (match (map-get? standards { standard-id: standard-id })
    standard (ok standard)
    (err ERR-STANDARD-NOT-FOUND)
  )
)

(define-read-only (get-product (product-id uint))
  (match (map-get? products { product-id: product-id })
    product (ok product)
    (err ERR-PRODUCT-NOT-FOUND)
  )
)

(define-read-only (get-certification (certification-id uint))
  (match (map-get? certifications { certification-id: certification-id })
    certification (ok certification)
    (err ERR-CERTIFICATION-NOT-FOUND)
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

