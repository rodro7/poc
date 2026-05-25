package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/nats-io/nats.go"
)

var (
	natsURL   = getEnv("NATS_URL", "nats://nats:4222")
	jwtSecret = getEnv("JWT_SECRET", "change-me-in-production")
	port      = getEnv("PORT", "8080")
)

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

type AuthRequest struct {
	Token string `json:"token"`
}

type AuthResponse struct {
	Valid   bool   `json:"valid"`
	UserID string `json:"user_id,omitempty"`
	Error  string `json:"error,omitempty"`
}

type Claims struct {
	UserID string `json:"user_id"`
	jwt.RegisteredClaims
}

func validateToken(tokenStr string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(jwtSecret), nil
	})
	if err != nil {
		return nil, err
	}
	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, fmt.Errorf("invalid token claims")
	}
	return claims, nil
}

func generateToken(userID string) (string, error) {
	claims := &Claims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(jwtSecret))
}

func authHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req AuthRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, AuthResponse{Error: "invalid request body"})
		return
	}

	claims, err := validateToken(req.Token)
	if err != nil {
		writeJSON(w, http.StatusUnauthorized, AuthResponse{Valid: false, Error: err.Error()})
		return
	}

	writeJSON(w, http.StatusOK, AuthResponse{Valid: true, UserID: claims.UserID})
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok", "service": "auth-nats"})
}

func writeJSON(w http.ResponseWriter, status int, v interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}

func setupNATSAuth(nc *nats.Conn) {
	// Subscribe to auth requests on NATS
	nc.Subscribe("auth.validate", func(msg *nats.Msg) {
		var req AuthRequest
		if err := json.Unmarshal(msg.Data, &req); err != nil {
			resp, _ := json.Marshal(AuthResponse{Error: "invalid request"})
			msg.Respond(resp)
			return
		}

		tokenStr := strings.TrimPrefix(req.Token, "Bearer ")
		claims, err := validateToken(tokenStr)
		if err != nil {
			resp, _ := json.Marshal(AuthResponse{Valid: false, Error: err.Error()})
			msg.Respond(resp)
			return
		}

		resp, _ := json.Marshal(AuthResponse{Valid: true, UserID: claims.UserID})
		msg.Respond(resp)
	})

	log.Println("Subscribed to auth.validate on NATS")
}

func main() {
	// Connect to NATS
	nc, err := nats.Connect(natsURL,
		nats.RetryOnFailedConnect(true),
		nats.MaxReconnects(-1),
		nats.ReconnectWait(2*time.Second),
	)
	if err != nil {
		log.Printf("Warning: Could not connect to NATS at %s: %v", natsURL, err)
	} else {
		defer nc.Close()
		setupNATSAuth(nc)
		log.Printf("Connected to NATS at %s", natsURL)
	}

	// HTTP server
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/auth/validate", authHandler)

	addr := ":" + port
	log.Printf("Auth-NATS service listening on %s", addr)
	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
