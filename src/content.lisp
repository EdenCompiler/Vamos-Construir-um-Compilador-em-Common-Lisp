(in-package #:lbccl.content)

(defparameter *course-title* "Let's Build a Compiler in Common Lisp")

(defparameter *course-deck*
  "An original Common Lisp course inspired by the classic compiler-building path: start with tiny expressions, grow a scanner and parser, emit bytecode, and keep the complete implementation readable.")

(defstruct lesson number slug title deck goals sections)

(defstruct section heading paragraphs code notes)

(defun lines (&rest strings)
  (format nil "~{~A~^~%~}" strings))

(defun paragraph (&rest strings)
  (format nil "~{~A~^ ~}" strings))

(defun make (number slug title deck goals sections)
  (make-lesson :number number
               :slug slug
               :title title
               :deck deck
               :goals goals
               :sections sections))

(defun section (heading paragraphs &key code notes)
  (make-section :heading heading
                :paragraphs paragraphs
                :code code
                :notes notes))

(defparameter *lessons*
  (list
   (make
    1
    "introduction"
    "Introduction"
    "Build a compiler by making the smallest useful piece work first."
    '("See the source language, compiler, bytecode, and VM as one feedback loop."
      "Use Common Lisp data as a practical AST representation."
      "Compile and run a first Tiny program.")
    (list
     (section
      "The shape of the project"
      (list
       (paragraph
        "This course is an original Common Lisp adaptation, not a reproduction of Jack Crenshaw's text."
        "It follows the same useful habit: type small pieces, run them, and keep the compiler understandable.")
       (paragraph
        "The complete working example in this site compiles a Tiny language into bytecode for a stack VM."
        "That keeps code generation concrete without requiring an assembler or native toolchain."))
      :code
      (lines
       "(defparameter *source*"
       "  \"let x = 1 + 2 * 3;"
       "   print x;\")"
       ""
       "(multiple-value-bind (output environment)"
       "    (lbccl.compiler:run-source *source*)"
       "  (declare (ignore environment))"
       "  output) ; => (7)"))
     (section
      "Why Common Lisp fits"
      (list
       (paragraph
        "A compiler is mostly tree building and tree walking."
        "Common Lisp gives us symbolic data, generic sequences, restarts in the REPL, and fast iteration.")
       (paragraph
        "For the first pass, plain lists are enough."
        "Later chapters show where structures, classes, or separate passes would pay for themselves."))
      :code
      (lines
       "'(:program"
       " ((:let \"x\" (:binary \"+\" (:integer 1)"
       "                         (:binary \"*\" (:integer 2) (:integer 3))))"
       "  (:print (:variable \"x\"))))"))))

   (make
    2
    "expression-parsing"
    "Expression Parsing"
    "Turn arithmetic text into a tree with recursive descent."
    '("Parse literals, parentheses, unary operators, and precedence."
      "Represent expressions as simple S-expressions."
      "Compile expression trees into stack operations.")
    (list
     (section
      "Recursive descent in one idea"
      (list
       (paragraph
        "Each precedence level gets one function."
        "The expression parser calls the relation parser, which calls addition, then multiplication, then unary, then primary.")
       (paragraph
        "The result is code that looks like the grammar and is easy to debug at the REPL."))
      :code
      (lines
       "(lbccl.compiler:parse"
       " (lbccl.compiler:scan \"print 2 + 3 * 4;\"))"))
     (section
      "Stack code for expressions"
      (list
       (paragraph
        "A stack machine makes the first code generator small."
        "Compile the left expression, compile the right expression, then emit the operator instruction."))
      :code
      (lines
       "(lbccl.compiler:compile-source"
       " \"print 2 + 3 * 4;\")")
      :notes
      '("Try compiling 2 + 3 * 4 and confirm multiplication appears before addition in the AST."))))

   (make
    3
    "more-expressions"
    "More Expressions"
    "Add variables, assignment, unary minus, and comparisons."
    '("Distinguish names from keywords."
      "Treat variables as loads and stores."
      "Return integers for boolean answers so conditions can branch.")
    (list
     (section
      "Variables are environment slots"
      (list
       (paragraph
        "The first implementation does not need a symbol table with scopes."
        "A hash table from variable name to integer value is enough for the VM, and the compiler can still emit explicit load and store instructions."))
      :code
      (lines
       "(let ((environment (make-hash-table :test #'equal)))"
       "  (setf (gethash \"x\" environment) 7)"
       "  (list (gethash \"x\" environment 0)"
       "        '((:store \"x\") (:load \"x\"))))"))
     (section
      "Comparisons are expressions"
      (list
       (paragraph
        "A comparison is compiled exactly like arithmetic: compute both sides, then emit an operation."
        "The VM pushes 1 for true and 0 for false, which makes later control flow simple."))
      :code
      (lines
       "(multiple-value-bind (output environment)"
       "    (lbccl.compiler:run-source"
       "     \"let limit = 10;"
       "      let ok = limit >= 3;"
       "      print ok;\")"
       "  (declare (ignore environment))"
       "  output)"))))

   (make
    4
    "interpreter"
    "Interpreters"
    "Run the compiled bytecode with a tiny virtual machine."
    '("Understand the stack discipline."
      "Implement bytecode dispatch with CASE."
      "Use the VM as a correctness oracle while the compiler grows.")
    (list
     (section
      "The VM loop"
      (list
       (paragraph
        "The VM keeps a program counter, a stack, an output list, and an environment."
        "Each bytecode instruction either manipulates those values or changes the program counter."))
      :code
      (lines
       "(multiple-value-bind (output environment)"
       "    (lbccl.compiler:run-bytecode"
       "     '((:push 40) (:push 2) (:add) (:print)))"
       "  (declare (ignore environment))"
       "  output)"))
     (section
      "Run before you optimize"
      (list
       (paragraph
        "Interpreters are excellent test fixtures."
        "Before adding native output, make the bytecode execution boringly predictable."))
      :code
      (lines
       "(lbccl.compiler:compile-source \"print 40 + 2;\")"
       ";; => ((:PUSH 40) (:PUSH 2) (:ADD) (:PRINT))"))))

   (make
    5
    "control-constructs"
    "Control Constructs"
    "Use labels and jumps to implement IF and WHILE."
    '("Compile structured control flow without losing structure in the parser."
      "Assemble symbolic labels into numeric jump targets."
      "Keep statement parsing separate from expression parsing.")
    (list
     (section
      "Labels first, addresses later"
      (list
       (paragraph
        "The compiler emits symbolic labels because they are easy for humans and easy to patch."
        "A short assembler pass removes label markers and rewrites jumps to instruction indexes."))
      :code
      (lines
       "'((:label \"while-1\")"
       "(:load \"n\")"
       "(:push 1)"
       "(:greater-than)"
       "(:jump-if-zero \"end-while-2\"))"))
     (section
      "A loop example"
      (list
       (paragraph
        "The loop body is just another block of statements."
        "That lets nested loops and nested conditionals fall out of the same parser."))
      :code
      (lines
       "(multiple-value-bind (output environment)"
       "    (lbccl.compiler:run-source"
       "     \"let n = 5;"
       "      let acc = 1;"
       "      while n > 1 do"
       "        acc = acc * n;"
       "        n = n - 1;"
       "      end"
       "      print acc;\")"
       "  (declare (ignore environment))"
       "  output)"))))

   (make
    6
    "boolean-expressions"
    "Boolean Expressions"
    "Keep booleans simple until the language needs richer semantics."
    '("Compile relational operators as integer-producing expressions."
      "See how truthiness drives conditional jumps."
      "Plan short-circuit AND and OR as a later refinement.")
    (list
     (section
      "Zero and nonzero"
      (list
       (paragraph
        "The Tiny VM treats zero as false and every nonzero integer as true."
        "This is enough for if and while and keeps the bytecode compact."))
      :code
      (lines
       "(defun truthy-integer (value)"
       "  (if (zerop value) 0 1))"))
     (section
      "Where AND and OR belong"
      (list
       (paragraph
        "AND and OR can be ordinary operators, but real short-circuiting is control flow."
        "A later parser can add boolean precedence and compile AND as an early jump when the left side is false."))
      :code
      (lines
       ";; Esboco para AND com curto-circuito:"
       "'((compile-expression left)"
       "  (emit :jump-if-zero false-label)"
       "  (compile-expression right))"))))

   (make
    7
    "lexical-scanning"
    "Lexical Scanning"
    "Give the parser tokens instead of raw characters."
    '("Scan integers, identifiers, keywords, symbols, and comments."
      "Attach positions to tokens for better errors."
      "Keep token text normalized.")
    (list
     (section
      "A token is a small record"
      (list
       (paragraph
        "The scanner is the compiler's first boundary."
        "It hides whitespace and comments while preserving enough position information to explain errors."))
      :code
      (lines
       "(defstruct token kind text value position)"
       ""
       "(make-token :kind :integer"
       "            :text \"123\""
       "            :value 123"
       "            :position 0)"))
     (section
      "Keywords are just names with a table"
      (list
       (paragraph
        "The scanner reads a word once, lowercases it, and decides whether it is a keyword or an identifier."
        "The parser can then ask for keyword LET without caring how many spaces appeared in the source."))
      :code
      (lines
       "(defparameter *keywords*"
       "  '(\"let\" \"print\" \"if\" \"then\" \"else\" \"end\" \"while\" \"do\"))"))))

   (make
    8
    "little-philosophy"
    "A Little Philosophy"
    "Prefer a compiler you can explain over one that looks impressive."
    '("Preserve small passes."
      "Use names that reveal the grammar."
      "Delay abstractions until a second example asks for them.")
    (list
     (section
      "The right amount of clever"
      (list
       (paragraph
        "Common Lisp makes it tempting to write a parser generator immediately."
        "For this course, the hand-written parser is the lesson: it exposes where precedence, statements, and blocks actually live."))
      :code
      (lines
       ";; Nomes simples sao parte da ideia aqui."
       "'(parse-statement"
       "  parse-expression"
       "  compile-statement"
       "  compile-expression)"))
     (section
      "Use the REPL"
      (list
       (paragraph
        "When a token stream looks wrong, inspect it directly."
        "When an AST looks wrong, compile only that part."
        "The REPL is not a side tool; it is part of the compiler-building loop."))
      :code
      (lines
       "(mapcar #'lbccl.compiler:token-text"
       "        (lbccl.compiler:scan \"print 1 + 2;\"))"))))

   (make
    9
    "top-view"
    "A Top View"
    "Connect the compiler pipeline from source text to output."
    '("Trace the full path through scanner, parser, compiler, assembler, and VM."
      "Identify what each pass consumes and returns."
      "Keep pass contracts explicit.")
    (list
     (section
      "The pipeline"
      (list
       (paragraph
        "Each compiler pass should accept one kind of value and return another."
        "That makes the system testable without a full end-to-end run every time."))
      :code
      (lines
       "'(:source-text"
       "  :tokens"
       "  :ast"
       "  :symbolic-bytecode"
       "  :assembled-bytecode"
       "  :vm-output)"))
     (section
      "One public function"
      (list
       (paragraph
        "A convenient top-level function should still call the smaller passes."
        "Do not hide the pass functions; they are how you learn and debug."))
      :code
      (lines
       "(defun example-run-source (source)"
       "  (lbccl.compiler:run-bytecode"
       "   (lbccl.compiler:compile-source source)))"
       ""
       "(multiple-value-bind (output environment)"
       "    (example-run-source \"print 1;\")"
       "  (declare (ignore environment))"
       "  output)"))))

   (make
    10
    "introducing-tiny"
    "Introducing Tiny"
    "Define the small teaching language used by the rest of the site."
    '("Document the syntax supported by the implementation."
      "Keep the first language integer-only."
      "Make every feature earn its implementation cost.")
    (list
     (section
      "Tiny syntax"
      (list
       (paragraph
        "Tiny has integer arithmetic, variables, print statements, if/else, and while loops."
        "Statements are deliberately sparse so the compiler can stay visible."))
      :code
      (lines
       "'((statement (:let name \"=\" expression \";\"))"
       "  (statement (name \"=\" expression \";\"))"
       "  (statement (:print expression \";\"))"
       "  (statement (:if expression :then block :else block :end))"
       "  (statement (:while expression :do block :end)))"))
     (section
      "A complete Tiny program"
      (list
       (paragraph
        "This program computes a factorial using only the constructs already implemented by the parser and VM."))
      :code
      (lines
       "(multiple-value-bind (output environment)"
       "    (lbccl.compiler:run-source"
       "     \"let n = 5;"
       "      let acc = 1;"
       "      while n > 1 do"
       "        acc = acc * n;"
       "        n = n - 1;"
       "      end"
       "      print acc;\")"
       "  (declare (ignore environment))"
       "  output)"))))

   (make
    11
    "scanner-revisited"
    "Lexical Scan Revisited"
    "Improve diagnostics and make token handling stricter."
    '("Report character positions."
      "Reject unknown input early."
      "Normalize source choices before they reach the parser.")
    (list
     (section
      "Error positions"
      (list
       (paragraph
        "A compiler that fails loudly but vaguely is hard to use."
        "Token positions let syntax errors point back to the source character that caused the problem."))
      :code
      (lines
       "(define-condition compiler-error (error)"
       "  ((position :initarg :position :reader compiler-error-position)"
       "   (message :initarg :message :reader compiler-error-message)))"))
     (section
      "Comments"
      (list
       (paragraph
        "Comments are scanner work, not parser work."
        "The Tiny scanner treats # as a line comment and drops the rest of the line."))
      :code
      (lines
       "(mapcar #'lbccl.compiler:token-text"
       "        (lbccl.compiler:scan"
       "         \"let x = 3; # o parser nunca ve isto"
       "          print x;\"))"))))

   (make
    12
    "miscellany"
    "Miscellany"
    "Tighten the edges: division, defaults, and generated listings."
    '("Decide integer division semantics."
      "Choose behavior for reading uninitialized variables."
      "Generate source listings from the real compiler file.")
    (list
     (section
      "Integer division"
      (list
       (paragraph
        "The VM uses Common Lisp's TRUNCATE for integer division."
        "That is explicit, portable, and easy to replace if the language later wants rational or floored division."))
      :code
      (lines
       "'(:divide :implementation truncate)"))
     (section
      "Uninitialized variables"
      (list
       (paragraph
        "The first VM returns zero for a missing variable."
        "That mirrors many tiny teaching languages, but the parser and compiler are structured so a symbol-table pass can reject the same program later."))
      :code
      (lines
       "(multiple-value-bind (output environment)"
       "    (lbccl.compiler:run-source \"print missing;\")"
       "  (declare (ignore environment))"
       "  output)"))))

   (make
    13
    "procedures"
    "Procedures"
    "Plan calls, parameters, and local environments."
    '("Separate parsing a procedure from invoking it."
      "See why call frames are a VM feature."
      "Sketch a future extension without complicating the current code.")
    (list
     (section
      "Procedure syntax sketch"
      (list
       (paragraph
        "Procedures add two concepts: a named block and a call instruction."
        "The parser can collect definitions at top level while statements inside a block can call them."))
      :code
      (lines
       "'(:procedure \"twice\""
       "  (:parameters (\"x\"))"
       "  (:body ((:print (:variable \"x\"))"
       "          (:print (:variable \"x\"))))"
       "  (:call \"twice\" (21)))"))
     (section
      "Call frames"
      (list
       (paragraph
        "A real procedure call needs a return address and a local environment."
        "That belongs in the VM, not as a hack in the parser."))
      :code
      (lines
       "'((:call \"twice\" 1)"
       "  (:return))"))))

   (make
    14
    "types"
    "Types"
    "Add a small type pass before code generation."
    '("Distinguish syntax from meaning."
      "Use a separate pass to annotate or reject programs."
      "Keep the first type system small.")
    (list
     (section
      "A type environment"
      (list
       (paragraph
        "The parser should accept syntax, not decide every semantic rule."
        "A type pass can walk the AST with a table of variable names and expected kinds."))
      :code
      (lines
       "(defun infer-expression-type (expression environment)"
       "  (case (first expression)"
       "    (:integer :integer)"
       "    (:variable (gethash (second expression) environment))"
       "    (:binary :integer)))"))
     (section
      "Useful first checks"
      (list
       (paragraph
        "Start by rejecting unknown variables and non-integer conditions if you add true booleans later."
        "Do that before bytecode generation so the compiler fails before emitting partial code."))
      :code
      (lines
       "(let ((type nil)"
       "      (name \"x\"))"
       "  (handler-case"
       "      (when (null type)"
       "        (error \"Unknown variable ~A\" name))"
       "    (error (condition)"
       "      (princ-to-string condition))))"))))

   (make
    15
    "back-to-the-future"
    "Back to the Future"
    "Where this simple compiler can go next."
    '("Replace the VM backend with another target."
      "Keep the AST contract stable."
      "Use tests to protect refactors.")
    (list
     (section
      "Backend swaps"
      (list
       (paragraph
        "Once the AST is stable, the bytecode backend is only one possible target."
        "You can emit C, WebAssembly text, native assembly, or Common Lisp forms from the same tree."))
      :code
      (lines
       "(defgeneric emit-target (target source))"
       ""
       "(defmethod emit-target ((target (eql :bytecode)) source)"
       "  (declare (ignore target))"
       "  (lbccl.compiler:compile-source source))"
       ""
       "(emit-target :bytecode \"print 1;\")"))
     (section
      "Keep examples executable"
      (list
       (paragraph
        "Compiler tutorials age better when their examples are runnable."
        "This site's examples are backed by a test file that exercises scanning, parsing, bytecode, and generated pages."))
      :code
      (lines
       "'(:command \"sbcl\" \"--script\" \"test.lisp\")"))))

   (make
    16
    "unit-construction"
    "Unit Construction"
    "Package the compiler as a set of clear Common Lisp units."
    '("Use packages as module boundaries."
      "Export only the teaching API."
      "Build the website from Lisp data.")
    (list
     (section
      "Packages are part of the design"
      (list
       (paragraph
        "The project separates the compiler, course content, renderer, and tests into packages."
        "That keeps the site generator from depending on parser internals it does not need."))
      :code
      (lines
       "'(defpackage #:lbccl.compiler"
       "  (:use #:cl)"
       "  (:export #:scan #:parse #:compile-source #:run-source))"))
     (section
      "The site is Lisp data"
      (list
       (paragraph
        "Lessons are structures, code examples are strings, and the renderer turns them into HTML."
        "That satisfies the central constraint: the maintained source for the site and the examples is Common Lisp."))
      :code
      (lines
       "(defstruct lesson number slug title deck goals sections)"
       "(defstruct section heading paragraphs code notes)"))))

   (make
    17
    "package-bootstrap"
    "Package Bootstrap"
    "Make the compiler source file able to define its own package when it is run by itself."
    '("Understand why IN-PACKAGE needs the package to exist before the rest of the file loads."
      "Use EVAL-WHEN to run setup code at compile time, load time, and direct execution time."
      "Guard DEFPACKAGE so standalone script use and normal system loading both work.")
    (list
     (section
      "Why this form is first"
      (list
       (paragraph
        "The compiler file begins with an IN-PACKAGE form."
        "That form only works if the LBCCL.COMPILER package already exists.")
       (paragraph
        "When the website loads the whole project, src/package.lisp creates that package first."
        "When someone runs only src/tiny-compiler.lisp, the compiler file must create the package for itself before IN-PACKAGE is read."))
      :code
      (lines
       "(eval-when (:compile-toplevel :load-toplevel :execute)"
       "  (unless (find-package \"LBCCL.COMPILER\")"
       "    (defpackage #:lbccl.compiler"
       "      (:use #:cl)"
       "      (:export"
       "       #:scan"
       "       #:parse"
       "       #:compile-source"
       "       #:compile-program"
       "       #:run-bytecode"
       "       #:run-source"
       "       #:token"
       "       #:token-kind"
       "       #:token-text"
       "       #:token-value"
       "       #:token-position"
       "       #:standalone-main))))"))
     (section
      "What EVAL-WHEN changes"
      (list
       (paragraph
        "EVAL-WHEN controls when a top-level form is evaluated."
        "The :compile-toplevel case matters if the file is compiled, because later forms need the package while the compiler is reading and compiling them.")
       (paragraph
        "The :load-toplevel case matters when a compiled or source file is loaded."
        "The :execute case matters when the form is evaluated directly, including script-style loading."))
      :code
      (lines
       "(list"
       " (package-name (find-package \"LBCCL.COMPILER\"))"
       " (package-name *package*))"))
     (section
      "The guard and the public API"
      (list
       (paragraph
        "FIND-PACKAGE is called with the string \"LBCCL.COMPILER\" so the lookup is independent of the current package."
        "If the package already exists, UNLESS skips DEFPACKAGE and avoids redefining it.")
       (paragraph
        "DEFPACKAGE says that the compiler package uses CL and exports the teaching API."
        "The #: syntax creates uninterned symbols for names in the package definition, avoiding accidental interning in the package that reads this form."))
      :code
      (lines
       "(loop for name in '(\"SCAN\" \"PARSE\" \"COMPILE-SOURCE\""
	       "                      \"RUN-BYTECODE\" \"RUN-SOURCE\""
	       "                      \"STANDALONE-MAIN\")"
	       "      collect (nth-value 1"
	       "               (find-symbol name \"LBCCL.COMPILER\")))"))))))
