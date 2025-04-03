;; Material Sourcing Contract
;; Tracks the origin of fibers and fabrics in the supply chain

(define-data-var contract-owner principal tx-sender)

;; Data structures
(define-map materials
  { material-id: uint }
  {
    name: (string-ascii 50),
    origin: (string-ascii 100),
    harvest-date: uint,
    supplier: principal,
    organic: bool,
    registered-by: principal,
    registration-date: uint
  }
)

(define-map material-batches
  { batch-id: uint }
  {
    material-id: uint,
    quantity: uint,
    quality-grade: (string-ascii 10),
    timestamp: uint
  }
)

(define-data-var last-material-id uint u0)
(define-data-var last-batch-id uint u0)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-MATERIAL-EXISTS u101)
(define-constant ERR-MATERIAL-NOT-FOUND u102)
(define-constant ERR-BATCH-EXISTS u103)
(define-constant ERR-BATCH-NOT-FOUND u104)

;; Functions
(define-public (register-material (name (string-ascii 50)) (origin (string-ascii 100)) (harvest-date uint) (supplier principal) (organic bool))
  (let ((new-id (+ (var-get last-material-id) u1)))
    (asserts! (or (is-eq tx-sender (var-get contract-owner)) (is-eq tx-sender supplier)) (err ERR-NOT-AUTHORIZED))
    (map-insert materials
      { material-id: new-id }
      {
        name: name,
        origin: origin,
        harvest-date: harvest-date,
        supplier: supplier,
        organic: organic,
        registered-by: tx-sender,
        registration-date: (unwrap-panic (get-block-info? time u0))
      }
    )
    (var-set last-material-id new-id)
    (ok new-id)
  )
)

(define-public (register-batch (material-id uint) (quantity uint) (quality-grade (string-ascii 10)))
  (let ((new-id (+ (var-get last-batch-id) u1)))
    (asserts! (is-some (map-get? materials { material-id: material-id })) (err ERR-MATERIAL-NOT-FOUND))
    (map-insert material-batches
      { batch-id: new-id }
      {
        material-id: material-id,
        quantity: quantity,
        quality-grade: quality-grade,
        timestamp: (unwrap-panic (get-block-info? time u0))
      }
    )
    (var-set last-batch-id new-id)
    (ok new-id)
  )
)

(define-read-only (get-material (material-id uint))
  (match (map-get? materials { material-id: material-id })
    material (ok material)
    (err ERR-MATERIAL-NOT-FOUND)
  )
)

(define-read-only (get-batch (batch-id uint))
  (match (map-get? material-batches { batch-id: batch-id })
    batch (ok batch)
    (err ERR-BATCH-NOT-FOUND)
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

