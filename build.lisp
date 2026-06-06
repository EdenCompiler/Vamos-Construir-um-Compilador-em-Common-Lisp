(let ((root (make-pathname :name nil :type nil :defaults *load-truename*)))
  (dolist (file '("src/package.lisp"
	                  "src/tiny-compiler.lisp"
	                  "src/content.lisp"
	                  "src/content-pt-br.lisp"
	                  "src/render.lisp"))
    (load (merge-pathnames file root)))
  (funcall (read-from-string "lbccl.site:BUILD-SITE")
           (merge-pathnames "public/" root)))

#+sbcl (sb-ext:quit)
