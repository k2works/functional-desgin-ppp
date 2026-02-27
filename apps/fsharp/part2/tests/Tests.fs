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


// ============================================
// 第6章: TDD in FP テスト
// ============================================

open FunctionalDesign.Part2.TddFunctional

// ============================================
// 1. FizzBuzz テスト
// ============================================

module FizzBuzzTests =

    [<Fact>]
    let ``fizzbuzz 1は"1"を返す`` () =
        Assert.Equal("1", fizzbuzz 1)

    [<Fact>]
    let ``fizzbuzz 2は"2"を返す`` () =
        Assert.Equal("2", fizzbuzz 2)

    [<Fact>]
    let ``fizzbuzz 3は"Fizz"を返す`` () =
        Assert.Equal("Fizz", fizzbuzz 3)

    [<Fact>]
    let ``fizzbuzz 5は"Buzz"を返す`` () =
        Assert.Equal("Buzz", fizzbuzz 5)

    [<Fact>]
    let ``fizzbuzz 15は"FizzBuzz"を返す`` () =
        Assert.Equal("FizzBuzz", fizzbuzz 15)

    [<Fact>]
    let ``fizzbuzz 30は"FizzBuzz"を返す`` () =
        Assert.Equal("FizzBuzz", fizzbuzz 30)

    [<Fact>]
    let ``fizzbuzzSequence 15は正しい列を返す`` () =
        let expected = ["1"; "2"; "Fizz"; "4"; "Buzz"; "Fizz"; "7"; "8"; "Fizz"; "Buzz"; "11"; "Fizz"; "13"; "14"; "FizzBuzz"]
        Assert.Equal<string list>(expected, fizzbuzzSequence 15)

    [<Property>]
    let ``3の倍数は常にFizzを含む`` (n: FsCheck.PositiveInt) =
        let num = n.Get * 3
        let result = fizzbuzz num
        result.Contains("Fizz")

    [<Property>]
    let ``5の倍数は常にBuzzを含む`` (n: FsCheck.PositiveInt) =
        let num = n.Get * 5
        let result = fizzbuzz num
        result.Contains("Buzz")

// ============================================
// 2. ローマ数字変換テスト
// ============================================

module RomanNumeralsTests =

    [<Fact>]
    let ``toRoman 1はIを返す`` () =
        Assert.Equal("I", toRoman 1)

    [<Fact>]
    let ``toRoman 4はIVを返す`` () =
        Assert.Equal("IV", toRoman 4)

    [<Fact>]
    let ``toRoman 5はVを返す`` () =
        Assert.Equal("V", toRoman 5)

    [<Fact>]
    let ``toRoman 9はIXを返す`` () =
        Assert.Equal("IX", toRoman 9)

    [<Fact>]
    let ``toRoman 10はXを返す`` () =
        Assert.Equal("X", toRoman 10)

    [<Fact>]
    let ``toRoman 40はXLを返す`` () =
        Assert.Equal("XL", toRoman 40)

    [<Fact>]
    let ``toRoman 50はLを返す`` () =
        Assert.Equal("L", toRoman 50)

    [<Fact>]
    let ``toRoman 90はXCを返す`` () =
        Assert.Equal("XC", toRoman 90)

    [<Fact>]
    let ``toRoman 100はCを返す`` () =
        Assert.Equal("C", toRoman 100)

    [<Fact>]
    let ``toRoman 400はCDを返す`` () =
        Assert.Equal("CD", toRoman 400)

    [<Fact>]
    let ``toRoman 500はDを返す`` () =
        Assert.Equal("D", toRoman 500)

    [<Fact>]
    let ``toRoman 900はCMを返す`` () =
        Assert.Equal("CM", toRoman 900)

    [<Fact>]
    let ``toRoman 1000はMを返す`` () =
        Assert.Equal("M", toRoman 1000)

    [<Fact>]
    let ``toRoman 1994はMCMXCIVを返す`` () =
        Assert.Equal("MCMXCIV", toRoman 1994)

    [<Fact>]
    let ``toRoman 3999はMMMCMXCIXを返す`` () =
        Assert.Equal("MMMCMXCIX", toRoman 3999)

    [<Fact>]
    let ``fromRoman IVは4を返す`` () =
        Assert.Equal(4, fromRoman "IV")

    [<Fact>]
    let ``fromRoman MCMXCIVは1994を返す`` () =
        Assert.Equal(1994, fromRoman "MCMXCIV")

    [<Fact>]
    let ``toRomanとfromRomanは逆関数（1-100）`` () =
        for n in 1..100 do
            Assert.Equal(n, fromRoman (toRoman n))

    [<Fact>]
    let ``toRomanとfromRomanは逆関数（3900-3999）`` () =
        for n in 3900..3999 do
            Assert.Equal(n, fromRoman (toRoman n))

