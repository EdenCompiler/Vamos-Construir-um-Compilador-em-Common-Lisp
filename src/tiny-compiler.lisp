(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package "LBCCL.COMPILER")
    (defpackage #:lbccl.compiler
      (:use #:cl)
      (:export
       #:scan
       #:parse
       #:compile-source
       #:compile-program
       #:run-bytecode
       #:run-source
       #:token
       #:token-kind
       #:token-text
       #:token-value
       #:token-position
       #:standalone-main))))

(in-package #:lbccl.compiler)

(defstruct token kind text value position)

(defparameter *keywords*
  '("let" "print" "if" "then" "else" "end" "while" "do"))

(defparameter *two-character-symbols*
  '("<=" ">=" "==" "!="))

(defparameter *single-character-symbols*
  "+-*/()=;<>")

(define-condition compiler-error (error)
  ((position :initarg :position :reader compiler-error-position)
   (message :initarg :message :reader compiler-error-message))
  (:report (lambda (condition stream)
             (format stream "~A at character ~D"
                     (compiler-error-message condition)
                     (compiler-error-position condition)))))

(defun fail-at (position control &rest arguments)
  (error 'compiler-error
         :position position
         :message (apply #'format nil control arguments)))

(defun identifier-character-p (character)
  (or (alphanumericp character)
      (char= character #\_)))

(defun scan (source)
  "Turn SOURCE into a list of token structures."
  (let ((length (length source))
        (index 0)
        (tokens '()))
    (labels ((at-end-p ()
               (>= index length))
             (peek ()
               (unless (at-end-p)
                 (char source index)))
             (peek-next ()
               (let ((next (1+ index)))
                 (when (< next length)
                   (char source next))))
             (advance ()
               (prog1 (peek)
                 (incf index)))
             (emit (kind text value position)
               (push (make-token :kind kind
                                 :text text
                                 :value value
                                 :position position)
                     tokens))
             (skip-line-comment ()
               (loop until (or (at-end-p) (char= (peek) #\Newline))
                     do (advance))))
      (loop until (at-end-p) do
        (let ((character (peek)))
          (cond
            ((find character '(#\Space #\Tab #\Newline #\Return))
             (advance))
            ((char= character #\#)
             (skip-line-comment))
            ((digit-char-p character)
             (let ((start index))
               (loop while (and (not (at-end-p)) (digit-char-p (peek)))
                     do (advance))
               (let ((text (subseq source start index)))
                 (emit :integer text (parse-integer text) start))))
            ((alpha-char-p character)
             (let ((start index))
               (loop while (and (not (at-end-p))
                                (identifier-character-p (peek)))
                     do (advance))
               (let* ((text (string-downcase (subseq source start index)))
                      (kind (if (member text *keywords* :test #'string=)
                                :keyword
                                :identifier)))
                 (emit kind text text start))))
            ((and (peek-next)
                  (member (coerce (list character (peek-next)) 'string)
                          *two-character-symbols*
                          :test #'string=))
             (let ((start index)
                   (text (coerce (list character (peek-next)) 'string)))
               (advance)
               (advance)
               (emit :symbol text text start)))
            ((find character *single-character-symbols*)
             (let ((start index)
                   (text (string character)))
               (advance)
               (emit :symbol text text start)))
            (t
             (fail-at index "Unexpected character ~S" character)))))
      (emit :eof "" nil index)
      (nreverse tokens))))

(defun parse (tokens)
  "Parse TOKENS into a small AST."
  (let* ((stream (coerce tokens 'vector))
         (position 0)
         (length (length stream)))
    (labels ((current ()
               (aref stream (min position (1- length))))
             (current-kind ()
               (token-kind (current)))
             (current-text ()
               (token-text (current)))
             (current-position ()
               (token-position (current)))
             (keyword-p (text)
               (and (eq (current-kind) :keyword)
                    (string= (current-text) text)))
             (symbol-p (text)
               (and (eq (current-kind) :symbol)
                    (string= (current-text) text)))
             (advance ()
               (prog1 (current)
                 (when (< position (1- length))
                   (incf position))))
             (consume-keyword (text)
               (unless (keyword-p text)
                 (fail-at (current-position) "Expected keyword ~A" text))
               (advance))
             (consume-symbol (text)
               (unless (symbol-p text)
                 (fail-at (current-position) "Expected symbol ~A" text))
               (advance))
             (consume-identifier ()
               (unless (eq (current-kind) :identifier)
                 (fail-at (current-position) "Expected an identifier"))
               (token-text (advance)))
             (consume-statement-end ()
               (consume-symbol ";"))
             (block-finished-p (stoppers)
               (or (eq (current-kind) :eof)
                   (and (eq (current-kind) :keyword)
                        (member (current-text) stoppers :test #'string=))))
             (parse-block (stoppers)
               (loop until (block-finished-p stoppers)
                     collect (parse-statement)))
             (parse-statement ()
               (cond
                 ((keyword-p "let")
                  (advance)
                  (let ((name (consume-identifier)))
                    (consume-symbol "=")
                    (let ((value (parse-expression)))
                      (consume-statement-end)
                      (list :let name value))))
                 ((keyword-p "print")
                  (advance)
                  (let ((value (parse-expression)))
                    (consume-statement-end)
                    (list :print value)))
                 ((keyword-p "if")
                  (advance)
                  (let ((condition (parse-expression)))
                    (consume-keyword "then")
                    (let ((then-body (parse-block '("else" "end")))
                          (else-body '()))
                      (when (keyword-p "else")
                        (advance)
                        (setf else-body (parse-block '("end"))))
                      (consume-keyword "end")
                      (list :if condition then-body else-body))))
                 ((keyword-p "while")
                  (advance)
                  (let ((condition (parse-expression)))
                    (consume-keyword "do")
                    (let ((body (parse-block '("end"))))
                      (consume-keyword "end")
                      (list :while condition body))))
                 ((eq (current-kind) :identifier)
                  (let ((name (consume-identifier)))
                    (consume-symbol "=")
                    (let ((value (parse-expression)))
                      (consume-statement-end)
                      (list :assign name value))))
                 (t
                  (fail-at (current-position)
                           "Expected a statement, found ~S"
                           (current-text)))))
             (parse-expression ()
               (parse-relation))
             (parse-relation ()
               (let ((left (parse-sum)))
                 (loop while (member (current-text)
                                     '("<" "<=" ">" ">=" "==" "!=")
                                     :test #'string=)
                       do (let ((operator (current-text)))
                            (advance)
                            (setf left (list :binary operator left (parse-sum)))))
                 left))
             (parse-sum ()
               (let ((left (parse-term)))
                 (loop while (member (current-text) '("+" "-") :test #'string=)
                       do (let ((operator (current-text)))
                            (advance)
                            (setf left (list :binary operator left (parse-term)))))
                 left))
             (parse-term ()
               (let ((left (parse-unary)))
                 (loop while (member (current-text) '("*" "/") :test #'string=)
                       do (let ((operator (current-text)))
                            (advance)
                            (setf left (list :binary operator left (parse-unary)))))
                 left))
             (parse-unary ()
               (cond
                 ((symbol-p "+")
                  (advance)
                  (parse-unary))
                 ((symbol-p "-")
                  (advance)
                  (list :unary "-" (parse-unary)))
                 (t
                  (parse-primary))))
             (parse-primary ()
               (cond
                 ((eq (current-kind) :integer)
                  (let ((value (token-value (advance))))
                    (list :integer value)))
                 ((eq (current-kind) :identifier)
                  (let ((name (consume-identifier)))
                    (list :variable name)))
                 ((symbol-p "(")
                  (advance)
                  (let ((expression (parse-expression)))
                    (consume-symbol ")")
                    expression))
                 (t
                  (fail-at (current-position)
                           "Expected an expression, found ~S"
                           (current-text))))))
      (let ((program (list :program (parse-block '()))))
        (unless (eq (current-kind) :eof)
          (fail-at (current-position) "Expected end of input"))
        program))))

(defun opcode-for-binary-operator (operator)
  (cdr (assoc operator
              '(("+" . :add)
                ("-" . :subtract)
                ("*" . :multiply)
                ("/" . :divide)
                ("<" . :less-than)
                ("<=" . :less-or-equal)
                (">" . :greater-than)
                (">=" . :greater-or-equal)
                ("==" . :equal-to)
                ("!=" . :not-equal-to))
              :test #'string=)))

(defun assemble (instructions)
  (let ((labels (make-hash-table :test #'equal))
        (program-counter 0))
    (dolist (instruction instructions)
      (if (eq (first instruction) :label)
          (setf (gethash (second instruction) labels) program-counter)
          (incf program-counter)))
    (loop for instruction in instructions
          unless (eq (first instruction) :label)
          collect
          (case (first instruction)
            ((:jump :jump-if-zero)
             (let ((target (gethash (second instruction) labels)))
               (unless target
                 (error "Unknown label ~A" (second instruction)))
               (list (first instruction) target)))
            (otherwise instruction)))))

(defun compile-program (ast)
  "Compile AST into bytecode for the tiny stack VM."
  (let ((instructions '())
        (label-counter 0))
    (labels ((emit (&rest instruction)
               (push instruction instructions))
             (fresh-label (prefix)
               (format nil "~A-~D" prefix (incf label-counter)))
             (emit-label (label)
               (emit :label label))
             (compile-expression (expression)
               (case (first expression)
                 (:integer
                  (emit :push (second expression)))
                 (:variable
                  (emit :load (second expression)))
                 (:unary
                  (compile-expression (third expression))
                  (cond
                    ((string= (second expression) "-")
                     (emit :negate))
                    (t
                     (error "Unknown unary operator ~A" (second expression)))))
                 (:binary
                  (compile-expression (third expression))
                  (compile-expression (fourth expression))
                  (let ((opcode (opcode-for-binary-operator (second expression))))
                    (unless opcode
                      (error "Unknown binary operator ~A" (second expression)))
                    (emit opcode)))
                 (otherwise
                  (error "Unknown expression node ~S" expression))))
             (compile-statement (statement)
               (case (first statement)
                 (:let
                  (compile-expression (third statement))
                  (emit :store (second statement)))
                 (:assign
                  (compile-expression (third statement))
                  (emit :store (second statement)))
                 (:print
                  (compile-expression (second statement))
                  (emit :print))
                 (:if
                  (let ((else-label (fresh-label "else"))
                        (end-label (fresh-label "end-if")))
                    (compile-expression (second statement))
                    (emit :jump-if-zero else-label)
                    (compile-block (third statement))
                    (emit :jump end-label)
                    (emit-label else-label)
                    (compile-block (fourth statement))
                    (emit-label end-label)))
                 (:while
                  (let ((start-label (fresh-label "while"))
                        (end-label (fresh-label "end-while")))
                    (emit-label start-label)
                    (compile-expression (second statement))
                    (emit :jump-if-zero end-label)
                    (compile-block (third statement))
                    (emit :jump start-label)
                    (emit-label end-label)))
                 (otherwise
                  (error "Unknown statement node ~S" statement))))
             (compile-block (statements)
               (dolist (statement statements)
                 (compile-statement statement))))
      (unless (eq (first ast) :program)
        (error "Expected a program AST"))
      (compile-block (second ast))
      (assemble (nreverse instructions)))))

(defun compile-source (source)
  (compile-program (parse (scan source))))

(defun truthy-integer (value)
  (if (zerop value) 0 1))

(defun run-bytecode (bytecode)
  "Run BYTECODE and return two values: printed output and the final environment."
  (let ((program (coerce bytecode 'vector))
        (stack '())
        (output '())
        (environment (make-hash-table :test #'equal))
        (program-counter 0))
    (labels ((push-stack (value)
               (push value stack))
             (pop-stack ()
               (unless stack
                 (error "Stack underflow"))
               (pop stack))
             (binary (function)
               (let ((right (pop-stack))
                     (left (pop-stack)))
                 (push-stack (funcall function left right))))
             (comparison (predicate)
               (binary (lambda (left right)
                         (if (funcall predicate left right) 1 0)))))
      (loop while (< program-counter (length program)) do
        (let ((instruction (aref program program-counter))
              (jumped nil))
          (case (first instruction)
            (:push
             (push-stack (second instruction)))
            (:load
             (push-stack (gethash (second instruction) environment 0)))
            (:store
             (setf (gethash (second instruction) environment) (pop-stack)))
            (:add
             (binary #'+))
            (:subtract
             (binary #'-))
            (:multiply
             (binary #'*))
            (:divide
             (binary #'truncate))
            (:negate
             (push-stack (- (pop-stack))))
            (:less-than
             (comparison #'<))
            (:less-or-equal
             (comparison #'<=))
            (:greater-than
             (comparison #'>))
            (:greater-or-equal
             (comparison #'>=))
            (:equal-to
             (comparison #'=))
            (:not-equal-to
             (comparison #'/=))
            (:print
             (push (pop-stack) output))
            (:jump
             (setf program-counter (second instruction)
                   jumped t))
            (:jump-if-zero
             (when (zerop (truthy-integer (pop-stack)))
               (setf program-counter (second instruction)
                     jumped t)))
            (otherwise
             (error "Unknown instruction ~S" instruction)))
          (unless jumped
            (incf program-counter)))))
    (values (nreverse output) environment)))

(defun run-source (source)
  (run-bytecode (compile-source source)))

(defparameter *standalone-demo-source*
  "let n = 5;
let acc = 1;
while n > 1 do
  acc = acc * n;
  n = n - 1;
end
print acc;")

(defun standalone-main (&optional source)
  "Compile and run SOURCE, printing bytecode and VM output."
  (let ((program-source (or source *standalone-demo-source*)))
    (format t "~&Tiny source:~%~A~%~%" program-source)
    (format t "Bytecode:~%~S~%~%" (compile-source program-source))
    (multiple-value-bind (output environment)
        (run-source program-source)
      (declare (ignore environment))
      (format t "Output: ~S~%" output)
      output)))

(defun split-null-separated-string (string)
  (let ((parts '())
        (start 0)
        (length (length string)))
    (loop for index from 0 below length do
      (when (char= (char string index) (code-char 0))
        (when (< start index)
          (push (subseq string start index) parts))
        (setf start (1+ index))))
    (when (< start length)
      (push (subseq string start) parts))
    (nreverse parts)))

(defun linux-process-arguments ()
  (ignore-errors
    (with-open-file (stream #p"/proc/self/cmdline"
                            :direction :input
                            :element-type '(unsigned-byte 8))
      (let ((bytes (loop for byte = (read-byte stream nil nil)
                         while byte
                         collect byte)))
        (split-null-separated-string
         (coerce (mapcar #'code-char bytes) 'string))))))

(defun script-pathname-argument ()
  #+sbcl
  (let ((tail (rest (member "--script"
                            (linux-process-arguments)
                            :test #'string=))))
    (first tail))
  #-sbcl
  nil)

(defun standalone-source-argument ()
  #+sbcl
  (let* ((tail (rest (member "--script"
                             (linux-process-arguments)
                             :test #'string=)))
         (source-parts (rest tail)))
    (when source-parts
      (format nil "~{~A~^ ~}" source-parts)))
  #-sbcl
  nil)

(defun running-as-sbcl-script-p ()
  #+sbcl
  (let ((script-name (script-pathname-argument)))
    (and *load-truename*
         script-name
         (ignore-errors
           (equal (truename script-name) (truename *load-truename*)))))
  #-sbcl
  nil)

#+sbcl
(when (running-as-sbcl-script-p)
  (standalone-main (standalone-source-argument))
  (sb-ext:quit))
