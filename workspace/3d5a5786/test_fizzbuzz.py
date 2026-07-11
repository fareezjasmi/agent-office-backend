from fizzbuzz import fizzbuzz


def test_fizzbuzz():
    assert fizzbuzz(1) == "1"
    assert fizzbuzz(3) == "Fizz"
    assert fizzbuzz(5) == "Buzz"
    assert fizzbuzz(15) == "FizzBuzz"
    assert fizzbuzz(20) == "Buzz"
    assert fizzbuzz(2) == "2"
    assert fizzbuzz(4) == "4"


if __name__ == "__main__":
    test_fizzbuzz()
    print("All tests passed!")
