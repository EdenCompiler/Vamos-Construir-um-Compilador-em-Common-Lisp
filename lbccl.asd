(asdf:defsystem #:lbccl
  :description "A Common Lisp static site generator and companion compiler for Let's Build a Compiler in Common Lisp."
  :author "Bruno"
  :license "MIT"
  :serial t
  :components
  ((:file "src/package")
	   (:file "src/tiny-compiler")
	   (:file "src/content")
	   (:file "src/content-pt-br")
	   (:file "src/render")))

(asdf:defsystem #:lbccl/tests
  :depends-on (#:lbccl)
  :serial t
  :components
  ((:file "src/tests")))
