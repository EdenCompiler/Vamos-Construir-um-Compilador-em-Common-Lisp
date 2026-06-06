(in-package #:lbccl.tests)

(defun assert-equal (expected actual label)
  (unless (equal expected actual)
    (error "~A expected ~S, got ~S" label expected actual)))

(defun assert-true (value label)
  (unless value
    (error "~A expected true" label)))

(defun outputs (source)
  (multiple-value-bind (output environment)
      (run-source source)
    (declare (ignore environment))
    output))

(defun read-forms-from-string (source label)
  (declare (ignore label))
  (let ((end (gensym "END")))
    (with-input-from-string (stream source)
      (loop for form = (read stream nil end)
            until (eq form end)
            collect form))))

(defun package-name-for-example (lesson-index section-index)
  (format nil "LBCCL.EXAMPLE.~D.~D" lesson-index section-index))

(defun evaluate-example-code (code lesson-index section-index)
  (let* ((package-name (package-name-for-example lesson-index section-index))
         (existing-package (find-package package-name)))
    (when existing-package
      (delete-package existing-package))
    (let ((package (make-package package-name :use '(:cl))))
      (unwind-protect
           (let ((*package* package))
             (dolist (form (read-forms-from-string
                            code
                            (format nil "lesson ~D section ~D" lesson-index section-index)))
               (eval form)))
        (delete-package package)))))

(defun lesson-sets ()
  `((:en . ,*lessons*)
    (:pt-br . ,*lessons-pt-br*)))

(defun test-lesson-examples ()
  (dolist (lesson-set (lesson-sets))
    (let ((language (car lesson-set))
          (lessons (cdr lesson-set)))
      (loop for lesson in lessons
            for lesson-index from 1 do
              (loop for section in (lesson-sections lesson)
                    for section-index from 1
                    for code = (lbccl.content:section-code section)
                    when code do
                      (handler-case
                          (evaluate-example-code code lesson-index section-index)
                        (error (condition)
                          (error "Example failed in ~A lesson ~D, section ~D (~A): ~A"
                                 language
                                 lesson-index
                                 section-index
                                 (lbccl.content:section-heading section)
                                 condition))))))))

(defun test-localized-course-shape ()
  (assert-equal (length *lessons*)
                (length *lessons-pt-br*)
                "Portuguese lesson count")
  (assert-equal (mapcar #'lbccl.content:lesson-slug *lessons*)
                (mapcar #'lbccl.content:lesson-slug *lessons-pt-br*)
                "Portuguese lesson slugs match English")
  (loop for english in *lessons*
        for portuguese in *lessons-pt-br* do
          (assert-equal (mapcar #'lbccl.content:section-code
                                (lesson-sections english))
                        (mapcar #'lbccl.content:section-code
                                (lesson-sections portuguese))
                        "Portuguese examples reuse tested Common Lisp code")))

(defun test-localized-site-build ()
  (let ((output #p"/tmp/lbccl-site-test/"))
    (funcall (read-from-string "lbccl.site:BUILD-SITE") output)
    (dolist (file '("index.html"
                    "compiler.html"
                    "introduction.html"
                    "pt-br/index.html"
                    "pt-br/compiler.html"
                    "pt-br/introduction.html"
                    "assets/pipeline.png"))
      (assert-true (probe-file (merge-pathnames file output))
                   (format nil "generated ~A" file)))))

(defun count-source-forms (pathname)
  (let ((end (gensym "END"))
        (count 0))
    (with-open-file (stream pathname :direction :input)
      (loop for form = (read stream nil end)
            until (eq form end) do
              (incf count)))
    count))

(defun test-full-compiler-source ()
  (assert-true (> (count-source-forms #p"src/tiny-compiler.lisp") 0)
               "full compiler source can be read")
  (assert-equal '(14 3 2)
                (outputs
                 "print 2 + 3 * 4;
                  print 9 / 3;
                  if 1 != 0 then
                    print 2;
                  else
                    print 0;
                  end")
                "full compiler source behavior"))

(defun run-tests ()
  (let ((tokens (scan "let x = 12 + 3; # comentario")))
    (assert-equal '("let" "x" "=" "12" "+" "3" ";" "")
                  (mapcar #'lbccl.compiler:token-text tokens)
                  "scanner token texts"))
  (assert-true (parse (scan "print 1 + 2 * 3;"))
               "parser returns an AST")
  (assert-equal '((:push 1) (:push 2) (:push 3) (:multiply) (:add) (:print))
                (compile-source "print 1 + 2 * 3;")
                "bytecode precedence")
  (assert-equal '(7)
                (outputs "let x = 1 + 2 * 3; print x;")
                "arithmetic output")
  (assert-equal '(120)
                (outputs
                 "let n = 5;
                  let acc = 1;
                  while n > 1 do
                    acc = acc * n;
                    n = n - 1;
                  end
                  print acc;")
                "while factorial")
  (assert-equal '(10)
                (outputs
                 "let x = 4;
                  if x > 5 then
                    print 1;
                  else
                    print 10;
                  end")
                "if else branch")
  (assert-true (>= (length *lessons*) 16)
               "course has the classic-scale lesson map")
  (dolist (lesson *lessons*)
    (assert-true (lesson-sections lesson)
                 "lesson has sections"))
  (test-localized-course-shape)
  (test-lesson-examples)
  (test-full-compiler-source)
  (test-localized-site-build)
  (format t "All LBCCL tests passed.~%"))
