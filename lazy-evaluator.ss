#lang scheme ; File lazy-evaluator.ss
#|
Syntax: (ev term) -> value of the term
Curries the term and evaluates it in the current environment. Free variables are allowed and self-evaluating. When an application is evaluated, the operator must be a function. The actual-argument is not evaluated, but wrapped in a promise. The value of an abstraction is a procedure of one argument. If this procedure receives a promise for its argument, the promise will be forced when needed.

Syntax: (def var term)
First evaluates the term in the current environment, then adds the binding (var value-of-term) to the current environment. It is allowed to shadow an existing binding.

Procedure (list-env) -> list of variables
Returns the list of all variables bound in the current environment. Shadowed variables are included.

(clear-env) -> void
Clears the current environment.

|#
(provide ev def list-env list-vars clear-env)

(define-syntax ev
 (syntax-rules ()
  ((_ x) (ev-aux 'x env))))

(define-syntax (def stx)
 (syntax-case stx ()
  ((_ var x)
 #'(extend-env 'var (let ((e env)) (lazy (ev-aux 'x e)))))))

(define (ev-aux x env)
 (cond
  ((var? x) (force (lookup x env)))
  ((abstr? x) (make-fun (cadr x) (caddr x) env))
  ((appl? x) (make-appl (ev-aux (car x) env) (cdr x) env))
  (else (error 'ev "incorrect (sub)term ~s" x))))

(define (abstr? x)
 (and
  (list? x)
  (= (length x) 3)
  (eq? (car x) 'λ)
  (formals? (cadr x))))

(define (formals? x)
 (and
  (list? x)
  (andmap var? x)))

(define (appl? x)
 (and
  (list? x)
  (pair? x)
  (not (eq? (car x) 'λ))))

(define (lookup var env)
 (let ((binding (assq var env)))
  (if binding (cdr binding) var)))

(define (make-fun vars body env)
 (if (null? vars) (ev-aux body env)
  (let ((var (car vars)) (vars (cdr vars)))
   (λ (x) (make-fun vars body (cons (cons var x) env))))))

(define (make-appl op args env)
 (if (null? args) op
  (let ((arg (car args)) (args (cdr args)))
   (make-appl (op (lazy (ev-aux arg env))) args env))))

(define env '())
(define (clear-env) (set! env '()))
(define (list-vars) (map car env))
(define (list-env) env)
(define (extend-env var value) (set! env (cons (cons var value) env)))
(define (var? x) (and (symbol? x) (not (eq? x 'λ))))

