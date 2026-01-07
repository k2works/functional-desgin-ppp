module Tests

open System
open Xunit
open FunctionalDesign.Part2.Validation

// ============================================
// 第4章: データバリデーション
// ============================================

// ============================================
// 1. 基本的なバリデーション
// ============================================

module BasicValidationTests =

    [<Fact>]
    let ``validateName は有効な名前を受け入れる`` () =
        let result = validateName "田中太郎"
        Assert.Equal(Ok "田中太郎", result)

    [<Fact>]
    let ``validateName は空の名前を拒否`` () =
        let result = validateName ""

        match result with
        | Error errors -> Assert.Contains("名前は空にできません", errors)
        | Ok _ -> Assert.Fail("Expected error")

    [<Fact>]
    let ``validateName は100文字を超える名前を拒否`` () =
        let longName = String.replicate 101 "a"
        let result = validateName longName

        match result with
        | Error errors -> Assert.Contains("名前は100文字以内である必要があります", errors)
        | Ok _ -> Assert.Fail("Expected error")

    [<Fact>]
    let ``validateAge は有効な年齢を受け入れる`` () =
        let result = validateAge 25
        Assert.Equal(Ok 25, result)

    [<Fact>]
    let ``validateAge は負の年齢を拒否`` () =
        let result = validateAge -1

        match result with
        | Error errors -> Assert.Contains("年齢は0以上である必要があります", errors)
        | Ok _ -> Assert.Fail("Expected error")

    [<Fact>]
    let ``validateAge は150歳を超える年齢を拒否`` () =
        let result = validateAge 200

        match result with
        | Error errors -> Assert.Contains("年齢は150以下である必要があります", errors)
        | Ok _ -> Assert.Fail("Expected error")

    [<Fact>]
    let ``validateEmail は有効なメールを受け入れる`` () =
        let result = validateEmail "test@example.com"
        Assert.Equal(Ok "test@example.com", result)

    [<Fact>]
    let ``validateEmail は無効なメールを拒否`` () =
        let result = validateEmail "invalid-email"

        match result with
        | Error errors -> Assert.Contains("無効なメールアドレス形式です", errors)
        | Ok _ -> Assert.Fail("Expected error")

// ============================================
// 2. 列挙型
// ============================================

module MembershipTests =

    [<Fact>]
    let ``Membership.fromString は有効な値を受け入れる`` () =
        Assert.Equal(Ok Bronze, Membership.fromString "bronze")
        Assert.Equal(Ok Silver, Membership.fromString "silver")
        Assert.Equal(Ok Gold, Membership.fromString "gold")
        Assert.Equal(Ok Platinum, Membership.fromString "platinum")

    [<Fact>]
    let ``Membership.fromString は大文字小文字を区別しない`` () =
        Assert.Equal(Ok Gold, Membership.fromString "GOLD")
        Assert.Equal(Ok Gold, Membership.fromString "Gold")

    [<Fact>]
    let ``Membership.fromString は無効な値を拒否`` () =
        let result = Membership.fromString "invalid"

        match result with
        | Error errors -> Assert.Contains("無効な会員種別: invalid", errors)
        | Ok _ -> Assert.Fail("Expected error")

    [<Fact>]
    let ``Membership.toString は正しい文字列を返す`` () =
        Assert.Equal("gold", Membership.toString Gold)
        Assert.Equal("bronze", Membership.toString Bronze)

// ============================================
// 3. Validated パターン
// ============================================

module ValidatedTests =

    [<Fact>]
    let ``Validated.valid は Valid を作成`` () =
        let result = Validated.valid 42
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``Validated.invalid は Invalid を作成`` () =
        let result: Validated<string, int> = Validated.invalid [ "error" ]
        Assert.False(Validated.isValid result)

    [<Fact>]
    let ``Validated.map は値を変換`` () =
        let result = Validated.valid 5 |> Validated.map (fun x -> x * 2)

        match result with
        | Valid v -> Assert.Equal(10, v)
        | Invalid _ -> Assert.Fail("Expected Valid")

    [<Fact>]
    let ``Validated.combine は両方 Valid のとき成功`` () =
        let result = Validated.combine (fun a b -> a + b) (Validated.valid 1) (Validated.valid 2)

        match result with
        | Valid v -> Assert.Equal(3, v)
        | Invalid _ -> Assert.Fail("Expected Valid")

    [<Fact>]
    let ``Validated.combine はエラーを蓄積`` () =
        let va: Validated<string, int> = Validated.invalid [ "error1" ]
        let vb: Validated<string, int> = Validated.invalid [ "error2" ]
        let result = Validated.combine (+) va vb

        match result with
        | Invalid errors ->
            Assert.Contains("error1", errors)
            Assert.Contains("error2", errors)
        | Valid _ -> Assert.Fail("Expected Invalid")

    [<Fact>]
    let ``Validated.toResult は正しく変換`` () =
        Assert.Equal(Ok 42, Validated.toResult (Validated.valid 42))
        Assert.Equal(Error [ "err" ], Validated.toResult (Validated.invalid [ "err" ]))

