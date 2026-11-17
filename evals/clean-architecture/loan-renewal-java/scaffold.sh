#!/usr/bin/env bash
set -e
mkdir -p src/library/domain src/library/application src/library/infrastructure src/library/web

cat > src/library/domain/Loan.java <<'JAVA'
package library.domain;

import java.time.LocalDate;

public class Loan {
    private final String id;
    private final String memberId;
    private final String title;
    private LocalDate dueOn;
    private int renewals;

    public Loan(String id, String memberId, String title, LocalDate dueOn, int renewals) {
        this.id = id;
        this.memberId = memberId;
        this.title = title;
        this.dueOn = dueOn;
        this.renewals = renewals;
    }

    public String getId() {
        return id;
    }

    public String getMemberId() {
        return memberId;
    }

    public String getTitle() {
        return title;
    }

    public LocalDate getDueOn() {
        return dueOn;
    }

    public void setDueOn(LocalDate dueOn) {
        this.dueOn = dueOn;
    }

    public int getRenewals() {
        return renewals;
    }

    public void setRenewals(int renewals) {
        this.renewals = renewals;
    }

    public boolean isOverdue() {
        return dueOn.isBefore(LocalDate.now());
    }
}
JAVA

cat > src/library/application/RenewLoan.java <<'JAVA'
package library.application;

import library.domain.Loan;
import library.infrastructure.LoanStore;
import library.infrastructure.SmtpNotifier;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

public class RenewLoan {
    private final LoanStore loans;

    public RenewLoan(LoanStore loans) {
        this.loans = loans;
    }

    public ResponseEntity<String> execute(String loanId) {
        Loan loan = loans.findById(loanId).orElse(null);
        if (loan == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("No loan " + loanId);
        }

        loan.setDueOn(loan.getDueOn().plusDays(14));
        loan.setRenewals(loan.getRenewals() + 1);
        loans.save(loan);

        SmtpNotifier notifier = new SmtpNotifier(System.getenv("SMTP_HOST"), 587);
        notifier.send(loan.getMemberId(), "Loan renewed",
            loan.getTitle() + " is now due on " + loan.getDueOn());

        return ResponseEntity.ok("Renewed until " + loan.getDueOn());
    }
}
JAVA

cat > src/library/infrastructure/LoanStore.java <<'JAVA'
package library.infrastructure;

import java.util.Optional;
import library.domain.Loan;

public interface LoanStore {
    Optional<Loan> findById(String id);

    void save(Loan loan);
}
JAVA

cat > src/library/infrastructure/JdbcLoanStore.java <<'JAVA'
package library.infrastructure;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Optional;
import javax.sql.DataSource;
import library.domain.Loan;

public class JdbcLoanStore implements LoanStore {
    private final DataSource dataSource;

    public JdbcLoanStore(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public Optional<Loan> findById(String id) {
        String sql = "select member_id, title, due_on, renewals from loans where id = ?";
        try (Connection connection = dataSource.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, id);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                return Optional.of(new Loan(
                    id,
                    rs.getString("member_id"),
                    rs.getString("title"),
                    rs.getDate("due_on").toLocalDate(),
                    rs.getInt("renewals")));
            }
        } catch (SQLException e) {
            throw new IllegalStateException("could not load loan " + id, e);
        }
    }

    @Override
    public void save(Loan loan) {
        String sql = "update loans set due_on = ?, renewals = ? where id = ?";
        try (Connection connection = dataSource.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setDate(1, Date.valueOf(loan.getDueOn()));
            statement.setInt(2, loan.getRenewals());
            statement.setString(3, loan.getId());
            statement.executeUpdate();
        } catch (SQLException e) {
            throw new IllegalStateException("could not save loan " + loan.getId(), e);
        }
    }
}
JAVA

cat > src/library/infrastructure/SmtpNotifier.java <<'JAVA'
package library.infrastructure;

import jakarta.mail.Message;
import jakarta.mail.MessagingException;
import jakarta.mail.Session;
import jakarta.mail.Transport;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;
import java.util.Properties;

public class SmtpNotifier {
    private final Session session;

    public SmtpNotifier(String host, int port) {
        Properties props = new Properties();
        props.put("mail.smtp.host", host);
        props.put("mail.smtp.port", String.valueOf(port));
        this.session = Session.getInstance(props);
    }

    public void send(String memberId, String subject, String body) {
        try {
            MimeMessage message = new MimeMessage(session);
            message.setFrom(new InternetAddress("desk@library.example.org"));
            message.setRecipients(Message.RecipientType.TO, memberId + "@members.library.example.org");
            message.setSubject(subject);
            message.setText(body);
            Transport.send(message);
        } catch (MessagingException e) {
            throw new IllegalStateException(e);
        }
    }
}
JAVA

cat > src/library/web/LoanController.java <<'JAVA'
package library.web;

import library.application.RenewLoan;
import library.domain.Loan;
import library.infrastructure.LoanStore;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/loans")
public class LoanController {
    private final RenewLoan renewLoan;
    private final LoanStore loans;

    public LoanController(RenewLoan renewLoan, LoanStore loans) {
        this.renewLoan = renewLoan;
        this.loans = loans;
    }

    @PostMapping("/{id}/renew")
    public ResponseEntity<String> renew(@PathVariable("id") String id) {
        Loan loan = loans.findById(id).orElse(null);
        if (loan != null && loan.getRenewals() >= 2) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body("A loan can be renewed twice at most");
        }
        if (loan != null && loan.isOverdue()) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body("Overdue loans must be returned first");
        }
        return renewLoan.execute(id);
    }
}
JAVA

cat > src/library/LoanRenewalTest.java <<'JAVA'
package library;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class LoanRenewalTest {
    @Autowired
    private MockMvc mvc;

    @Autowired
    private JdbcTemplate jdbc;

    @BeforeEach
    void seed() {
        jdbc.update("delete from loans");
        jdbc.update("insert into loans(id, member_id, title, due_on, renewals) "
            + "values ('L1', 'M1', 'Dune', current_date + 5, 0)");
        jdbc.update("insert into loans(id, member_id, title, due_on, renewals) "
            + "values ('L2', 'M1', 'Emma', current_date + 5, 2)");
    }

    @Test
    void firstRenewalIsAccepted() throws Exception {
        mvc.perform(post("/loans/L1/renew")).andExpect(status().isOk());
    }

    @Test
    void thirdRenewalIsRefused() throws Exception {
        mvc.perform(post("/loans/L2/renew"))
            .andExpect(status().isConflict())
            .andExpect(content().string("A loan can be renewed twice at most"));
    }
}
JAVA
