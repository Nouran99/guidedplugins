#!/usr/bin/env bash
set -e
mkdir -p src/Ordering
cat > src/Ordering/Order.cs <<'CS'
using Shop.Api.Contracts;

namespace Shop.Ordering;

public class Order
{
    public Guid Id { get; set; }
    public Customer Customer { get; set; } = null!;
    public List<OrderLine> Lines { get; set; } = new();
    public OrderStatus Status { get; set; }
    public DateTime PlacedAt { get; set; }

    public decimal Total => Lines.Sum(l => l.Quantity * l.Product.Price);

    public static Order From(PlaceOrderRequest request, Customer customer, IEnumerable<Product> catalog)
    {
        var order = new Order
        {
            Id = Guid.NewGuid(),
            Customer = customer,
            Status = OrderStatus.Draft,
        };
        foreach (var item in request.Items)
        {
            var product = catalog.Single(p => p.Sku == item.Sku);
            order.Lines.Add(new OrderLine { Product = product, Quantity = item.Quantity });
        }
        return order;
    }
}

public class OrderLine
{
    public Product Product { get; set; } = null!;
    public int Quantity { get; set; }
}

public enum OrderStatus
{
    Draft,
    Placed,
    Shipped,
    Cancelled,
}
CS
cat > src/Ordering/Customer.cs <<'CS'
namespace Shop.Ordering;

public class Customer
{
    public Guid Id { get; set; }
    public string Name { get; set; } = "";
    public string Email { get; set; } = "";
    public Account Account { get; set; } = null!;
    public List<Order> Orders { get; set; } = new();
}

public class Account
{
    public decimal CreditLimit { get; set; }
    public decimal Balance { get; set; }
}
CS
cat > src/Ordering/Stock.cs <<'CS'
namespace Shop.Ordering;

public class Product
{
    public string Sku { get; set; } = "";
    public string Title { get; set; } = "";
    public decimal Price { get; set; }
}

public class StockItem
{
    public string Sku { get; set; } = "";
    public int OnHand { get; set; }
}
CS
cat > src/Ordering/PlaceOrderHandler.cs <<'CS'
using Microsoft.EntityFrameworkCore;
using Shop.Api.Contracts;
using Shop.Infrastructure;

namespace Shop.Ordering;

public record OrderUpdated(Guid OrderId, string Field, string From, string To);

public class PlaceOrderHandler
{
    private readonly ShopDbContext _db;
    private readonly IEventBus _bus;

    public PlaceOrderHandler(ShopDbContext db, IEventBus bus)
    {
        _db = db;
        _bus = bus;
    }

    public async Task<Guid> Handle(PlaceOrderRequest request)
    {
        var customer = await _db.Customers
            .Include(c => c.Account)
            .SingleAsync(c => c.Id == request.CustomerId);
        var skus = request.Items.Select(i => i.Sku).ToList();
        var catalog = await _db.Products.Where(p => skus.Contains(p.Sku)).ToListAsync();
        var order = Order.From(request, customer, catalog);

        if (customer.Account.CreditLimit - customer.Account.Balance < order.Total)
        {
            throw new InvalidOperationException("Credit limit exceeded");
        }

        foreach (var line in order.Lines)
        {
            var stock = await _db.StockItems.SingleAsync(s => s.Sku == line.Product.Sku);
            if (stock.OnHand < line.Quantity)
            {
                throw new InvalidOperationException($"Not enough stock for {stock.Sku}");
            }
            stock.OnHand -= line.Quantity;
        }

        customer.Account.Balance += order.Total;
        order.Status = OrderStatus.Placed;
        order.PlacedAt = DateTime.UtcNow;

        _db.Orders.Add(order);
        await _db.SaveChangesAsync();

        await _bus.Publish(new OrderUpdated(order.Id, "Status", "Draft", "Placed"));
        return order.Id;
    }

    public async Task ChangeQuantity(Guid orderId, string sku, int quantity)
    {
        var order = await _db.Orders
            .Include(o => o.Lines)
            .ThenInclude(l => l.Product)
            .SingleAsync(o => o.Id == orderId);
        var line = order.Lines.Single(l => l.Product.Sku == sku);
        var before = line.Quantity;
        line.Quantity = quantity;
        await _db.SaveChangesAsync();
        await _bus.Publish(new OrderUpdated(order.Id, "Quantity", before.ToString(), quantity.ToString()));
    }
}
CS