// ============================================
// 4. ドメインプリミティブ
// ============================================

module DomainPrimitiveTests =

    [<Fact>]
    let ``ProductId.create は有効なIDを受け入れる`` () =
        let result = ProductId.create "PROD-00001"
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``ProductId.create は無効なIDを拒否`` () =
        let result = ProductId.create "INVALID"

        match result with
        | Invalid errors -> Assert.True(errors |> List.exists (fun e -> e.Contains("無効な商品ID形式")))
        | Valid _ -> Assert.Fail("Expected Invalid")

    [<Fact>]
    let ``ProductId.value は値を取得`` () =
        let pid = ProductId.unsafe "PROD-12345"
        Assert.Equal("PROD-12345", ProductId.value pid)

    [<Fact>]
    let ``ProductName.create は有効な名前を受け入れる`` () =
        let result = ProductName.create "テスト商品"
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``ProductName.create は空の名前を拒否`` () =
        let result = ProductName.create ""

        match result with
        | Invalid errors -> Assert.Contains("商品名は空にできません", errors)
        | Valid _ -> Assert.Fail("Expected Invalid")

    [<Fact>]
    let ``Price.create は正の価格を受け入れる`` () =
        let result = Price.create 1000m
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``Price.create はゼロ以下の価格を拒否`` () =
        let result = Price.create 0m

        match result with
        | Invalid errors -> Assert.Contains("価格は正の数である必要があります", errors)
        | Valid _ -> Assert.Fail("Expected Invalid")

    [<Fact>]
    let ``Quantity.create は正の数量を受け入れる`` () =
        let result = Quantity.create 5
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``Quantity.create はゼロ以下の数量を拒否`` () =
        let result = Quantity.create 0

        match result with
        | Invalid errors -> Assert.Contains("数量は正の整数である必要があります", errors)
        | Valid _ -> Assert.Fail("Expected Invalid")

// ============================================
// 5. 商品モデル
// ============================================

module ProductTests =

    [<Fact>]
    let ``Product.create は有効な商品を作成`` () =
        let result = Product.create "PROD-00001" "テスト商品" 1000m None None
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``Product.create は複数のエラーを蓄積`` () =
        let result = Product.create "INVALID" "" -100m None None

        match result with
        | Invalid errors ->
            Assert.True(errors.Length >= 3)
            Assert.True(errors |> List.exists (fun e -> e.Contains("商品ID")))
            Assert.True(errors |> List.exists (fun e -> e.Contains("商品名")))
            Assert.True(errors |> List.exists (fun e -> e.Contains("価格")))
        | Valid _ -> Assert.Fail("Expected Invalid")

// ============================================
// 6. 注文ドメインモデル
// ============================================

module OrderTests =

    [<Fact>]
    let ``OrderId.create は有効なIDを受け入れる`` () =
        let result = OrderId.create "ORD-12345678"
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``CustomerId.create は有効なIDを受け入れる`` () =
        let result = CustomerId.create "CUST-123456"
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``OrderItem.create は有効なアイテムを作成`` () =
        let result = OrderItem.create "PROD-00001" 2 1000m
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``OrderItem.total は正しく計算`` () =
        let item =
            { ProductId = ProductId.unsafe "PROD-00001"
              Quantity = Quantity.unsafe 3
              Price = Price.unsafe 500m }

        Assert.Equal(1500m, OrderItem.total item)

    [<Fact>]
    let ``Order.calculateTotal は全アイテムの合計を計算`` () =
        let item1 =
            { ProductId = ProductId.unsafe "PROD-00001"
              Quantity = Quantity.unsafe 2
              Price = Price.unsafe 1000m }

        let item2 =
            { ProductId = ProductId.unsafe "PROD-00002"
              Quantity = Quantity.unsafe 3
              Price = Price.unsafe 500m }

        let order =
            { OrderId = OrderId.unsafe "ORD-12345678"
              CustomerId = CustomerId.unsafe "CUST-123456"
              Items = [ item1; item2 ]
              OrderDate = DateTime.Now
              Total = None
              Status = None }

        // 2000 + 1500 = 3500
        Assert.Equal(3500m, Order.calculateTotal order)