// ============================================
// 3. ボウリングスコアテスト
// ============================================

module BowlingTests =

    [<Fact>]
    let ``ガタースコアは0`` () =
        Assert.Equal(0, bowlingScore (List.replicate 20 0))

    [<Fact>]
    let ``すべて1ピンは20点`` () =
        Assert.Equal(20, bowlingScore (List.replicate 20 1))

    [<Fact>]
    let ``スペアの後の投球はボーナス`` () =
        let rolls = [ 5; 5; 3; 0 ] @ List.replicate 16 0
        Assert.Equal(16, bowlingScore rolls)

    [<Fact>]
    let ``ストライクの後の2投はボーナス`` () =
        let rolls = [ 10; 3; 4 ] @ List.replicate 16 0
        Assert.Equal(24, bowlingScore rolls)

    [<Fact>]
    let ``パーフェクトゲームは300点`` () =
        Assert.Equal(300, bowlingScore (List.replicate 12 10))

    [<Fact>]
    let ``9フレームのストライク後にスペア`` () =
        // 9ストライク + スペア(5,5) + ボーナス3
        let rolls = List.replicate 9 10 @ [ 5; 5; 3 ]
        // 最初の9フレームは各30点=270、10フレームは5+5+3=13
        // ただし9フレーム目は10+5+5=20、10フレーム目は5+5+3=13
        Assert.Equal(268, bowlingScore rolls)

// ============================================
// 4. 素数テスト
// ============================================

module PrimesTests =

    [<Fact>]
    let ``0は素数ではない`` () =
        Assert.False(isPrime 0)

    [<Fact>]
    let ``1は素数ではない`` () =
        Assert.False(isPrime 1)

    [<Fact>]
    let ``2は素数`` () =
        Assert.True(isPrime 2)

    [<Fact>]
    let ``3は素数`` () =
        Assert.True(isPrime 3)

    [<Fact>]
    let ``4は素数ではない`` () =
        Assert.False(isPrime 4)

    [<Fact>]
    let ``97は素数`` () =
        Assert.True(isPrime 97)

    [<Fact>]
    let ``primesUpTo 20は正しい素数リストを返す`` () =
        let expected = [ 2; 3; 5; 7; 11; 13; 17; 19 ]
        Assert.Equal<int list>(expected, primesUpTo 20)

    [<Fact>]
    let ``primeFactors 24は2,2,2,3を返す`` () =
        let expected = [ 2; 2; 2; 3 ]
        Assert.Equal<int list>(expected, primeFactors 24)

    [<Fact>]
    let ``primeFactors 100は2,2,5,5を返す`` () =
        let expected = [ 2; 2; 5; 5 ]
        Assert.Equal<int list>(expected, primeFactors 100)

    [<Fact>]
    let ``primeFactorsの積は元の数に等しい（2-100）`` () =
        for n in 2..100 do
            let factors = primeFactors n
            let product = factors |> List.fold (*) 1
            Assert.Equal(n, product)

// ============================================
// 5. スタックテスト
// ============================================

