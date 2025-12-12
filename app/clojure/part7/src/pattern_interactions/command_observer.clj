(ns pattern-interactions.command-observer
  "Command + Observer パターンの統合
   コマンド実行時にオブザーバーに通知"
  (:require [pattern-interactions.command :as cmd]
            [pattern-interactions.observer :as obs]))

(defn make-observable-canvas
  "オブザーバブルなキャンバスを作成"
  []
  {:shapes []
   :subject (obs/make-subject)
   :history []
   :redo-stack []})

(defn get-shapes
  "図形一覧を取得"
  [canvas]
  (:shapes canvas))

(defn get-history
  "コマンド履歴を取得"
  [canvas]
  (:history canvas))

(defn add-observer
  "オブザーバーを追加"
  [canvas observer-fn]
  (obs/add-observer (:subject canvas) observer-fn)
  canvas)

(defn execute-command
  "コマンドを実行し、オブザーバーに通知"
  [canvas command]
  (let [executor (cmd/execute command)
        new-canvas (-> canvas
                       executor
                       (update :history conj command)
                       (assoc :redo-stack []))]
    ;; オブザーバーに通知
    (obs/notify-observers (:subject canvas)
                          {:type :command-executed
                           :command command
                           :description (cmd/describe command)})
    new-canvas))

(defn undo-last
  "最後のコマンドを取り消し"
  [canvas]
  (if (empty? (:history canvas))
    canvas
    (let [last-cmd (peek (:history canvas))
          undoer (cmd/undo last-cmd)
          new-canvas (-> canvas
                         undoer
                         (update :history pop)
                         (update :redo-stack conj last-cmd))]
      ;; オブザーバーに通知
      (obs/notify-observers (:subject canvas)
                            {:type :command-undone
                             :command last-cmd
                             :description (cmd/describe last-cmd)})
      new-canvas)))

(defn redo-last
  "最後に取り消したコマンドを再実行"
  [canvas]
  (if (empty? (:redo-stack canvas))
    canvas
    (let [cmd-to-redo (peek (:redo-stack canvas))
          executor (cmd/execute cmd-to-redo)
          new-canvas (-> canvas
                         executor
                         (update :history conj cmd-to-redo)
                         (update :redo-stack pop))]
      ;; オブザーバーに通知
      (obs/notify-observers (:subject canvas)
                            {:type :command-redone
                             :command cmd-to-redo
                             :description (cmd/describe cmd-to-redo)})
      new-canvas)))

(defn can-undo?
  "Undo 可能かどうか"
  [canvas]
  (not (empty? (:history canvas))))

(defn can-redo?
  "Redo 可能かどうか"
  [canvas]
  (not (empty? (:redo-stack canvas))))
