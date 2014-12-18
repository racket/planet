#lang racket
(require setup/dirs
         setup/getinfo)

;; do nothing via 'raco test' because run-all.rkt runs this test
;; and that way we can guarantee they run sequentially in drdr
(module test racket/base)

(define tmp-dir (make-temporary-file "info-domain-test-~a" 'directory))

(define raco (build-path (find-console-bin-dir)
                         (if (eq? 'windows (system-type))
                             "raco.exe"
                             "raco")))

(make-directory (build-path tmp-dir "p1"))
(make-directory (build-path tmp-dir "p2"))

(define (add-info sub)
  (call-with-output-file*
   (build-path tmp-dir sub "info.rkt")
   (lambda (o)
     (display (~a "#lang info\n(define planet-info-domain-test " (~s sub) ")\n")
              o))))

(add-info "p1")
(add-info "p2")

(define (test expected got)
  (unless (equal? expected got)
    (error 'test "failed: ~s vs. ~s" expected got)))

(define (link-one sub)
  (parameterize ([current-directory tmp-dir])
    (test #t
          (system* raco "planet" "create" sub))
    (test #t
          (system* raco "planet" "fileinject" "racket-tester" (~a sub ".plt") "1" "0"))))

(test 0 (length (find-relevant-directories '(planet-info-domain-test))))

(link-one "p1")

(reset-relevant-directories-state!)
(test 1 (length (find-relevant-directories '(planet-info-domain-test))))

(link-one "p2")

(reset-relevant-directories-state!)
(test 2 (length (find-relevant-directories '(planet-info-domain-test))))

(define (unlink-one sub)
  (test #t
        (system* raco "planet" "remove" "racket-tester" (~a sub ".plt") "1" "0")))

(unlink-one "p1")

(reset-relevant-directories-state!)
(test 1 (length (find-relevant-directories '(planet-info-domain-test))))

(unlink-one "p2")

(delete-directory/files tmp-dir)