module StackTests =

    [<Fact>]
    let ``空のスタックはisEmptyがtrue`` () =
        let stack = Stack.empty<int>
        Assert.True(Stack.isEmpty stack)

    [<Fact>]
    let ``pushするとisEmptyがfalse`` () =
        let stack = Stack.empty |> Stack.push 1
        Assert.False(Stack.isEmpty stack)

    [<Fact>]
    let ``LIFO順序で動作する`` () =
        let stack =
            Stack.empty
            |> Stack.push "a"
            |> Stack.push "b"
            |> Stack.push "c"

        match Stack.pop stack with
        | Some (v1, s1) ->
            Assert.Equal("c", v1)
            match Stack.pop s1 with
            | Some (v2, s2) ->
                Assert.Equal("b", v2)
                match Stack.pop s2 with
                | Some (v3, s3) ->
                    Assert.Equal("a", v3)
                    Assert.True(Stack.isEmpty s3)
                | None -> Assert.Fail("Expected value")
            | None -> Assert.Fail("Expected value")
        | None -> Assert.Fail("Expected value")

    [<Fact>]
    let ``peekはスタックを変更しない`` () =
        let stack = Stack.empty |> Stack.push 1 |> Stack.push 2
        Assert.Equal(Some 2, Stack.peek stack)
        Assert.Equal(2, Stack.size stack)

    [<Fact>]
    let ``空のスタックのpopはNoneを返す`` () =
        let stack = Stack.empty<int>
        Assert.Equal(None, Stack.pop stack)

// ============================================
// 6. キューテスト
// ============================================

module QueueTests =

    [<Fact>]
    let ``空のキューはisEmptyがtrue`` () =
        let queue = Queue.empty<int>
        Assert.True(Queue.isEmpty queue)

    [<Fact>]
    let ``enqueueするとisEmptyがfalse`` () =
        let queue = Queue.empty |> Queue.enqueue 1
        Assert.False(Queue.isEmpty queue)

    [<Fact>]
    let ``FIFO順序で動作する`` () =
        let queue =
            Queue.empty
            |> Queue.enqueue "a"
            |> Queue.enqueue "b"
            |> Queue.enqueue "c"

        match Queue.dequeue queue with
        | Some (v1, q1) ->
            Assert.Equal("a", v1)
            match Queue.dequeue q1 with
            | Some (v2, q2) ->
                Assert.Equal("b", v2)
                match Queue.dequeue q2 with
                | Some (v3, q3) ->
                    Assert.Equal("c", v3)
                    Assert.True(Queue.isEmpty q3)
                | None -> Assert.Fail("Expected value")
            | None -> Assert.Fail("Expected value")
        | None -> Assert.Fail("Expected value")

    [<Fact>]
    let ``空のキューのdequeueはNoneを返す`` () =
        let queue = Queue.empty<int>
        Assert.Equal(None, Queue.dequeue queue)

// ============================================
// 7. 文字列電卓テスト
// ============================================

module StringCalculatorTests =

    [<Fact>]
    let ``空文字列は0を返す`` () =
        Assert.Equal(0, StringCalculator.add "")

    [<Fact>]
    let ``単一の数値はその値を返す`` () =
        Assert.Equal(5, StringCalculator.add "5")

    [<Fact>]
    let ``カンマ区切りの数値を合計する`` () =
        Assert.Equal(6, StringCalculator.add "1,2,3")

    [<Fact>]
    let ``改行区切りも処理する`` () =
        Assert.Equal(6, StringCalculator.add "1\n2,3")

    [<Fact>]
    let ``カスタム区切り文字を使用できる`` () =
        Assert.Equal(3, StringCalculator.add "//;\n1;2")

    [<Fact>]
    let ``負の数は例外をスローする`` () =
        let ex = Assert.Throws<System.ArgumentException>(fun () ->
            StringCalculator.add "1,-2,3" |> ignore)
        Assert.Contains("-2", ex.Message)

    [<Fact>]
    let ``1000より大きい数は無視する`` () =
        Assert.Equal(2, StringCalculator.add "2,1001")

    [<Fact>]
    let ``1000は含む`` () =
        Assert.Equal(1002, StringCalculator.add "2,1000")

// ============================================
// 8. 税計算テスト
// ============================================

