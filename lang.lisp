(in-package :core-lisp)

(cl:defparameter *compile-top-level* t)

(cl:defun package-globals (package)
  (cl:let* ((package-name (package-name package))
            (prefix (format nil "~a::" package-name)))
    (loop for sym being the present-symbols of *core-lisp-global-package*
          for name = (symbol-name sym)
          when (serapeum:string^= prefix name)
            collect sym)))

(cl:defun reset-package-globals (package)
  (loop with global-package = *core-lisp-global-package*
        for sym in (package-globals package)
        do (unintern sym global-package)
        finally (return package)))

(cl:defun read-module (source stream)
  (cl:let* ((use-list (list (find-package :core-lisp)))
            (package (vernacular:reset-file-package source :use-list use-list))
            (readtable (named-readtables:find-readtable 'core-lisp)))
    ;; I can't come up with an example where this could matter, but
    ;; it's probably better to start clean.
    (reset-package-globals package)
    `(module-progn
       ,@(vernacular:slurp-stream stream
                                  :readtable readtable
                                  :package package))))

(cl:defclass core-lisp-module ()
  ((package :initarg :package :type package)))

(defun find-external-symbol (name package)
  (setf name (string name))
  (or (serapeum:find-external-symbol name package)
      (cl:error "No symbol named ~a exported from ~s." name package)))

(serapeum:defmethods core-lisp-module (self package)
  (:method vernacular:module-exports (self)
    (serapeum:package-exports package))
  (:method vernacular:module-ref (self name)
    (vernacular:module-ref-ns self name nil))
  (:method vernacular:module-ref-ns (self name (ns cl:null))
    (let* ((sym (find-external-symbol name package))
           (alias (or (get-alias sym '%aliases% nil)
                      sym)))
      ;; Should we shadow symbol-value?
      (symbol-value alias)))
  (:method vernacular:module-ref-ns (self name (ns (cl:eql 'cl:function)))
    (symbol-function (find-external-symbol name package)))
  (:method vernacular:module-ref-ns (self name (ns (cl:eql 'cl:macro-function)))
    (macro-function (find-external-symbol name package))))

(cl:defmacro module-progn (&body body)
  ;; Variable-only at the moment.
  (cl:let* ((export-forms
              (loop for form in body
                    if (and (consp form)
                            (eql (first form) :export))
                      collect form))
            (export-default-form
              (loop for form in body
                    if (and (consp form) (eql (first form) :export-default))
                      return form))
            (meta-forms
              (append export-forms (list export-default-form)))
            (body
              (remove-if (lambda (form)
                           (member form meta-forms))
                         body))
            (exports
              (append
               (loop for form in export-forms
                     append (rest form))
               (and export-default-form
                    `((:default ,(second export-default-form)))))))
    (assert (not (and export-forms export-default-form)))
    (with-unique-names (source pkg)
      `(progn
         ,@body
         (setq vernacular:*module*
               (cl:let* ((,source ,vernacular:*source*)
                         (,pkg (vernacular:ensure-file-package ,source))
                         (*package* ,pkg))
                 ,@(loop for export in exports
                         collect (etypecase export
                                   (cl:symbol `(export ',export))
                                   ((cl:cons (cl:eql function)
                                             (cl:cons symbol cl:null))
                                    `(export ',(second export)))
                                   ((cl:cons (cl:eql macro-function)
                                             (cl:cons symbol cl:null))
                                    `(export ',(second export)))
                                   ((cl:cons (cl:eql :default) (cl:cons cl:t cl:null))
                                    (with-unique-names (sym)
                                      `(cl:let ((,sym (intern ,(string 'default))))
                                         (setf (symbol-value ,sym) ,(second export))
                                         (export ,sym))))))
                 (make-instance 'core-lisp-module :package ,pkg)))))))

(defmacro import (m &rest args)
  `(macrolet ((vernacular/cl:defmacro (name args &body body)
                  (declare (ignore args body))
                ;; ISLISP's defmacro supports neither &environment
                ;; nor &whole nor even &body.
                (let ((key (alexandria:make-keyword name))
                      (env nil))
                  `(defmacro ,name (&rest args)
                     (list 'funcall
                           '(vernacular:module-ref* ,',m ',key)
                           (list 'quote (cons ',name args))
                           ,env))))
              (vernacular/cl:defun (name args &body body)
                  (list* 'defun name args body))
              (vernacular/cl:defalias (name expr)
                `(let ((fn ,expr))
                   (defun ,name (&rest args)
                     (apply fn args))))
              (vernacular/cl:def (name init)
                (list 'defglobal name init))
              (vernacular/cl:define-symbol-macro (name expr)
                (list 'define-symbol-macro name expr)))
     (vernacular:import ,m ,@args)))
