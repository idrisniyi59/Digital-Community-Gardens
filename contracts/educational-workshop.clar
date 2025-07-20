;; Educational Workshop Contract
;; Organizes gardening classes and educational events

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-WORKSHOP-NOT-FOUND (err u501))
(define-constant ERR-INVALID-INPUT (err u502))
(define-constant ERR-WORKSHOP-FULL (err u503))
(define-constant ERR-ALREADY-REGISTERED (err u504))
(define-constant ERR-NOT-REGISTERED (err u505))
(define-constant ERR-WORKSHOP-PAST (err u506))

;; Data Variables
(define-data-var next-workshop-id uint u1)

;; Data Maps
(define-map workshops
  { workshop-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 300),
    instructor: principal,
    max-participants: uint,
    current-participants: uint,
    scheduled-date: uint,
    duration-hours: uint,
    location: (string-ascii 100),
    skill-level: (string-ascii 20),
    materials-provided: bool,
    cost-stx: uint,
    status: (string-ascii 20)
  }
)

(define-map workshop-registrations
  { workshop-id: uint, participant: principal }
  {
    registered-at: uint,
    attended: bool,
    feedback-rating: (optional uint),
    feedback-comments: (optional (string-ascii 200))
  }
)

(define-map instructor-profiles
  { instructor: principal }
  {
    name: (string-ascii 50),
    bio: (string-ascii 300),
    specialties: (string-ascii 200),
    workshops-taught: uint,
    average-rating: uint,
    total-ratings: uint
  }
)

(define-map participant-learning
  { participant: principal }
  {
    workshops-attended: uint,
    total-hours-learned: uint,
    skill-areas: (string-ascii 200),
    certificates-earned: uint
  }
)

;; Read-only functions
(define-read-only (get-workshop (workshop-id uint))
  (map-get? workshops { workshop-id: workshop-id })
)

(define-read-only (get-registration (workshop-id uint) (participant principal))
  (map-get? workshop-registrations { workshop-id: workshop-id, participant: participant })
)

(define-read-only (get-instructor-profile (instructor principal))
  (map-get? instructor-profiles { instructor: instructor })
)

(define-read-only (get-participant-learning (participant principal))
  (default-to
    { workshops-attended: u0, total-hours-learned: u0, skill-areas: "", certificates-earned: u0 }
    (map-get? participant-learning { participant: participant })
  )
)

(define-read-only (get-next-workshop-id)
  (var-get next-workshop-id)
)

(define-read-only (is-workshop-available (workshop-id uint))
  (match (map-get? workshops { workshop-id: workshop-id })
    workshop-data (and
      (< (get current-participants workshop-data) (get max-participants workshop-data))
      (> (get scheduled-date workshop-data) block-height)
      (is-eq (get status workshop-data) "scheduled")
    )
    false
  )
)

;; Public functions
(define-public (create-instructor-profile (name (string-ascii 50)) (bio (string-ascii 300)) (specialties (string-ascii 200)))
  (begin
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len bio) u0) ERR-INVALID-INPUT)
    (asserts! (> (len specialties) u0) ERR-INVALID-INPUT)

    (map-set instructor-profiles
      { instructor: tx-sender }
      {
        name: name,
        bio: bio,
        specialties: specialties,
        workshops-taught: u0,
        average-rating: u0,
        total-ratings: u0
      }
    )

    (ok true)
  )
)

(define-public (schedule-workshop
  (title (string-ascii 100))
  (description (string-ascii 300))
  (max-participants uint)
  (days-from-now uint)
  (duration-hours uint)
  (location (string-ascii 100))
  (skill-level (string-ascii 20))
  (materials-provided bool)
  (cost-stx uint))

  (let ((workshop-id (var-get next-workshop-id)))
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)
    (asserts! (> max-participants u0) ERR-INVALID-INPUT)
    (asserts! (<= max-participants u50) ERR-INVALID-INPUT)
    (asserts! (> days-from-now u0) ERR-INVALID-INPUT)
    (asserts! (> duration-hours u0) ERR-INVALID-INPUT)
    (asserts! (> (len location) u0) ERR-INVALID-INPUT)
    (asserts! (> (len skill-level) u0) ERR-INVALID-INPUT)
    (asserts! (is-some (map-get? instructor-profiles { instructor: tx-sender })) ERR-NOT-AUTHORIZED)

    (let ((scheduled-date (+ block-height (* days-from-now u144))))
      (map-set workshops
        { workshop-id: workshop-id }
        {
          title: title,
          description: description,
          instructor: tx-sender,
          max-participants: max-participants,
          current-participants: u0,
          scheduled-date: scheduled-date,
          duration-hours: duration-hours,
          location: location,
          skill-level: skill-level,
          materials-provided: materials-provided,
          cost-stx: cost-stx,
          status: "scheduled"
        }
      )
    )

    (var-set next-workshop-id (+ workshop-id u1))
    (ok workshop-id)
  )
)

