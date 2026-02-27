(ns command-pattern.canvas-commands-spec
  (:require [speclj.core :refer :all]
            [command-pattern.command :as cmd]
            [command-pattern.canvas-commands :as cc]))

(describe "Command パターン - キャンバスコマンド"

  (context "Canvas操作"
    (it "キャンバスを作成できる"
      (let [canvas (cc/make-canvas)]
        (should= [] (:shapes canvas))))

    (it "図形を追加できる"
      (let [canvas (cc/make-canvas)
            shape {:id 1 :type :circle :x 10 :y 10}
            updated (cc/add-shape-to-canvas canvas shape)]
        (should= 1 (count (:shapes updated)))
        (should= shape (first (:shapes updated)))))

    (it "図形を削除できる"
      (let [canvas {:shapes [{:id 1 :type :circle} {:id 2 :type :square}]}
            updated (cc/remove-shape-from-canvas canvas 1)]
        (should= 1 (count (:shapes updated)))
        (should= 2 (:id (first (:shapes updated)))))))

  (context "AddShapeCommand"
    (it "図形追加コマンドを実行できる"
      (let [shape {:id 1 :type :circle :x 10 :y 10}
            command (cc/make-add-shape-command shape)
            canvas (cc/make-canvas)
            execute-fn (cmd/execute command)
            result (execute-fn canvas)]
        (should= 1 (count (:shapes result)))))

    (it "図形追加を取り消せる"
      (let [shape {:id 1 :type :circle :x 10 :y 10}
            command (cc/make-add-shape-command shape)
            canvas {:shapes [shape]}
            undo-fn (cmd/undo command)
            result (undo-fn canvas)]
        (should= 0 (count (:shapes result))))))

  (context "DeleteShapeCommand"
    (it "図形削除コマンドを実行できる"
      (let [shape {:id 1 :type :circle :x 10 :y 10}
            command (cc/make-delete-shape-command 1 shape)
            canvas {:shapes [shape]}
            execute-fn (cmd/execute command)
            result (execute-fn canvas)]
        (should= 0 (count (:shapes result)))))

    (it "図形削除を取り消せる"
      (let [shape {:id 1 :type :circle :x 10 :y 10}
            command (cc/make-delete-shape-command 1 shape)
            canvas (cc/make-canvas)
            undo-fn (cmd/undo command)
            result (undo-fn canvas)]
        (should= 1 (count (:shapes result))))))

  (context "MoveShapeCommand"
    (it "図形移動コマンドを実行できる"
      (let [shape {:id 1 :type :circle :x 10 :y 10}
            command (cc/make-move-shape-command 1 5 5)
            canvas {:shapes [shape]}
            execute-fn (cmd/execute command)
            result (execute-fn canvas)]
        (should= 15 (:x (first (:shapes result))))
        (should= 15 (:y (first (:shapes result))))))

    (it "図形移動を取り消せる"
      (let [shape {:id 1 :type :circle :x 15 :y 15}
            command (cc/make-move-shape-command 1 5 5)
            canvas {:shapes [shape]}
            undo-fn (cmd/undo command)
            result (undo-fn canvas)]
        (should= 10 (:x (first (:shapes result))))
        (should= 10 (:y (first (:shapes result))))))))

(run-specs)
