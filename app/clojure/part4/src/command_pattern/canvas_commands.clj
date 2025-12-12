(ns command-pattern.canvas-commands
  "Command パターン - キャンバス操作コマンド

   図形描画アプリケーションの操作をコマンドとして実装します。
   図形の追加、削除、移動をサポートします。"
  (:require [command-pattern.command :as cmd]))

;; =============================================================================
;; Canvas 状態の定義
;; =============================================================================

(defn make-canvas
  "キャンバスを作成"
  []
  {:shapes []})

(defn add-shape-to-canvas
  "キャンバスに図形を追加"
  [canvas shape]
  (update canvas :shapes conj shape))

(defn remove-shape-from-canvas
  "キャンバスから図形を削除"
  [canvas shape-id]
  (update canvas :shapes
          (fn [shapes]
            (filterv #(not= (:id %) shape-id) shapes))))

(defn find-shape
  "図形を検索"
  [canvas shape-id]
  (first (filter #(= (:id %) shape-id) (:shapes canvas))))

;; =============================================================================
;; AddShapeCommand: 図形追加
;; =============================================================================

(defn make-add-shape-command
  "図形追加コマンドを作成"
  [shape]
  {:type :add-shape-command
   :shape shape})

(defmethod cmd/execute :add-shape-command [command]
  (fn [canvas]
    (add-shape-to-canvas canvas (:shape command))))

(defmethod cmd/undo :add-shape-command [command]
  (fn [canvas]
    (remove-shape-from-canvas canvas (get-in command [:shape :id]))))

;; =============================================================================
;; DeleteShapeCommand: 図形削除
;; =============================================================================

(defn make-delete-shape-command
  "図形削除コマンドを作成"
  [shape-id deleted-shape]
  {:type :delete-shape-command
   :shape-id shape-id
   :deleted-shape deleted-shape})

(defmethod cmd/execute :delete-shape-command [command]
  (fn [canvas]
    (remove-shape-from-canvas canvas (:shape-id command))))

(defmethod cmd/undo :delete-shape-command [command]
  (fn [canvas]
    (add-shape-to-canvas canvas (:deleted-shape command))))

;; =============================================================================
;; MoveShapeCommand: 図形移動
;; =============================================================================

(defn make-move-shape-command
  "図形移動コマンドを作成"
  [shape-id dx dy]
  {:type :move-shape-command
   :shape-id shape-id
   :dx dx
   :dy dy})

(defn move-shape
  "図形を移動"
  [canvas shape-id dx dy]
  (update canvas :shapes
          (fn [shapes]
            (mapv (fn [shape]
                    (if (= (:id shape) shape-id)
                      (-> shape
                          (update :x + dx)
                          (update :y + dy))
                      shape))
                  shapes))))

(defmethod cmd/execute :move-shape-command [command]
  (fn [canvas]
    (move-shape canvas (:shape-id command) (:dx command) (:dy command))))

(defmethod cmd/undo :move-shape-command [command]
  (fn [canvas]
    (move-shape canvas (:shape-id command) (- (:dx command)) (- (:dy command)))))