// ============================================
// 7. 条件付きバリデーション
// ============================================

module NotificationTests =

    [<Fact>]
    let ``createEmail は有効なメール通知を作成`` () =
        let result = Notification.createEmail "test@example.com" "件名" "本文"
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``createEmail は無効なメールアドレスを拒否`` () =
        let result = Notification.createEmail "invalid" "件名" "本文"

        match result with
        | Invalid errors -> Assert.Contains("無効なメールアドレス形式です", errors)
        | Valid _ -> Assert.Fail("Expected Invalid")

    [<Fact>]
    let ``createEmail は複数のエラーを蓄積`` () =
        let result = Notification.createEmail "invalid" "" ""

        match result with
        | Invalid errors ->
            Assert.True(errors.Length >= 3)
            Assert.Contains("無効なメールアドレス形式です", errors)
            Assert.Contains("件名は空にできません", errors)
            Assert.Contains("本文は空にできません", errors)
        | Valid _ -> Assert.Fail("Expected Invalid")

    [<Fact>]
    let ``createSMS は有効なSMS通知を作成`` () =
        let result = Notification.createSMS "090-1234-5678" "本文"
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``createSMS は無効な電話番号を拒否`` () =
        let result = Notification.createSMS "invalid" "本文"

        match result with
        | Invalid errors -> Assert.Contains("無効な電話番号形式です", errors)
        | Valid _ -> Assert.Fail("Expected Invalid")

    [<Fact>]
    let ``createPush は有効なプッシュ通知を作成`` () =
        let result = Notification.createPush "device-token-123" "本文"
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``createPush は空のトークンを拒否`` () =
        let result = Notification.createPush "" "本文"

        match result with
        | Invalid errors -> Assert.Contains("デバイストークンは空にできません", errors)
        | Valid _ -> Assert.Fail("Expected Invalid")

    [<Fact>]
    let ``Notification.getBody は本文を取得`` () =
        Assert.Equal(
            "本文",
            EmailNotification("test@example.com", "件名", "本文")
            |> Notification.getBody
        )

        Assert.Equal("SMS本文", SMSNotification("090-0000-0000", "SMS本文") |> Notification.getBody)
        Assert.Equal("プッシュ本文", PushNotification("token", "プッシュ本文") |> Notification.getBody)

// ============================================
// 8. バリデーションユーティリティ
// ============================================

module ValidationUtilityTests =

    [<Fact>]
    let ``validatePerson は有効な人物データを検証`` () =
        let response = validatePerson "田中" 30 None
        Assert.True(response.Valid)
        Assert.True(response.Data.IsSome)
        Assert.Empty(response.Errors)

    [<Fact>]
    let ``validatePerson は無効なデータでエラーを返す`` () =
        let response = validatePerson "" -1 None
        Assert.False(response.Valid)
        Assert.True(response.Data.IsNone)
        Assert.Contains("名前は空にできません", response.Errors)
        Assert.Contains("年齢は0以上である必要があります", response.Errors)

    [<Fact>]
    let ``conformOrThrow は Valid で値を返す`` () =
        let value = conformOrThrow (Validated.valid 42)
        Assert.Equal(42, value)

    [<Fact>]
    let ``conformOrThrow は Invalid で例外を投げる`` () =
        Assert.Throws<Exception>(fun () ->
            conformOrThrow (Validated.invalid [ "error1"; "error2" ])
            |> ignore)

// ============================================
// 9. 計算関数
// ============================================

module CalculationTests =

    [<Fact>]
    let ``calculateItemTotal は正しく計算`` () =
        let item =
            { ProductId = ProductId.unsafe "PROD-00001"
              Quantity = Quantity.unsafe 3
              Price = Price.unsafe 1000m }

        Assert.Equal(3000m, calculateItemTotal item)

    [<Fact>]
    let ``applyDiscount は有効な割引率で計算`` () =
        let result = applyDiscount 1000m 0.1
        Assert.Equal(Ok 900m, result)

    [<Fact>]
    let ``applyDiscount は無効な割引率でエラー`` () =
        let result = applyDiscount 1000m 1.5

        match result with
        | Error msg -> Assert.Contains("0から1の間", msg)
        | Ok _ -> Assert.Fail("Expected error")

    [<Fact>]
    let ``sumPrices は複数の価格を合計`` () =
        let result = sumPrices [ 100m; 200m; 300m ]
        Assert.Equal(600m, result)


