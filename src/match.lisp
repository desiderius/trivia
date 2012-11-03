(in-package :optima)

(define-condition match-error (error)
  ((values :initarg :values
           :initform nil
           :reader match-error-values)
   (patterns :initarg :patterns
             :initform nil
             :reader match-error-patterns))
  (:report (lambda (condition stream)
             (format stream "Can't match ~S with ~{~S~^ or ~}."
                     (match-error-values condition)
                     (match-error-patterns condition)))))

(defmacro match (arg &body clauses)
  "Matches ARG with CLAUSES. CLAUSES is a list of the form of (PATTERN
. BODY) where PATTERN is a pattern specifier and BODY is an implicit
progn. If ARG is matched with some PATTERN, then evaluates
corresponding BODY and returns the evaluated value. Otherwise, returns
NIL.

If BODY starts with the symbols WHEN or UNLESS, then the next form
will be used to introduce a guard for PATTERN. That is,

    (match list ((list x) when (oddp x) x))
    (match list ((list x) unless (evenp x) x))

will be translated to

    (match list ((and (list x) (when (oddp x))) x))
    (match list ((and (list x) (unless (evenp x))) x))

Evaluating a form (FAIL) in the clause body causes the latest pattern
matching be failed. For example,

    (match 1
      (x (if (eql x 1)
             (fail)
             x))
      (_ 'ok))

returns OK, because the form (FAIL) in the first clause is
evaluated.

Examples:

    (match 1 (1 1))
    => 1
    (match 1 (2 2))
    => 2
    (match 1 (x x))
    => 1
    (match (list 1 2 3)
      (list x y z) (+ x y z))
    => 6"
  (compile-match-1 arg clauses nil))

(defmacro multiple-value-match (values-form &body clauses)
  "Matches the multiple values of VALUES-FORM with CLAUSES. Unlike
MATCH, CLAUSES have to have the form of (PATTERNS . BODY), where
PATTERNS is a list of patterns. The number of values that will be used
to match is determined by the maximum arity of PATTERNS among CLAUSES.

Examples:

    (multiple-value-match (values 1 2)
     ((2) 1)
     ((1 y) y))
    => 2"
  (compile-multiple-value-match values-form clauses nil))

(defmacro ematch (arg &body clauses)
  "Same as MATCH, except MATCH-ERROR will be raised if not matched."
  (let ((else `(error 'match-error
                      :values (list ,arg)
                      :patterns ',(mapcar #'car clauses))))
    (compile-match-1 arg clauses else)))

(defmacro multiple-value-ematch (values-form &body clauses)
  "Same as MULTIPLE-VALUE-MATCH, except MATCH-ERROR will be raised if
not matched."
  (let ((else `(error 'match-error
                      :values (list ,values-form)
                      :patterns ',(mapcar #'car clauses))))
    (compile-multiple-value-match values-form clauses else)))

(defmacro cmatch (arg &body clauses)
  "Same as MATCH, except continuable MATCH-ERROR will be raised if not
matched."
  (let ((else `(cerror "Continue."
                       'match-error
                       :values (list ,arg)
                       :patterns ',(mapcar #'car clauses))))
    (compile-match-1 arg clauses else)))

(defmacro multiple-value-cmatch (values-form &body clauses)
  "Same as MULTIPLE-VALUE-MATCH, except continuable MATCH-ERROR will
be raised if not matched."
  (let ((else `(cerror "Continue."
                       'match-error
                       :values (list ,values-form)
                       :patterns ',(mapcar #'car clauses))))
    (compile-multiple-value-match values-form clauses else)))
