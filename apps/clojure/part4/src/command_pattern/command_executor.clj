(ns command-pattern.command-executor
  "Command パターン - コマンド実行器

   コマンドの実行、Undo/Redo、バッチ処理を管理します。"
  (:require [command-pattern.command :as cmd]))

;; =============================================================================
;; CommandExecutor: コマンド実行と履歴管理
;; =============================================================================

(defn make-executor
  "コマンド実行器を作成"
  [initial-state]
  {:state initial-state
   :undo-stack []
   :redo-stack []})

(defn execute-command
  "コマンドを実行し、履歴に追加"
  [executor command]
  (let [state (:state executor)
        execute-fn (cmd/execute command)
        new-state (execute-fn state)]
    (-> executor
        (assoc :state new-state)
        (update :undo-stack conj command)
        (assoc :redo-stack []))))

(defn can-undo?
  "Undo 可能か確認"
  [executor]
  (seq (:undo-stack executor)))

(defn undo-command
  "最後のコマンドを取り消す"
  [executor]
  (if (can-undo? executor)
    (let [command (peek (:undo-stack executor))
          state (:state executor)
          undo-fn (cmd/undo command)
          new-state (undo-fn state)]
      (-> executor
          (assoc :state new-state)
          (update :undo-stack pop)
          (update :redo-stack conj command)))
    executor))

(defn can-redo?
  "Redo 可能か確認"
  [executor]
  (seq (:redo-stack executor)))

(defn redo-command
  "最後に取り消したコマンドを再実行"
  [executor]
  (if (can-redo? executor)
    (let [command (peek (:redo-stack executor))
          state (:state executor)
          execute-fn (cmd/execute command)
          new-state (execute-fn state)]
      (-> executor
          (assoc :state new-state)
          (update :redo-stack pop)
          (update :undo-stack conj command)))
    executor))

(defn get-state
  "現在の状態を取得"
  [executor]
  (:state executor))

;; =============================================================================
;; バッチ処理
;; =============================================================================

(defn execute-batch
  "複数のコマンドをまとめて実行"
  [executor commands]
  (reduce execute-command executor commands))

(defn undo-all
  "すべてのコマンドを取り消す"
  [executor]
  (if (can-undo? executor)
    (recur (undo-command executor))
    executor))

;; =============================================================================
;; MacroCommand: 複合コマンド
;; =============================================================================

(defn make-macro-command
  "複合コマンドを作成"
  [commands]
  {:type :macro-command
   :commands commands})

(defmethod cmd/execute :macro-command [macro]
  (fn [state]
    (reduce (fn [s command]
              ((cmd/execute command) s))
            state
            (:commands macro))))

(defmethod cmd/undo :macro-command [macro]
  (fn [state]
    (reduce (fn [s command]
              ((cmd/undo command) s))
            state
            (reverse (:commands macro)))))
