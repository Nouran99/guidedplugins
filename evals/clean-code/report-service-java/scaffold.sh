#!/usr/bin/env bash
set -e
mkdir -p src
cat > src/ReportService.java <<'JAVA'
import java.util.*;

public class ReportService {
    public static Map<String, Integer> counts = new HashMap<String, Integer>();
    public String title;
    public List<String> rows = new ArrayList<String>();

    public void generate(Customer c) {
        String city = c.getAddress().getCity().getName().toUpperCase();
        Db db = ServiceLocator.get("db");
        List<String> data = db.query("select * from orders where city='" + city + "'");
        for (String d : data) {
            rows.add(d.trim());
            counts.put(city, counts.getOrDefault(city, 0) + 1);
        }
        StringBuilder sb = new StringBuilder();
        sb.append("<html><h1>").append(title).append("</h1>");
        for (String r : rows) {
            sb.append("<p>").append(r).append("</p>");
        }
        sb.append("</html>");
        Files.write("/tmp/" + city + ".html", sb.toString());
        Mailer.send(c.getEmail(), sb.toString());
    }

    public static void bump(String city) {
        counts.put(city, counts.get(city) + 1);
    }
}
JAVA