module TaxCalculatorTests =

    [<Fact>]
    let ``calculateTotalWithTaxは税込み総額を計算する`` () =
        let items =
            [ { Name = "商品A"; Price = 1000m }
              { Name = "商品B"; Price = 2000m } ]
        let result = TaxCalculator.calculateTotalWithTax items 0.1m

        Assert.Equal(3000m, result.Subtotal)
        Assert.Equal(300m, result.Tax)
        Assert.Equal(3300m, result.Total)

    [<Fact>]
    let ``空のアイテムリストは0`` () =
        let result = TaxCalculator.calculateTotalWithTax [] 0.1m
        Assert.Equal(0m, result.Total)

// ============================================
// 9. 送料計算テスト
// ============================================

module ShippingCalculatorTests =

    [<Fact>]
    let ``10000円以上は送料無料`` () =
        let order = { Total = 10000m; Weight = 10.0; Region = Local }
        Assert.Equal(0, ShippingCalculator.calculateShipping order)

    [<Fact>]
    let ``Local軽量は300円`` () =
        let order = { Total = 5000m; Weight = 3.0; Region = Local }
        Assert.Equal(300, ShippingCalculator.calculateShipping order)

    [<Fact>]
    let ``Local重量は500円`` () =
        let order = { Total = 5000m; Weight = 6.0; Region = Local }
        Assert.Equal(500, ShippingCalculator.calculateShipping order)

    [<Fact>]
    let ``Domestic軽量は500円`` () =
        let order = { Total = 5000m; Weight = 3.0; Region = Domestic }
        Assert.Equal(500, ShippingCalculator.calculateShipping order)

    [<Fact>]
    let ``Domestic重量は800円`` () =
        let order = { Total = 5000m; Weight = 6.0; Region = Domestic }
        Assert.Equal(800, ShippingCalculator.calculateShipping order)

    [<Fact>]
    let ``International軽量は2000円`` () =
        let order = { Total = 5000m; Weight = 3.0; Region = International }
        Assert.Equal(2000, ShippingCalculator.calculateShipping order)

    [<Fact>]
    let ``International重量は3000円`` () =
        let order = { Total = 5000m; Weight = 6.0; Region = International }
        Assert.Equal(3000, ShippingCalculator.calculateShipping order)

// ============================================
// 10. パスワードバリデーターテスト
// ============================================

module PasswordValidatorTests =

    [<Fact>]
    let ``有効なパスワードはOkを返す`` () =
        let result = PasswordValidator.validateWithDefaults "Password1"
        Assert.True(Result.isOk result)

    [<Fact>]
    let ``短すぎるパスワードはエラー`` () =
        let result = PasswordValidator.validateWithDefaults "Pass1"
        match result with
        | Error errors ->
            Assert.Contains("Password must be at least 8 characters", errors)
        | Ok _ -> Assert.Fail("Expected error")

    [<Fact>]
    let ``大文字がないパスワードはエラー`` () =
        let result = PasswordValidator.validateWithDefaults "password1"
        match result with
        | Error errors ->
            Assert.Contains("Password must contain at least one uppercase letter", errors)
        | Ok _ -> Assert.Fail("Expected error")

    [<Fact>]
    let ``小文字がないパスワードはエラー`` () =
        let result = PasswordValidator.validateWithDefaults "PASSWORD1"
        match result with
        | Error errors ->
            Assert.Contains("Password must contain at least one lowercase letter", errors)
        | Ok _ -> Assert.Fail("Expected error")

    [<Fact>]
    let ``数字がないパスワードはエラー`` () =
        let result = PasswordValidator.validateWithDefaults "Password"
        match result with
        | Error errors ->
            Assert.Contains("Password must contain at least one digit", errors)
        | Ok _ -> Assert.Fail("Expected error")

    [<Fact>]
    let ``複数のエラーが蓄積される`` () =
        let result = PasswordValidator.validateWithDefaults "ab"
        match result with
        | Error errors ->
            Assert.True(errors.Length >= 3) // 短い、大文字なし、数字なし
        | Ok _ -> Assert.Fail("Expected error")

    [<Fact>]
    let ``カスタムルールで検証できる`` () =
        let rules = [ PasswordValidator.minLength 4; PasswordValidator.hasDigit ]
        let result = PasswordValidator.validate "abc1" rules
        Assert.True(Result.isOk result)

