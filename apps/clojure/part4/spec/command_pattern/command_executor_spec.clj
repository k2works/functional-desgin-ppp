(ns command-pattern.command-executor-spec
  (:require [speclj.core :refer :all]
            [command-pattern.command :as cmd]
            [command-pattern.command-executor :as exec]
            [command-pattern.text-commands :as tc]))

(describe "Command パターン - コマンド実行器"

  (context "基本操作"
    (it "実行器を作成できる"
      (let [executor (exec/make-executor "Hello")]
        (should= "Hello" (exec/get-state executor))
        (should-not (exec/can-undo? executor))
        (should-not (exec/can-redo? executor))))

    (it "コマンドを実行できる"
      (let [executor (exec/make-executor "Hello")
            command (tc/make-insert-command 5 " World")
            executor (exec/execute-command executor command)]
        (should= "Hello World" (exec/get-state executor))
        (should (exec/can-undo? executor)))))

  (context "Undo/Redo"
    (it "コマンドを取り消せる"
      (let [executor (-> (exec/make-executor "Hello")
                         (exec/execute-command (tc/make-insert-command 5 " World")))
            executor (exec/undo-command executor)]
        (should= "Hello" (exec/get-state executor))
        (should-not (exec/can-undo? executor))
        (should (exec/can-redo? executor))))

    (it "取り消したコマンドを再実行できる"
      (let [executor (-> (exec/make-executor "Hello")
                         (exec/execute-command (tc/make-insert-command 5 " World"))
                         (exec/undo-command)
                         (exec/redo-command))]
        (should= "Hello World" (exec/get-state executor))
        (should (exec/can-undo? executor))
        (should-not (exec/can-redo? executor))))

    (it "新しいコマンド実行でRedo履歴がクリアされる"
      (let [executor (-> (exec/make-executor "Hello")
                         (exec/execute-command (tc/make-insert-command 5 " World"))
                         (exec/undo-command)
                         (exec/execute-command (tc/make-insert-command 5 "!")))]
        (should= "Hello!" (exec/get-state executor))
        (should-not (exec/can-redo? executor)))))

  (context "バッチ処理"
    (it "複数のコマンドをまとめて実行できる"
      (let [commands [(tc/make-insert-command 5 " World")
                      (tc/make-insert-command 11 "!")]
            executor (exec/execute-batch (exec/make-executor "Hello") commands)]
        (should= "Hello World!" (exec/get-state executor))))

    (it "すべてのコマンドを取り消せる"
      (let [commands [(tc/make-insert-command 5 " World")
                      (tc/make-insert-command 11 "!")]
            executor (-> (exec/make-executor "Hello")
                         (exec/execute-batch commands)
                         (exec/undo-all))]
        (should= "Hello" (exec/get-state executor)))))

  (context "MacroCommand"
    (it "複合コマンドを実行できる"
      (let [commands [(tc/make-insert-command 5 " World")
                      (tc/make-insert-command 11 "!")]
            macro (exec/make-macro-command commands)
            executor (exec/execute-command (exec/make-executor "Hello") macro)]
        (should= "Hello World!" (exec/get-state executor))))

    (it "複合コマンドを取り消せる"
      (let [commands [(tc/make-insert-command 5 " World")
                      (tc/make-insert-command 11 "!")]
            macro (exec/make-macro-command commands)
            executor (-> (exec/make-executor "Hello")
                         (exec/execute-command macro)
                         (exec/undo-command))]
        (should= "Hello" (exec/get-state executor))))))

(run-specs)
