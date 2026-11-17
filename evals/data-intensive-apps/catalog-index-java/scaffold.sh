#!/usr/bin/env bash
set -e
mkdir -p src/catalog

cat > src/catalog/ProductService.java <<'JAVA'
package catalog;

import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

/** Reads and edits products. Reads go to the replica to keep load off the primary. */
public class ProductService {
    private static final Logger LOG = Logger.getLogger(ProductService.class.getName());

    private final Database primary;
    private final Database replica;
    private final SearchIndex searchIndex;
    private final Cache cache;
    private final PricingClient pricing;

    public ProductService(Database primary, Database replica, SearchIndex searchIndex,
                          Cache cache, PricingClient pricing) {
        this.primary = primary;
        this.replica = replica;
        this.searchIndex = searchIndex;
        this.cache = cache;
        this.pricing = pricing;
    }

    public Product get(long id) {
        String cached = cache.get("product:" + id);
        if (cached != null) {
            return Product.fromJson(cached);
        }
        Product product = replica.queryOne("select * from products where id = ?", id);
        cache.set("product:" + id, product.toJson(), 3600);
        return product;
    }

    public Product update(long id, ProductForm form) {
        primary.execute(
            "update products set title = ?, description = ?, category = ?, tags = ? where id = ?",
            form.title(), form.description(), form.category(), form.tags(), id);

        Product saved = replica.queryOne("select * from products where id = ?", id);
        try {
            searchIndex.put("products", id, saved.toDocument());
            cache.set("product:" + id, saved.toJson(), 3600);
        } catch (RuntimeException e) {
            LOG.warning("search index or cache not updated for product " + id);
        }
        return saved;
    }

    public List<ProductView> listByCategory(String category) {
        List<Product> products = replica.query(
            "select * from products where category = ? order by title", category);
        List<ProductView> views = new ArrayList<>();
        for (Product product : products) {
            long priceCents = pricing.currentPriceCents(product.getId());
            views.add(new ProductView(product, priceCents));
        }
        return views;
    }
}
JAVA

cat > src/catalog/StockLedger.java <<'JAVA'
package catalog;

/** Tracks how many units of each product can still be sold. */
public class StockLedger {
    private final Cache cache;

    public StockLedger(Cache cache) {
        this.cache = cache;
    }

    public boolean reserve(long productId, int quantity) {
        long left = cache.decrBy(key(productId), quantity);
        if (left < 0) {
            cache.incrBy(key(productId), quantity);
            return false;
        }
        return true;
    }

    public void release(long productId, int quantity) {
        cache.incrBy(key(productId), quantity);
    }

    public void restock(long productId, int quantity) {
        cache.incrBy(key(productId), quantity);
    }

    public int available(long productId) {
        String value = cache.get(key(productId));
        return value == null ? 0 : Integer.parseInt(value);
    }

    private static String key(long productId) {
        return "stock:" + productId;
    }
}
JAVA

cat > src/catalog/SalesReport.java <<'JAVA'
package catalog;

import java.util.List;

/** Feeds the operations dashboard, which refreshes every ten seconds on every open screen. */
public class SalesReport {
    private final Database primary;

    public SalesReport(Database primary) {
        this.primary = primary;
    }

    public List<DailySales> lastNinetyDays() {
        return primary.query(
            "select date(created_at) as day, count(*) as orders, sum(total_cents) as revenue "
                + "from orders group by date(created_at) order by day desc limit 90");
    }

    public List<CategorySales> topCategories() {
        return primary.query(
            "select p.category, sum(l.quantity * l.unit_cents) as revenue "
                + "from order_lines l join products p on p.id = l.product_id "
                + "group by p.category order by revenue desc limit 10");
    }
}
JAVA
