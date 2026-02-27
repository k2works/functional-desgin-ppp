package strategypattern

import org.scalatest.funspec.AnyFunSpec
import org.scalatest.matchers.should.Matchers

class StrategyPatternSpec extends AnyFunSpec with Matchers:

  // ============================================
  // 1. 料金計算戦略（トレイトベース）
  // ============================================

  describe("PricingStrategy") {
    describe("RegularPricing") {
      it("金額をそのまま返す") {
        RegularPricing.calculatePrice(BigDecimal(1000)) shouldBe BigDecimal(1000)
      }
    }

    describe("DiscountPricing") {
      it("割引率を適用する") {
        val strategy = DiscountPricing(BigDecimal("0.10"))
        strategy.calculatePrice(BigDecimal(1000)) shouldBe BigDecimal(900)
      }

      it("0%割引は金額をそのまま返す") {
        val strategy = DiscountPricing(BigDecimal(0))
        strategy.calculatePrice(BigDecimal(1000)) shouldBe BigDecimal(1000)
      }

      it("100%割引は0を返す") {
        val strategy = DiscountPricing(BigDecimal(1))
        strategy.calculatePrice(BigDecimal(1000)) shouldBe BigDecimal(0)
      }
    }

    describe("MemberPricing") {
      it("ゴールド会員は20%割引") {
        val strategy = MemberPricing(MemberLevel.Gold)
        strategy.calculatePrice(BigDecimal(1000)) shouldBe BigDecimal(800)
      }

      it("シルバー会員は15%割引") {
        val strategy = MemberPricing(MemberLevel.Silver)
        strategy.calculatePrice(BigDecimal(1000)) shouldBe BigDecimal(850)
      }

      it("ブロンズ会員は10%割引") {
        val strategy = MemberPricing(MemberLevel.Bronze)
        strategy.calculatePrice(BigDecimal(1000)) shouldBe BigDecimal(900)
      }
    }

    describe("BulkPricing") {
      val strategy = BulkPricing(threshold = 10, bulkDiscount = BigDecimal("0.15"))

      it("しきい値以上で大量購入割引を適用する") {
        strategy.calculatePrice(BigDecimal(1000), quantity = 10) shouldBe BigDecimal(850)
      }

      it("しきい値未満では割引なし") {
        strategy.calculatePrice(BigDecimal(1000), quantity = 5) shouldBe BigDecimal(1000)
      }
    }
  }

  // ============================================
  // 2. ショッピングカート（Context）
  // ============================================

  describe("ShoppingCart") {
    val item1 = CartItem("Item A", BigDecimal(500))
    val item2 = CartItem("Item B", BigDecimal(300), quantity = 2)

    describe("基本操作") {
      it("商品を追加できる") {
        val cart = ShoppingCart.empty.addItem(item1)
        cart.items should contain(item1)
      }

      it("商品を削除できる") {
        val cart = ShoppingCart(item1, item2).removeItem("Item A")
        cart.items should not contain item1
        cart.items should contain(item2)
      }

      it("小計を計算する") {
        val cart = ShoppingCart(item1, item2)
        cart.subtotal shouldBe BigDecimal(1100) // 500 + 300*2
      }

      it("商品数を返す") {
        val cart = ShoppingCart(item1, item2)
        cart.itemCount shouldBe 3 // 1 + 2
      }
    }

    describe("戦略の適用") {
      val cart = ShoppingCart(item1, item2)

      it("通常料金で合計を計算する") {
        cart.total shouldBe BigDecimal(1100)
      }

      it("割引戦略を適用する") {
        val discountedCart = cart.changeStrategy(DiscountPricing(BigDecimal("0.10")))
        discountedCart.total shouldBe BigDecimal(990)
      }

      it("会員戦略を適用する") {
        val memberCart = cart.changeStrategy(MemberPricing(MemberLevel.Gold))
        memberCart.total shouldBe BigDecimal(880)
      }

      it("戦略を変更できる") {
        val cart1 = cart.changeStrategy(MemberPricing(MemberLevel.Bronze))
        val cart2 = cart1.changeStrategy(MemberPricing(MemberLevel.Gold))
        cart1.total shouldBe BigDecimal(990) // 10% off
        cart2.total shouldBe BigDecimal(880) // 20% off
      }
    }
  }

  // ============================================
  // 3. 関数型アプローチ
  // ============================================

  describe("FunctionalStrategy") {
    import FunctionalStrategy._

    describe("基本戦略") {
      it("regular は identity") {
        regular(BigDecimal(1000)) shouldBe BigDecimal(1000)
      }

      it("discount は割引を適用する") {
        discount(BigDecimal("0.10"))(BigDecimal(1000)) shouldBe BigDecimal(900)
      }

      it("member は会員割引を適用する") {
        member(MemberLevel.Gold)(BigDecimal(1000)) shouldBe BigDecimal(800)
      }

      it("tax は税金を加算する") {
        tax(BigDecimal("0.10"))(BigDecimal(1000)) shouldBe BigDecimal(1100)
      }

      it("fixedDiscount は固定額を引く") {
        fixedDiscount(BigDecimal(100))(BigDecimal(1000)) shouldBe BigDecimal(900)
      }

      it("fixedDiscount は0未満にならない") {
        fixedDiscount(BigDecimal(1500))(BigDecimal(1000)) shouldBe BigDecimal(0)
      }
    }

    describe("戦略の合成") {
      it("複数の戦略を順番に適用する") {
        val composed = compose(
          discount(BigDecimal("0.10")),
          tax(BigDecimal("0.08"))
        )
        // 1000 * 0.9 * 1.08 = 972
        composed(BigDecimal(1000)) shouldBe BigDecimal("972.00")
      }

      it("3つ以上の戦略を合成できる") {
        val composed = compose(
          discount(BigDecimal("0.10")),
          discount(BigDecimal("0.05")),
          tax(BigDecimal("0.10"))
        )
        // 1000 * 0.9 * 0.95 * 1.1 = 940.5
        composed(BigDecimal(1000)) shouldBe BigDecimal("940.500")
      }
    }

    describe("条件付き戦略") {
      it("条件を満たす場合は then 戦略を適用") {
        val strategy = conditional(
          _ >= BigDecimal(5000),
          discount(BigDecimal("0.20")),
          regular
        )
        strategy(BigDecimal(6000)) shouldBe BigDecimal(4800)
      }

      it("条件を満たさない場合は else 戦略を適用") {
        val strategy = conditional(
          _ >= BigDecimal(5000),
          discount(BigDecimal("0.20")),
          regular
        )
        strategy(BigDecimal(3000)) shouldBe BigDecimal(3000)
      }
    }

    describe("段階別戦略") {
      val tierStrategy = tiered(List(
        BigDecimal(10000) -> discount(BigDecimal("0.20")),
        BigDecimal(5000) -> discount(BigDecimal("0.10")),
        BigDecimal(0) -> regular
      ))

      it("10000円以上で20%割引") {
        tierStrategy(BigDecimal(10000)) shouldBe BigDecimal(8000)
      }

      it("5000円以上で10%割引") {
        tierStrategy(BigDecimal(6000)) shouldBe BigDecimal(5400)
      }

      it("5000円未満は割引なし") {
        tierStrategy(BigDecimal(3000)) shouldBe BigDecimal(3000)
      }
    }

    describe("ユーティリティ戦略") {
      it("clamp は範囲内に制限する") {
        val clamped = clamp(BigDecimal(100), BigDecimal(1000))
        clamped(BigDecimal(50)) shouldBe BigDecimal(100)
        clamped(BigDecimal(500)) shouldBe BigDecimal(500)
        clamped(BigDecimal(2000)) shouldBe BigDecimal(1000)
      }

      it("round は指定桁数で丸める") {
        val rounded = round(0)
        rounded(BigDecimal("123.456")) shouldBe BigDecimal(123)
      }
    }
  }

  // ============================================
  // 4. 関数型カート
  // ============================================

  describe("FunctionalCart") {
    import FunctionalStrategy._

    val item1 = CartItem("Item A", BigDecimal(500))
    val item2 = CartItem("Item B", BigDecimal(500))

    it("戦略を追加して合計を計算する") {
      val cart = FunctionalCart(List(item1, item2))
        .addStrategy(discount(BigDecimal("0.10")))
        .addStrategy(tax(BigDecimal("0.08")))
      
      // 1000 * 1.0 (regular) * 0.9 * 1.08 = 972
      cart.total shouldBe BigDecimal("972.00")
    }

    it("戦略をクリアできる") {
      val cart = FunctionalCart(List(item1, item2))
        .addStrategy(discount(BigDecimal("0.20")))
        .clearStrategies()
      
      cart.total shouldBe BigDecimal(1000)
    }
  }

  // ============================================
  // 5. 配送料金戦略
  // ============================================

  describe("ShippingStrategy") {
    describe("StandardShipping") {
      it("重量と距離に基づいて計算する") {
        // weight * 10 + distance * 5
        StandardShipping.calculate(2.0, 100.0) shouldBe BigDecimal(520)
      }
    }

    describe("ExpressShipping") {
      it("標準より高いレートで計算する") {
        // weight * 20 + distance * 15
        ExpressShipping.calculate(2.0, 100.0) shouldBe BigDecimal(1540)
      }
    }

    describe("FreeShipping") {
      it("常に0を返す") {
        FreeShipping(BigDecimal(5000)).calculate(10.0, 1000.0) shouldBe BigDecimal(0)
      }
    }

    describe("WeightBasedShipping") {
      val strategy = WeightBasedShipping(
        baseRate = BigDecimal(500),
        perKgRate = BigDecimal(100),
        freeThreshold = 20.0
      )

      it("基本料金 + 重量ベースで計算する") {
        strategy.calculate(5.0, 0.0) shouldBe BigDecimal(1000) // 500 + 5*100
      }

      it("しきい値以上は無料") {
        strategy.calculate(25.0, 0.0) shouldBe BigDecimal(0)
      }
    }

    describe("DistanceBasedShipping") {
      val strategy = DistanceBasedShipping(
        baseRate = BigDecimal(300),
        perKmRate = BigDecimal(2),
        zones = Map(0 -> BigDecimal(500), 1 -> BigDecimal(800), 2 -> BigDecimal(1200))
      )

      it("ゾーン料金が設定されている場合はゾーン料金を返す") {
        strategy.calculate(0.0, 50.0) shouldBe BigDecimal(500)   // zone 0
        strategy.calculate(0.0, 150.0) shouldBe BigDecimal(800)  // zone 1
        strategy.calculate(0.0, 250.0) shouldBe BigDecimal(1200) // zone 2
      }

      it("ゾーン料金がない場合は距離ベースで計算する") {
        strategy.calculate(0.0, 350.0) shouldBe BigDecimal(1000) // 300 + 350*2
      }
    }
  }

  // ============================================
  // 6. 注文コンテキスト
  // ============================================

  describe("Order") {
    val cart = ShoppingCart(
      CartItem("Item A", BigDecimal(1000)),
      CartItem("Item B", BigDecimal(500))
    )

    it("商品合計と配送料を計算する") {
      val order = Order(cart, StandardShipping, weight = 2.0, distance = 50.0)
      order.itemsTotal shouldBe BigDecimal(1500)
      order.shippingCost shouldBe BigDecimal(270) // 2*10 + 50*5
      order.grandTotal shouldBe BigDecimal(1770)
    }

    it("配送戦略を変更できる") {
      val order = Order(cart, StandardShipping, weight = 2.0, distance = 50.0)
      val expressOrder = order.changeShipping(ExpressShipping)
      expressOrder.shippingCost shouldBe BigDecimal(790) // 2*20 + 50*15
    }

    it("無料配送を適用できる") {
      val order = Order(cart, FreeShipping(BigDecimal(1000)), weight = 2.0, distance = 50.0)
      order.shippingCost shouldBe BigDecimal(0)
      order.grandTotal shouldBe BigDecimal(1500)
    }
  }

  // ============================================
  // 7. 支払い戦略
  // ============================================

  describe("PaymentStrategy") {
    describe("CreditCardPayment") {
      val payment = CreditCardPayment("1234567890123456", BigDecimal("0.03"))

      it("手数料を計算する") {
        payment.fee(BigDecimal(1000)) shouldBe BigDecimal(30)
      }

      it("支払いを実行する") {
        val result = payment.pay(BigDecimal(1000))
        result.success shouldBe true
        result.transactionId shouldBe defined
        result.fee shouldBe BigDecimal(30)
      }
    }

    describe("BankTransferPayment") {
      val payment = BankTransferPayment("0001", BigDecimal(300))

      it("固定手数料を返す") {
        payment.fee(BigDecimal(1000)) shouldBe BigDecimal(300)
        payment.fee(BigDecimal(10000)) shouldBe BigDecimal(300)
      }

      it("支払いを実行する") {
        val result = payment.pay(BigDecimal(1000))
        result.success shouldBe true
        result.fee shouldBe BigDecimal(300)
      }
    }

    describe("CashOnDeliveryPayment") {
      val payment = CashOnDeliveryPayment(BigDecimal(500))

      it("固定手数料を返す") {
        payment.fee(BigDecimal(1000)) shouldBe BigDecimal(500)
      }
    }

    describe("PointsPayment") {
      it("十分なポイントがあれば成功する") {
        val payment = PointsPayment(10000)
        val result = payment.pay(BigDecimal(50)) // 50 / 0.01 = 5000 points needed
        result.success shouldBe true
        result.fee shouldBe BigDecimal(0)
      }

      it("ポイントが不足していると失敗する") {
        val payment = PointsPayment(100)
        val result = payment.pay(BigDecimal(50)) // 5000 points needed
        result.success shouldBe false
      }
    }
  }

  // ============================================
  // 8. ソート戦略
  // ============================================

  describe("SortStrategy") {
    import SortStrategy._

    val numbers = List(3, 1, 4, 1, 5, 9, 2, 6)

    it("昇順でソートする") {
      ascending[Int].apply(numbers) shouldBe List(1, 1, 2, 3, 4, 5, 6, 9)
    }

    it("降順でソートする") {
      descending[Int].apply(numbers) shouldBe List(9, 6, 5, 4, 3, 2, 1, 1)
    }

    it("カスタムキーでソートする") {
      case class Person(name: String, age: Int)
      val people = List(Person("Bob", 30), Person("Alice", 25), Person("Charlie", 35))
      
      byKey[Person, String](_.name).apply(people).map(_.name) shouldBe List("Alice", "Bob", "Charlie")
      byKey[Person, Int](_.age).apply(people).map(_.name) shouldBe List("Alice", "Bob", "Charlie")
    }
  }

  // ============================================
  // 9. バリデーション戦略
  // ============================================

  describe("ValidationStrategy") {
    import ValidationStrategy._

    describe("基本バリデータ") {
      it("always は常に有効") {
        always(42).isValid shouldBe true
      }

      it("never は常に無効") {
        never("error")(42).isValid shouldBe false
      }

      it("predicate は条件を満たせば有効") {
        val positive = predicate[Int](_ > 0, "Must be positive")
        positive(1).isValid shouldBe true
        positive(-1).isValid shouldBe false
      }
    }

    describe("数値バリデータ") {
      it("min は最小値をチェックする") {
        val atLeast10 = min(10, "Must be at least 10")
        atLeast10(10).isValid shouldBe true
        atLeast10(9).isValid shouldBe false
      }

      it("max は最大値をチェックする") {
        val atMost100 = max(100, "Must be at most 100")
        atMost100(100).isValid shouldBe true
        atMost100(101).isValid shouldBe false
      }

      it("range は範囲をチェックする") {
        val between1And10 = range(1, 10, "Must be 1-10")
        between1And10(5).isValid shouldBe true
        between1And10(0).isValid shouldBe false
        between1And10(11).isValid shouldBe false
      }
    }

    describe("合成バリデータ") {
      it("all は全てのバリデータを満たす必要がある") {
        val validator = ValidationStrategy.all(
          min(0, "Must be non-negative"),
          max(100, "Must be at most 100")
        )
        validator(50).isValid shouldBe true
        validator(-1).isValid shouldBe false
        validator(101).isValid shouldBe false
      }

      it("any は少なくとも1つのバリデータを満たせばよい") {
        val validator = any(
          predicate[Int](_ < 0, "negative"),
          predicate[Int](_ > 100, "greater than 100")
        )
        validator(-1).isValid shouldBe true
        validator(101).isValid shouldBe true
        validator(50).isValid shouldBe false
      }

      it("all はエラーを蓄積する") {
        val validator = ValidationStrategy.all(
          min(0, "Error A"),
          max(10, "Error B")
        )
        validator(-5) match
          case Invalid(errors) => errors should contain ("Error A")
          case _ => fail("Expected Invalid")
      }
    }
  }

  // ============================================
  // 10. 検索戦略
  // ============================================

  describe("SearchStrategy") {
    import SearchStrategy._

    val numbers = List(1, 2, 3, 4, 5, 4, 3, 2, 1)

    it("findFirst は最初の一致を返す") {
      findFirst(numbers, (_: Int) > 3) shouldBe Some(4)
    }

    it("findLast は最後の一致を返す") {
      findLast(numbers, (_: Int) > 3) shouldBe Some(4)
    }

    it("findAll は全ての一致を返す") {
      findAll(numbers, (_: Int) > 3) shouldBe List(4, 5, 4)
    }

    it("binarySearch はソート済みリストで検索する") {
      val sorted = List(1, 2, 3, 4, 5, 6, 7, 8, 9)
      binarySearch(5).apply(sorted) shouldBe Some(4)
      binarySearch(10).apply(sorted) shouldBe None
    }
  }
