;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:

;; Personal Info
(setq user-full-name "Kuzey Koç"
      user-mail-address "savolla@protonmail.com")

;; better j k experience
(define-key evil-normal-state-map (kbd "j") 'evil-next-visual-line)
(define-key evil-normal-state-map (kbd "k") 'evil-previous-visual-line)

;; vterm Configuration
(after! vterm
  (set-popup-rule! "*doom:vterm-popup"
    :size 0.30
    ;; :vslot -4
    :select t
    :quit nil))
;; (setq explicit-shell-file-name "$(readlink -f $(which zsh))")
;; (setq vterm-shell "$(readlink -f $(which zsh))")

;; Treemacs Configuration
(after! treemacs
  (treemacs-follow-mode 1)
  (setq treemacs-width 30)
  (setq treemacs-position 'right))

;; Window Split Configuration
(setq evil-vsplit-window-right t ;; automatic focus when splitted
      evil-split-window-below t) ;; automatic focus when splitted
(setq split-width-threshold 240)

;; Workspace Configuration
(map! :leader :desc "next workspace"          "TAB L" #'+workspace:switch-next ) ;; workspace next
(map! :leader :desc "previous workspace"      "TAB H" #'+workspace:switch-previous ) ;; workspace previous
(map! :leader :desc "delete workspace"        "TAB D" #'+workspace:delete ) ;; delete workspace
(map! :leader :desc "new workspace"           "TAB N" #'+workspace:new ) ;; new workspace
(map! :leader :desc "rename workspace"        "TAB R" #'+workspace:rename ) ;; rename workspace
(setq +workspaces-on-switch-project-behavior t) ;; always open a new workspace when opening new project

(defun my-weebery-is-always-greater ()
  (let* ((banner '(
"                        ██  ██        "
"                        ██  ██        "
"  ████████████  ██████████  ██  ██████"
"  ██  ██▄▄████  ████  ████  ██  ██▄▄██"
"████  ██  ██  ██  ████████████████  ██"
                   ))
         (longest-line (apply #'max (mapcar #'length banner))))
    (put-text-property
     (point)
     (dolist (line banner (point))
       (insert (+doom-dashboard--center
                +doom-dashboard--width
                (concat line (make-string (max 0 (- longest-line (length line))) 32)))
               "\n"))
     'face 'doom-dashboard-banner)))

(setq +doom-dashboard-ascii-banner-fn #'my-weebery-is-always-greater)

(setq doom-theme 'doom-gruvbox)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; Splash Screen Configuraion
(defun doom-dashboard-widget-footer ())

(setq doom-font (font-spec :family "Fira Code" :size 26 :spacing 110 )
      ;; doom-variable-pitch-font (font-spec :family "Fira Sans" :size 24)
)
;; cli emacs vertical border separator
(setq-default display-table (make-display-table))
(set-display-table-slot display-table 'vertical-border (make-glyph-code ?|))

(setq display-line-numbers-type t)

;; tabs keybinds
(map! :leader :desc "new tab"                 "TAB n" #'tab-new ) ;; new tab
(map! :leader :desc "next tab"                "TAB l" #'tab-next ) ;; next tab
(map! :leader :desc "kill tab"                "TAB d" #'tab-close ) ;; close tab
(map! :leader :desc "previous tab"            "TAB h" #'tab-previous ) ;; previous tab
(map! :leader :desc "toggle tabs"             "TAB t" #'tab-bar-mode ) ;; toggle tab-bar-mode


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
