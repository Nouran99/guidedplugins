#!/usr/bin/env bash
set -e
mkdir -p src/main/java/shop/receipts src/test/java/shop/receipts

cat > src/main/java/shop/receipts/Config.java <<'JAVA'
package shop.receipts;

public final class Config {
    private Config() {}

    public static String get(String key) {
        String value = System.getProperty(key);
        if (value == null) {
            throw new IllegalStateException("missing setting " + key);
        }
        return value;
    }
}
JAVA

cat > src/main/java/shop/receipts/Order.java <<'JAVA'
package shop.receipts;

import java.util.List;

public record Order(String id, String customerId, String customerEmail, List<Line> lines) {
    public record Line(String description, long cents) {}
}
JAVA

cat > src/main/java/shop/receipts/OrderRepository.java <<'JAVA'
package shop.receipts;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class OrderRepository {
    private static final OrderRepository INSTANCE = new OrderRepository();

    private final Map<String, Order> byId = new ConcurrentHashMap<>();

    private OrderRepository() {}

    public static OrderRepository instance() {
        return INSTANCE;
    }

    public void save(Order order) {
        byId.put(order.id(), order);
    }

    public Order find(String id) {
        return byId.get(id);
    }
}
JAVA

cat > src/main/java/shop/receipts/ReceiptMailer.java <<'JAVA'
package shop.receipts;

import com.acme.mail.MailRelay;
import com.acme.pdf.PdfWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import javax.servlet.http.HttpServletRequest;

public class ReceiptMailer {
    private final MailRelay relay;
    private final String archiveDir;

    public ReceiptMailer() {
        this.relay = new MailRelay(System.getenv("MAIL_RELAY_HOST"), 587);
        this.relay.open();
        this.archiveDir = Config.get("receipts.archive.dir");
    }

    public void handleResend(HttpServletRequest request) throws IOException {
        String orderId = request.getParameter("orderId");
        String customerId = request.getHeader("X-Customer-Id");
        Order order = OrderRepository.instance().find(orderId);
        if (order == null || !order.customerId().equals(customerId)) {
            return;
        }
        sendReceipt(order);
    }

    public void sendReceipt(Order order) throws IOException {
        PdfWriter pdf = new PdfWriter(Config.get("receipts.font.dir"));
        pdf.title("Receipt " + order.id() + " issued " + LocalDate.now());
        long total = 0;
        for (Order.Line line : order.lines()) {
            pdf.row(line.description(), line.cents());
            total += line.cents();
        }
        pdf.row("Total", total);
        byte[] bytes = pdf.bytes();

        Files.write(Path.of(archiveDir, order.id() + ".pdf"), bytes);
        relay.deliver(order.customerEmail(), "Your receipt " + order.id(), bytes);
    }
}
JAVA

cat > src/test/java/shop/receipts/ReceiptMailerTest.java <<'JAVA'
package shop.receipts;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import com.acme.mail.MailRelay;
import java.nio.file.Path;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.Mockito;
import org.springframework.test.util.ReflectionTestUtils;

class ReceiptMailerTest {
    @TempDir
    Path archive;

    @Test
    void sendsTheReceiptToTheCustomer() throws Exception {
        System.setProperty("receipts.font.dir", "src/test/fonts");
        ReceiptMailer mailer = Mockito.mock(ReceiptMailer.class, Mockito.CALLS_REAL_METHODS);
        MailRelay relay = mock(MailRelay.class);
        ReflectionTestUtils.setField(mailer, "relay", relay);
        ReflectionTestUtils.setField(mailer, "archiveDir", archive.toString());

        Order order = new Order("o-1", "c-1", "ann@example.com", List.of(new Order.Line("pen", 150)));
        mailer.sendReceipt(order);

        verify(relay).deliver(eq("ann@example.com"), any(), any());
    }
}
JAVA
