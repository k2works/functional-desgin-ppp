(ns command-pattern.text-commands
  "Command パターン - テキスト操作コマンド

   テキストエディタの操作をコマンドとして実装します。
   挿入、削除、置換の各操作をサポートします。"
  (:require [command-pattern.command :as cmd]
            [clojure.string :as str]))

;; =============================================================================
;; InsertCommand: テキスト挿入
;; =============================================================================

(defn make-insert-command
  "挿入コマンドを作成"
  [position text]
  {:type :insert-command
   :position position
   :text text})

(defmethod cmd/execute :insert-command [command]
  (fn [document]
    (let [pos (:position command)
          text (:text command)
          before (subs document 0 pos)
          after (subs document pos)]
      (str before text after))))

(defmethod cmd/undo :insert-command [command]
  (fn [document]
    (let [pos (:position command)
          len (count (:text command))
          before (subs document 0 pos)
          after (subs document (+ pos len))]
      (str before after))))

;; =============================================================================
;; DeleteCommand: テキスト削除
;; =============================================================================

(defn make-delete-command
  "削除コマンドを作成"
  [start-position end-position deleted-text]
  {:type :delete-command
   :start-position start-position
   :end-position end-position
   :deleted-text deleted-text})

(defmethod cmd/execute :delete-command [command]
  (fn [document]
    (let [start (:start-position command)
          end (:end-position command)
          before (subs document 0 start)
          after (subs document end)]
      (str before after))))

(defmethod cmd/undo :delete-command [command]
  (fn [document]
    (let [start (:start-position command)
          text (:deleted-text command)
          before (subs document 0 start)
          after (subs document start)]
      (str before text after))))

;; =============================================================================
;; ReplaceCommand: テキスト置換
;; =============================================================================

(defn make-replace-command
  "置換コマンドを作成"
  [start-position old-text new-text]
  {:type :replace-command
   :start-position start-position
   :old-text old-text
   :new-text new-text})

(defmethod cmd/execute :replace-command [command]
  (fn [document]
    (let [start (:start-position command)
          old-len (count (:old-text command))
          new-text (:new-text command)
          before (subs document 0 start)
          after (subs document (+ start old-len))]
      (str before new-text after))))

(defmethod cmd/undo :replace-command [command]
  (fn [document]
    (let [start (:start-position command)
          new-len (count (:new-text command))
          old-text (:old-text command)
          before (subs document 0 start)
          after (subs document (+ start new-len))]
      (str before old-text after))))
