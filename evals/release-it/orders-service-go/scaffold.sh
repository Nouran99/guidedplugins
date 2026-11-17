#!/usr/bin/env bash
set -e
mkdir -p src/service

cat > src/service/main.go <<'GO'
package main

import (
	"database/sql"
	"log"
	"net/http"
	"os"
	"strconv"

	_ "github.com/lib/pq"
	"github.com/robfig/cron/v3"
)

func main() {
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = "postgres://orders:orders@localhost:5432/orders?sslmode=disable"
	}
	poolSize, _ := strconv.Atoi(os.Getenv("DB_POOL_SIZE"))

	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		log.Fatal(err)
	}
	db.SetMaxOpenConns(poolSize)

	if err := migrate(db); err != nil {
		log.Fatal(err)
	}

	scheduler := cron.New()
	scheduler.AddFunc("0 * * * *", func() { exportAll(db) })
	scheduler.Start()

	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	})
	mux.HandleFunc("/orders/", getOrder(db))
	mux.HandleFunc("/admin/purge", purgeHandler(db))

	log.Printf("orders service listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", mux))
}

func migrate(db *sql.DB) error {
	statements := []string{
		`create table if not exists tenants (id text primary key)`,
		`create table if not exists orders (
			id text primary key,
			tenant_id text not null references tenants (id),
			payload text not null,
			created_at timestamptz not null default now())`,
		`create index if not exists orders_tenant_created_idx on orders (tenant_id, created_at)`,
	}
	for _, statement := range statements {
		if _, err := db.Exec(statement); err != nil {
			return err
		}
	}
	return nil
}
GO

cat > src/service/jobs.go <<'GO'
package main

import (
	"database/sql"
	"log"
	"os"
	"time"
)

const archiveDir = "/var/lib/orders/archive"

// exportAll writes the last hour of orders of every tenant to the archive directory.
func exportAll(db *sql.DB) {
	tenants, err := db.Query("select id from tenants")
	if err != nil {
		log.Printf("export: listing tenants: %v", err)
		return
	}
	defer tenants.Close()

	for tenants.Next() {
		var id string
		tenants.Scan(&id)
		go exportTenant(db, id)
	}
}

func exportTenant(db *sql.DB, tenantID string) {
	rows, err := db.Query(
		"select payload from orders where tenant_id = $1 and created_at > now() - interval '1 hour'", tenantID)
	if err != nil {
		return
	}
	defer rows.Close()

	name := tenantID + "-" + time.Now().UTC().Format("2006-01-02T15") + ".jsonl"
	f, err := os.Create(archiveDir + "/" + name)
	if err != nil {
		return
	}
	defer f.Close()

	for rows.Next() {
		var payload string
		rows.Scan(&payload)
		f.WriteString(payload + "\n")
	}
}
GO

cat > src/service/handlers.go <<'GO'
package main

import (
	"database/sql"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
)

func getOrder(db *sql.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id := strings.TrimPrefix(r.URL.Path, "/orders/")
		var payload string
		err := db.QueryRowContext(r.Context(), "select payload from orders where id = $1", id).Scan(&payload)
		if errors.Is(err, sql.ErrNoRows) {
			http.NotFound(w, r)
			return
		}
		if err != nil {
			log.Printf("order lookup failed: id=%s err=%v", id, err)
			http.Error(w, "lookup failed", http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		io.WriteString(w, payload)
	}
}

func purgeHandler(db *sql.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		before := r.URL.Query().Get("before")
		res, err := db.Exec("delete from orders where created_at < $1", before)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		n, _ := res.RowsAffected()
		fmt.Fprintf(w, "deleted %d orders\n", n)
	}
}
GO
