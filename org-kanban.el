;;; org-kanban --- kanban dynamic block for org-mode.
;;; Commentary:
;;; Each org TODO with a property Kanban is added to the table.
;;; Code:

;; -*- mode: Lisp; lexical-binding: t
(require 'org)
(require 'dash)
(require 'subr-x)

(defun org-kanban/get-title (todo)
  "Get the title from a heading TODO."
  (nth 4 todo))

(defun org-kanban/get-todo (todo)
  "Get the todo keyword from a heading TODO."
  (nth 2 todo))

(defun org-kanban/link (heading kanban search-for)
  "Create a link for a HEADING if the KANBAN value is equal to SEARCH-FOR."
  (if (stringp kanban) (if (string-equal search-for kanban) (format "[[%s]]" heading) "") ""))

(defun org-kanban/row-for (todo)
  "Convert a kanban TODO to a row of a org-table."
  (let* (
         (title (org-kanban/get-title todo))
         (kanban (nth 2 todo))
         (row-entries (-map (lambda(i) (org-kanban/link title i kanban)) org-todo-keywords-1))
         (row (string-join row-entries "|"))
         )
    (format "|%s|" row)))

(defun org-kanban/find ()
  "Search for a todo matching to the current kanban table row."
  (let*
      (
       (p (point))
       (line-start (save-excursion
                     (move-beginning-of-line 1)
                     (point)))
       (line-end (save-excursion
                   (move-end-of-line 1)
                   (point)))
       (start (save-excursion
                (goto-char line-start)
                (search-forward "[[")
                (point)))
       (end (save-excursion
              (goto-char start)
              (search-forward "]]")
              (point)))
       (title (if (and (>= start line-start) (<= end line-end)) (buffer-substring-no-properties start (- end 2)) nil))
       (entry (and title (marker-position (org-find-exact-headline-in-buffer title)))))
    entry))

(defun org-kanban/next ()
  "Move the todo entry in the current line of the kanban table to the next state."
  (interactive)
  (org-kanban/move 'right))

(defun org-kanban/prev ()
  "Move the todo entry in the current line of the kanban table to the previous state."
  (interactive)
  (org-kanban/move 'left))

(defun org-kanban/move (direction)
  "Move the todo entry in the current line of the kanban table to the next state in direction DIRECTION."
  (let* ((todo (org-kanban/find))
         (line (line-number-at-pos)))
    (if todo
        (progn
          (save-excursion
            (goto-char todo)
            (org-todo direction))
          (org-dblock-update)
          (goto-char 0)
          (forward-line (1- line))
          (goto-char (search-forward "[["))) nil)))

(defun org-dblock-write:kanban (params)
  "Create the kanban dynamic block.  PARAMS are ignored right now."
  (message "%s" org-todo-keywords-1)
  (insert
   (let*
       (
        (todos (org-map-entries (lambda() (org-heading-components))))
        (rows (-map 'row-for-kanban (-filter (lambda(todo) (-intersection (list (org-kanban/get-todo todo)) org-todo-keywords-1)) todos)))
        (table (--reduce (format "%s\n%s" acc it) rows))
        (table-title (string-join org-todo-keywords-1 "|"))
        )
     (format "|%s|\n|--|\n%s" table-title table)))
  (org-table-align))

(provide 'org-kanban)
;;; org-kanban.el ends here