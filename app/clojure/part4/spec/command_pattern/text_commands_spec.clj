(ns command-pattern.text-commands-spec
  (:require [speclj.core :refer :all]
            [command-pattern.command :as cmd]
            [command-pattern.text-commands :as tc]))

(describe "Command パターン - テキストコマンド"

  (context "InsertCommand"
    (it "テキストを挿入できる"
      (let [command (tc/make-insert-command 5 "World")
            document "Hello!"
            execute-fn (cmd/execute command)]
        (should= "HelloWorld!" (execute-fn document))))

    (it "先頭に挿入できる"
      (let [command (tc/make-insert-command 0 "Hi ")
            document "there"
            execute-fn (cmd/execute command)]
        (should= "Hi there" (execute-fn document))))

    (it "末尾に挿入できる"
      (let [command (tc/make-insert-command 5 "!"
            )
            document "Hello"
            execute-fn (cmd/execute command)]
        (should= "Hello!" (execute-fn document))))

    (it "挿入を取り消せる"
      (let [command (tc/make-insert-command 5 "World")
            document "HelloWorld!"
            undo-fn (cmd/undo command)]
        (should= "Hello!" (undo-fn document)))))

  (context "DeleteCommand"
    (it "テキストを削除できる"
      (let [command (tc/make-delete-command 5 10 "World")
            document "HelloWorld!"
            execute-fn (cmd/execute command)]
        (should= "Hello!" (execute-fn document))))

    (it "削除を取り消せる"
      (let [command (tc/make-delete-command 5 10 "World")
            document "Hello!"
            undo-fn (cmd/undo command)]
        (should= "HelloWorld!" (undo-fn document)))))

  (context "ReplaceCommand"
    (it "テキストを置換できる"
      (let [command (tc/make-replace-command 0 "Hello" "Hi")
            document "Hello World"
            execute-fn (cmd/execute command)]
        (should= "Hi World" (execute-fn document))))

    (it "置換を取り消せる"
      (let [command (tc/make-replace-command 0 "Hello" "Hi")
            document "Hi World"
            undo-fn (cmd/undo command)]
        (should= "Hello World" (undo-fn document))))))

(run-specs)