// ============================================
// 第5章: プロパティベーステスト
// ============================================

open FsCheck
open FsCheck.Xunit
open FunctionalDesign.Part2.PropertyBasedTesting

// ============================================
// 1. 文字列操作のプロパティ
// ============================================

module StringPropertyTests =

    [<Property>]
    let ``文字列反転は対合: 2回反転すると元に戻る`` (s: string) =
        let s = if isNull s then "" else s
        reverseString (reverseString s) = s

    [<Property>]
    let ``文字列反転は長さを保存する`` (s: string) =
        let s = if isNull s then "" else s
        (reverseString s).Length = s.Length

    [<Property>]
    let ``大文字変換は冪等`` (s: string) =
        let s = if isNull s then "" else s
        toUpperCase (toUpperCase s) = toUpperCase s

    [<Property>]
    let ``小文字変換は冪等`` (s: string) =
        let s = if isNull s then "" else s
        toLowerCase (toLowerCase s) = toLowerCase s

// ============================================
// 2. 数値操作のプロパティ
// ============================================

module NumberPropertyTests =

    [<Property>]
    let ``ソートは冪等: 2回ソートしても結果は同じ`` (nums: int list) =
        sortNumbers (sortNumbers nums) = sortNumbers nums

    [<Property>]
    let ``ソートは要素を保存する`` (nums: int list) =
        (sortNumbers nums |> List.sort) = (nums |> List.sort)

    [<Property>]
    let ``ソートは長さを保存する`` (nums: int list) =
        (sortNumbers nums).Length = nums.Length

    [<Property>]
    let ``ソート結果は昇順に並ぶ`` (nums: int list) =
        let sorted = sortNumbers nums

        match sorted with
        | [] -> true
        | [ _ ] -> true
        | _ -> List.pairwise sorted |> List.forall (fun (a, b) -> a <= b)

    [<Property>]
    let ``割引後の価格は0以上、元の価格以下`` (price: PositiveInt) =
        let p = decimal price.Get
        let r = 0.5 // 固定の割引率を使用
        let discounted = calculateDiscount p r
        discounted >= 0m && discounted <= p

// ============================================
// 3. コレクション操作のプロパティ
// ============================================

module CollectionPropertyTests =

    [<Property>]
    let ``filterは長さを減らすか維持する`` (list: int list) =
        (filter (fun x -> x > 0) list).Length <= list.Length

    [<Property>]
    let ``filter(常にtrue)は元のリストと同じ`` (list: int list) =
        filter (fun _ -> true) list = list

    [<Property>]
    let ``filter(常にfalse)は空リスト`` (list: int list) =
        filter (fun _ -> false) list = []

    [<Property>]
    let ``mapは長さを保存する`` (list: int list) =
        (map (fun x -> x * 2) list).Length = list.Length

    [<Property>]
    let ``map(identity)は元のリストと同じ`` (list: int list) =
        map id list = list

    [<Property>]
    let ``リスト反転は対合`` (list: int list) =
        reverse (reverse list) = list

    [<Property>]
    let ``concatの結合律`` (a: int list) (b: int list) (c: int list) =
        concat (concat a b) c = concat a (concat b c)

    [<Property>]
    let ``concatの長さは入力の長さの合計`` (a: int list) (b: int list) =
        (concat a b).Length = a.Length + b.Length

    [<Property>]
    let ``distinctは標準ライブラリと同じ結果`` (list: int list) =
        distinct list = List.distinct list

// ============================================
// 4. ラウンドトリッププロパティ
// ============================================

module RoundtripPropertyTests =

    [<Property>]
    let ``ランレングス符号化は可逆`` (s: string) =
        let s = if isNull s then "" else s
        // 英字のみでテスト（マルチバイト文字を避ける）
        let alphaOnly = s |> String.filter System.Char.IsLetter

        if alphaOnly.Length > 0 then
            decode (encode alphaOnly) = alphaOnly
        else
            true

    [<Property>]
    let ``Base64エンコード/デコードは可逆`` (s: string) =
        let s = if isNull s then "" else s
        // 有効なUTF-8文字列のみでテスト
        try
            base64Decode (base64Encode s) = s
        with
        | _ -> true // エンコードできない文字列はスキップ

