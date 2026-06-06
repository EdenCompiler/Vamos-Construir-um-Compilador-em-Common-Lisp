(defpackage #:lbccl.compiler
  (:use #:cl)
  (:export
   #:scan
   #:parse
   #:compile-source
   #:compile-program
   #:run-bytecode
   #:run-source
   #:standalone-main
   #:token
   #:token-kind
   #:token-text
   #:token-value
   #:token-position))

(defpackage #:lbccl.content
  (:use #:cl)
  (:export
	   #:*course-title*
	   #:*course-title-pt-br*
	   #:*course-deck*
	   #:*course-deck-pt-br*
	   #:*lessons*
	   #:*lessons-pt-br*
	   #:*available-languages*
	   #:course-title-for-language
	   #:course-deck-for-language
	   #:lessons-for-language
	   #:lesson
   #:lesson-number
   #:lesson-slug
   #:lesson-title
   #:lesson-deck
   #:lesson-goals
   #:lesson-sections
   #:section
   #:section-heading
   #:section-paragraphs
   #:section-code
   #:section-notes))

(defpackage #:lbccl.site
  (:use #:cl)
  (:import-from #:lbccl.content
	                #:*course-title*
	                #:*course-title-pt-br*
	                #:*course-deck*
	                #:*course-deck-pt-br*
	                #:*lessons*
	                #:*lessons-pt-br*
	                #:*available-languages*
	                #:course-title-for-language
	                #:course-deck-for-language
	                #:lessons-for-language
	                #:lesson-number
                #:lesson-slug
                #:lesson-title
                #:lesson-deck
                #:lesson-goals
                #:lesson-sections
                #:section-heading
                #:section-paragraphs
                #:section-code
                #:section-notes)
  (:export #:build-site))

(defpackage #:lbccl.tests
  (:use #:cl)
  (:import-from #:lbccl.compiler
                #:scan
                #:parse
                #:compile-source
                #:run-source)
	  (:import-from #:lbccl.content
	                #:*lessons*
	                #:*lessons-pt-br*
	                #:lesson-sections)
  (:export #:run-tests))
