
;; title: InstitutionalVote
;; version: 1.0.0
;; summary: A transparent decision-making system for academic policy development and implementation
;; description: This contract enables institutions to create proposals, manage voting processes,
;;              and maintain transparent records of academic policy decisions

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u101))
(define-constant ERR-PROPOSAL-EXPIRED (err u102))
(define-constant ERR-PROPOSAL-NOT-ACTIVE (err u103))
(define-constant ERR-ALREADY-VOTED (err u104))
(define-constant ERR-INVALID-VOTE-TYPE (err u105))
(define-constant ERR-PROPOSAL-ALREADY-EXECUTED (err u106))

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant PROPOSAL-DURATION u144) ;; ~24 hours in blocks (assuming 10 min blocks)

;; Vote types
(define-constant VOTE-YES u1)
(define-constant VOTE-NO u2)
(define-constant VOTE-ABSTAIN u3)

;; Proposal status
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-PASSED u2)
(define-constant STATUS-REJECTED u3)
(define-constant STATUS-EXECUTED u4)

;; Data variables
(define-data-var proposal-counter uint u0)
(define-data-var admin principal CONTRACT-OWNER)

;; Data maps
;; Institutional roles - who can create proposals and vote
(define-map institutional-members principal bool)

;; Proposal details
(define-map proposals uint {
    id: uint,
    title: (string-ascii 100),
    description: (string-ascii 500),
    proposer: principal,
    start-block: uint,
    end-block: uint,
    yes-votes: uint,
    no-votes: uint,
    abstain-votes: uint,
    status: uint,
    executed: bool
})

;; Track individual votes to prevent double voting
(define-map votes {proposal-id: uint, voter: principal} uint)

;; Track voting power (can be used for weighted voting in future versions)
(define-map voting-power principal uint)

;; Authorization functions
(define-private (is-admin (user principal))
    (is-eq user (var-get admin)))

(define-private (is-institutional-member (user principal))
    (default-to false (map-get? institutional-members user)))

;; Admin functions
(define-public (add-institutional-member (member principal))
    (begin
        (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
        (map-set institutional-members member true)
        (map-set voting-power member u1)
        (ok true)))

(define-public (remove-institutional-member (member principal))
    (begin
        (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
        (map-delete institutional-members member)
        (map-delete voting-power member)
        (ok true)))

(define-public (set-voting-power (member principal) (power uint))
    (begin
        (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
        (asserts! (is-institutional-member member) ERR-NOT-AUTHORIZED)
        (map-set voting-power member power)
        (ok true)))

;; Proposal management functions
(define-public (create-proposal (title (string-ascii 100)) (description (string-ascii 500)))
    (let ((proposal-id (+ (var-get proposal-counter) u1))
          (start-block block-height)
          (end-block (+ block-height PROPOSAL-DURATION)))
        (asserts! (is-institutional-member tx-sender) ERR-NOT-AUTHORIZED)
        (map-set proposals proposal-id {
            id: proposal-id,
            title: title,
            description: description,
            proposer: tx-sender,
            start-block: start-block,
            end-block: end-block,
            yes-votes: u0,
            no-votes: u0,
            abstain-votes: u0,
            status: STATUS-ACTIVE,
            executed: false
        })
        (var-set proposal-counter proposal-id)
        (ok proposal-id)))

(define-public (vote-on-proposal (proposal-id uint) (vote-type uint))
    (let ((proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
          (voter-power (default-to u1 (map-get? voting-power tx-sender))))
        (asserts! (is-institutional-member tx-sender) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status proposal) STATUS-ACTIVE) ERR-PROPOSAL-NOT-ACTIVE)
        (asserts! (<= block-height (get end-block proposal)) ERR-PROPOSAL-EXPIRED)
        (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: tx-sender})) ERR-ALREADY-VOTED)
        (asserts! (or (is-eq vote-type VOTE-YES) (or (is-eq vote-type VOTE-NO) (is-eq vote-type VOTE-ABSTAIN))) ERR-INVALID-VOTE-TYPE)

        ;; Record the vote
        (map-set votes {proposal-id: proposal-id, voter: tx-sender} vote-type)

        ;; Update vote counts
        (if (is-eq vote-type VOTE-YES)
            (map-set proposals proposal-id (merge proposal {yes-votes: (+ (get yes-votes proposal) voter-power)}))
            (if (is-eq vote-type VOTE-NO)
                (map-set proposals proposal-id (merge proposal {no-votes: (+ (get no-votes proposal) voter-power)}))
                (map-set proposals proposal-id (merge proposal {abstain-votes: (+ (get abstain-votes proposal) voter-power)}))))
        (ok true)))

(define-public (finalize-proposal (proposal-id uint))
    (let ((proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND)))
        (asserts! (> block-height (get end-block proposal)) ERR-PROPOSAL-NOT-ACTIVE)
        (asserts! (is-eq (get status proposal) STATUS-ACTIVE) ERR-PROPOSAL-NOT-ACTIVE)

        (let ((yes-votes (get yes-votes proposal))
              (no-votes (get no-votes proposal))
              (total-votes (+ yes-votes no-votes))
              (new-status (if (> yes-votes no-votes) STATUS-PASSED STATUS-REJECTED)))
            (map-set proposals proposal-id (merge proposal {status: new-status}))
            (ok new-status))))

(define-public (execute-proposal (proposal-id uint))
    (let ((proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND)))
        (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status proposal) STATUS-PASSED) ERR-PROPOSAL-NOT-ACTIVE)
        (asserts! (not (get executed proposal)) ERR-PROPOSAL-ALREADY-EXECUTED)

        (map-set proposals proposal-id (merge proposal {executed: true, status: STATUS-EXECUTED}))
        (ok true)))

;; Read-only functions for transparency
(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals proposal-id))

(define-read-only (get-proposal-count)
    (var-get proposal-counter))

(define-read-only (get-vote (proposal-id uint) (voter principal))
    (map-get? votes {proposal-id: proposal-id, voter: voter}))

(define-read-only (is-member (user principal))
    (is-institutional-member user))

(define-read-only (get-voting-power (member principal))
    (map-get? voting-power member))

(define-read-only (get-admin)
    (var-get admin))

(define-read-only (can-vote (proposal-id uint) (voter principal))
    (match (map-get? proposals proposal-id)
        proposal (and
                    (is-institutional-member voter)
                    (is-eq (get status proposal) STATUS-ACTIVE)
                    (<= block-height (get end-block proposal))
                    (is-none (map-get? votes {proposal-id: proposal-id, voter: voter})))
        false))

(define-read-only (get-proposal-results (proposal-id uint))
    (match (map-get? proposals proposal-id)
        proposal (some {
            id: (get id proposal),
            title: (get title proposal),
            yes-votes: (get yes-votes proposal),
            no-votes: (get no-votes proposal),
            abstain-votes: (get abstain-votes proposal),
            total-votes: (+ (+ (get yes-votes proposal) (get no-votes proposal)) (get abstain-votes proposal)),
            status: (get status proposal),
            executed: (get executed proposal)
        })
        none))

;; Initialize the contract owner as the first institutional member
(map-set institutional-members CONTRACT-OWNER true)
(map-set voting-power CONTRACT-OWNER u1)
