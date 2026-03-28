package main

import (
    "fmt"
    "net/http"
    "os"
)

func main() {
    host := os.Getenv("HOST")
    if host == "" {
        host = "0.0.0.0"
    }

    port := os.Getenv("PORT")
    if port == "" {
        port = "8081"
    }

    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        _, _ = w.Write([]byte(`{"status":"ok"}`))
    })

    addr := fmt.Sprintf("%s:%s", host, port)
    fmt.Printf("Go server em %s\n", addr)
    _ = http.ListenAndServe(addr, nil)
}
