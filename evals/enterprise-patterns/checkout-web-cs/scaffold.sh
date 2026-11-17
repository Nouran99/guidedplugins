#!/usr/bin/env bash
set -e
mkdir -p src/Checkout/Views

cat > src/Checkout/Cart.cs <<'CS'
namespace Checkout;

public record CartLine(string Sku, string Name, decimal UnitPrice, int Quantity);

public class Cart
{
    public List<CartLine> Lines { get; } = new();

    public decimal Total => Lines.Sum(line => line.UnitPrice * line.Quantity);
}

public static class CartSession
{
    private static readonly Dictionary<string, Cart> Carts = new();

    public static Cart Get(string cartId)
    {
        if (!Carts.TryGetValue(cartId, out var cart))
        {
            cart = new Cart();
            Carts[cartId] = cart;
        }
        return cart;
    }

    public static void Clear(string cartId)
    {
        Carts.Remove(cartId);
    }
}
CS

cat > src/Checkout/CheckoutController.cs <<'CS'
using Microsoft.AspNetCore.Mvc;

namespace Checkout;

public class CheckoutController : Controller
{
    private readonly OrderManager _manager;

    public CheckoutController(OrderManager manager)
    {
        _manager = manager;
    }

    [HttpPost]
    public IActionResult Add(string sku, string name, decimal unitPrice, int quantity)
    {
        var cartId = Request.Cookies["cart_id"] ?? Guid.NewGuid().ToString("N");
        Response.Cookies.Append("cart_id", cartId);
        CartSession.Get(cartId).Lines.Add(new CartLine(sku, name, unitPrice, quantity));
        return RedirectToAction("Summary");
    }

    public IActionResult Summary()
    {
        var cart = CartSession.Get(Request.Cookies["cart_id"] ?? "");
        return View(cart);
    }

    [HttpPost]
    public IActionResult Place()
    {
        var orderId = _manager.Place(Request.Form);
        Response.Cookies.Delete("cart_id");
        return RedirectToAction("Done", new { id = orderId });
    }

    public IActionResult Done(int id)
    {
        return View(id);
    }
}
CS

cat > src/Checkout/OrderManager.cs <<'CS'
using Microsoft.AspNetCore.Http;

namespace Checkout;

public class OrderManager
{
    private readonly OrderService _service;

    public OrderManager(OrderService service)
    {
        _service = service;
    }

    public int Place(IFormCollection form)
    {
        return _service.Place(form);
    }

    public Order? Find(int orderId)
    {
        return _service.Find(orderId);
    }
}
CS

cat > src/Checkout/OrderService.cs <<'CS'
using Microsoft.AspNetCore.Http;

namespace Checkout;

public class OrderService
{
    private readonly OrderDao _dao;

    public OrderService(OrderDao dao)
    {
        _dao = dao;
    }

    public int Place(IFormCollection form)
    {
        var cartId = form["cart_id"].ToString();
        var cart = CartSession.Get(cartId);
        if (cart.Lines.Count == 0)
        {
            throw new InvalidOperationException("The cart is empty.");
        }

        var order = new Order
        {
            Email = form["email"].ToString(),
            Address = form["address"].ToString(),
            Total = cart.Total,
            Lines = cart.Lines.ToList(),
        };
        var orderId = _dao.Insert(order);

        var mailer = Ioc.Resolve<IMailer>();
        mailer.Send(order.Email, "Your order " + orderId, "Thank you. Total: " + order.Total.ToString("C"));

        CartSession.Clear(cartId);
        return orderId;
    }

    public Order? Find(int orderId)
    {
        return _dao.Find(orderId);
    }
}
CS

cat > src/Checkout/OrderDao.cs <<'CS'
using System.Data.SqlClient;

namespace Checkout;

public class Order
{
    public int Id { get; set; }
    public string Email { get; set; } = "";
    public string Address { get; set; } = "";
    public decimal Total { get; set; }
    public List<CartLine> Lines { get; set; } = new();
}

public class OrderDao
{
    private readonly string _connectionString;

    public OrderDao(string connectionString)
    {
        _connectionString = connectionString;
    }

    public int Insert(Order order)
    {
        using var connection = new SqlConnection(_connectionString);
        connection.Open();
        using var transaction = connection.BeginTransaction();

        var header = new SqlCommand(
            "insert into Orders (Email, Address, Total) output inserted.Id values (@email, @address, @total)",
            connection, transaction);
        header.Parameters.AddWithValue("@email", order.Email);
        header.Parameters.AddWithValue("@address", order.Address);
        header.Parameters.AddWithValue("@total", order.Total);
        var orderId = (int)header.ExecuteScalar()!;

        foreach (var line in order.Lines)
        {
            var row = new SqlCommand(
                "insert into OrderLines (OrderId, Sku, UnitPrice, Quantity) values (@id, @sku, @price, @qty)",
                connection, transaction);
            row.Parameters.AddWithValue("@id", orderId);
            row.Parameters.AddWithValue("@sku", line.Sku);
            row.Parameters.AddWithValue("@price", line.UnitPrice);
            row.Parameters.AddWithValue("@qty", line.Quantity);
            row.ExecuteNonQuery();
        }

        transaction.Commit();
        return orderId;
    }

    public Order? Find(int orderId)
    {
        using var connection = new SqlConnection(_connectionString);
        connection.Open();
        var command = new SqlCommand("select Email, Address, Total from Orders where Id = @id", connection);
        command.Parameters.AddWithValue("@id", orderId);
        using var reader = command.ExecuteReader();
        if (!reader.Read())
        {
            return null;
        }
        return new Order
        {
            Id = orderId,
            Email = reader.GetString(0),
            Address = reader.GetString(1),
            Total = reader.GetDecimal(2),
        };
    }
}
CS

cat > src/Checkout/Ioc.cs <<'CS'
namespace Checkout;

public interface IMailer
{
    void Send(string to, string subject, string body);
}

public static class Ioc
{
    private static IServiceProvider? _provider;

    public static void Init(IServiceProvider provider)
    {
        _provider = provider;
    }

    public static T Resolve<T>() where T : notnull
    {
        return (T)_provider!.GetService(typeof(T))!;
    }
}
CS

cat > src/Checkout/Views/Summary.cshtml <<'CSHTML'
@model Checkout.Cart
@{
    var subtotal = Model.Lines.Sum(line => line.UnitPrice * line.Quantity);
    var freeShipping = subtotal >= 75m || Model.Lines.Any(line => line.Sku.StartsWith("GIFT"));
    var shipping = freeShipping ? 0m : 6.90m;
    var discount = Model.Lines.Count >= 5 ? subtotal * 0.05m : 0m;
}
<h1>Your basket</h1>
<table>
  @foreach (var line in Model.Lines)
  {
    <tr>
      <td>@line.Name</td>
      <td>@line.Quantity</td>
      <td>@((line.UnitPrice * line.Quantity).ToString("C"))</td>
    </tr>
  }
</table>
<p>Subtotal: @subtotal.ToString("C")</p>
@if (discount > 0)
{
  <p>Bulk discount: -@discount.ToString("C")</p>
}
<p>Shipping: @(freeShipping ? "free" : shipping.ToString("C"))</p>
<p><strong>Total: @((subtotal - discount + shipping).ToString("C"))</strong></p>
<form method="post" action="/checkout/place">
  <input type="hidden" name="cart_id" value="@Context.Request.Cookies["cart_id"]" />
  <input type="email" name="email" />
  <textarea name="address"></textarea>
  <button type="submit">Place order</button>
</form>
CSHTML