(define-public (register-for-workshop (workshop-id uint))
  (let ((workshop-data (unwrap! (map-get? workshops { workshop-id: workshop-id }) ERR-WORKSHOP-NOT-FOUND)))
    (asserts! (is-none (map-get? workshop-registrations { workshop-id: workshop-id, participant: tx-sender })) ERR-ALREADY-REGISTERED)
    (asserts! (< (get current-participants workshop-data) (get max-participants workshop-data)) ERR-WORKSHOP-FULL)
    (asserts! (> (get scheduled-date workshop-data) block-height) ERR-WORKSHOP-PAST)
    (asserts! (is-eq (get status workshop-data) "scheduled") ERR-INVALID-INPUT)

    (map-set workshop-registrations
      { workshop-id: workshop-id, participant: tx-sender }
      {
        registered-at: block-height,
        attended: false,
        feedback-rating: none,
        feedback-comments: none
      }
    )

    (map-set workshops
      { workshop-id: workshop-id }
      (merge workshop-data { current-participants: (+ (get current-participants workshop-data) u1) })
    )

    (ok true)
  )
)

(define-public (mark-attendance (workshop-id uint) (participant principal))
  (let ((workshop-data (unwrap! (map-get? workshops { workshop-id: workshop-id }) ERR-WORKSHOP-NOT-FOUND))
        (registration (unwrap! (map-get? workshop-registrations { workshop-id: workshop-id, participant: participant }) ERR-NOT-REGISTERED)))

    (asserts! (is-eq tx-sender (get instructor workshop-data)) ERR-NOT-AUTHORIZED)

    (map-set workshop-registrations
      { workshop-id: workshop-id, participant: participant }
      (merge registration { attended: true })
    )

    ;; Update participant learning stats
    (let ((learning-stats (get-participant-learning participant)))
      (map-set participant-learning
        { participant: participant }
        (merge learning-stats {
          workshops-attended: (+ (get workshops-attended learning-stats) u1),
          total-hours-learned: (+ (get total-hours-learned learning-stats) (get duration-hours workshop-data))
        })
      )
    )

    (ok true)
  )
)

(define-public (submit-feedback (workshop-id uint) (rating uint) (comments (string-ascii 200)))
  (let ((workshop-data (unwrap! (map-get? workshops { workshop-id: workshop-id }) ERR-WORKSHOP-NOT-FOUND))
        (registration (unwrap! (map-get? workshop-registrations { workshop-id: workshop-id, participant: tx-sender }) ERR-NOT-REGISTERED)))

    (asserts! (get attended registration) ERR-NOT-AUTHORIZED)
    (asserts! (>= rating u1) ERR-INVALID-INPUT)
    (asserts! (<= rating u5) ERR-INVALID-INPUT)

    (map-set workshop-registrations
      { workshop-id: workshop-id, participant: tx-sender }
      (merge registration {
        feedback-rating: (some rating),
        feedback-comments: (some comments)
      })
    )

    ;; Update instructor rating
    (update-instructor-rating (get instructor workshop-data) rating)

    (ok true)
  )
)

(define-public (complete-workshop (workshop-id uint))
  (let ((workshop-data (unwrap! (map-get? workshops { workshop-id: workshop-id }) ERR-WORKSHOP-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get instructor workshop-data)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status workshop-data) "scheduled") ERR-INVALID-INPUT)

    (map-set workshops
      { workshop-id: workshop-id }
      (merge workshop-data { status: "completed" })
    )

    ;; Update instructor stats
    (match (map-get? instructor-profiles { instructor: tx-sender })
      profile (map-set instructor-profiles
        { instructor: tx-sender }
        (merge profile { workshops-taught: (+ (get workshops-taught profile) u1) })
      )
      false
    )

    (ok true)
  )
)

;; Private functions
(define-private (update-instructor-rating (instructor principal) (new-rating uint))
  (match (map-get? instructor-profiles { instructor: instructor })
    profile (let ((current-total (get total-ratings profile))
                  (current-avg (get average-rating profile))
                  (new-total (+ current-total u1))
                  (new-avg (if (> current-total u0)
                    (/ (+ (* current-avg current-total) new-rating) new-total)
                    new-rating)))
      (map-set instructor-profiles
        { instructor: instructor }
        (merge profile {
          average-rating: new-avg,
          total-ratings: new-total
        })
      )
    )
    false
  )
)
