(let ((root (make-pathname :name nil :type nil :defaults *load-truename*)))
  (dolist (file '("src/package.lisp"
	                  "src/tiny-compiler.lisp"
	                  "src/content.lisp"
	                  "src/content-pt-br.lisp"
	                  "src/render.lisp"
                  "src/tests.lisp"))
    (load (merge-pathnames file root)))
  (funcall (read-from-string "lbccl.tests:RUN-TESTS")))

#+sbcl (sb-ext:quit)
