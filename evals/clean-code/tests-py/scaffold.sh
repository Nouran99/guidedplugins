#!/usr/bin/env bash
set -e
mkdir -p tests
cat > tests/test_orders.py <<'PY'
import time
import pytest
from orders import Cart

cart = Cart()


def test1():
    cart.add("apple", 2)
    assert cart.total() == 2
    cart.add("pear", 3)
    assert cart.total() == 5
    assert cart.count() == 2
    cart.remove("apple")
    assert cart.total() == 3
    assert cart.count() == 1


def test2():
    # runs after test1 and relies on its leftovers
    assert cart.count() == 1


def test_discount():
    time.sleep(2)
    c = Cart()
    c.add("tv", 1000)
    print(c.total())


@pytest.mark.skip
def test_refund():
    assert Cart().refund("x") == 0
PY