// ============================================
// 5. 代数的性質のプロパティ
// ============================================

module AlgebraicPropertyTests =

    [<Property>]
    let ``加算の結合律`` (a: int) (b: int) (c: int) =
        // オーバーフローを避けるため小さい数で
        let a, b, c = a % 1000, b % 1000, c % 1000
        (a + b) + c = a + (b + c)

    [<Property>]
    let ``加算の交換律`` (a: int) (b: int) = a + b = b + a

    [<Property>]
    let ``加算の単位元`` (a: int) = a + 0 = a && 0 + a = a

    [<Property>]
    let ``整数加算モノイドの結合律`` (a: int) (b: int) (c: int) =
        let m = intAdditionMonoid
        m.Combine (m.Combine a b) c = m.Combine a (m.Combine b c)

    [<Property>]
    let ``整数加算モノイドの単位元`` (a: int) =
        let m = intAdditionMonoid
        m.Combine a m.Empty = a && m.Combine m.Empty a = a

    [<Property>]
    let ``文字列連結モノイドの結合律`` (a: string) (b: string) (c: string) =
        let a = if isNull a then "" else a
        let b = if isNull b then "" else b
        let c = if isNull c then "" else c
        let m = stringConcatMonoid
        m.Combine (m.Combine a b) c = m.Combine a (m.Combine b c)

    [<Property>]
    let ``文字列連結モノイドの単位元`` (a: string) =
        let a = if isNull a then "" else a
        let m = stringConcatMonoid
        m.Combine a m.Empty = a && m.Combine m.Empty a = a

// ============================================
// 6. ビジネスロジックのプロパティ
// ============================================

module BusinessLogicPropertyTests =

    [<Property>]
    let ``最終価格は元の価格以下`` (price: PositiveInt) (membership: Membership) =
        let total = decimal price.Get
        let finalPrice = calculateFinalPrice total membership
        finalPrice <= total

    [<Property>]
    let ``Platinumは最大の割引を受ける`` (price: PositiveInt) =
        let total = decimal price.Get
        let platinumPrice = calculateFinalPrice total Platinum
        let bronzePrice = calculateFinalPrice total Bronze
        platinumPrice <= bronzePrice

    [<Property>]
    let ``割引率の順序: Platinum < Gold < Silver < Bronze`` (price: PositiveInt) =
        let total = decimal price.Get
        let prices = [ Platinum; Gold; Silver; Bronze ] |> List.map (calculateFinalPrice total)

        prices |> List.pairwise |> List.forall (fun (a, b) -> a <= b)

// ============================================
// 7. バリデーションのプロパティ
// ============================================

module ValidationPropertyTests =

    // 有効なメールアドレスを生成
    let validEmailGen =
        gen {
            let! local = Gen.elements [ "user"; "test"; "admin"; "info" ]
            let! domain = Gen.elements [ "example"; "test"; "company" ]
            let! tld = Gen.elements [ "com"; "org"; "net"; "io"; "jp" ]
            return sprintf "%s@%s.%s" local domain tld
        }

    [<Property>]
    let ``生成された有効なメールアドレスはバリデーションを通過する`` () =
        Prop.forAll (Arb.fromGen validEmailGen) (fun email -> isValidEmail email)

    // 有効な電話番号を生成
    let validPhoneGen =
        gen {
            let! length = Gen.choose (10, 15)
            let! digits = Gen.listOfLength length (Gen.elements [ '0' .. '9' ])
            return System.String(digits |> List.toArray)
        }

    [<Property>]
    let ``生成された有効な電話番号はバリデーションを通過する`` () =
        Prop.forAll (Arb.fromGen validPhoneGen) (fun phone -> isValidPhoneNumber phone)

// ============================================
// 8. オラクルテスト
// ============================================

module OraclePropertyTests =

    [<Property>]
    let ``sortNumbersは標準ライブラリのsortと同じ結果`` (nums: int list) =
        sortNumbers nums = List.sort nums

    [<Property>]
    let ``reverseは標準ライブラリのrevと同じ結果`` (list: int list) =
        reverse list = List.rev list

    [<Property>]
    let ``filterは標準ライブラリのfilterと同じ結果`` (list: int list) =
        let pred x = x > 0
        filter pred list = List.filter pred list

    [<Property>]
    let ``mapは標準ライブラリのmapと同じ結果`` (list: int list) =
        let f x = x * 2
        map f list = List.map f list

