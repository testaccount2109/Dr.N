package drn

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"strconv"
	"sync"
	"time"

	"github.com/sandertv/gophertunnel/minecraft"
	"github.com/sandertv/gophertunnel/minecraft/protocol/packet"
)

// ServerEntry represents a saved server configuration.
type ServerEntry struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Address string `json:"address"`
	Port    string `json:"port"`
}

// StatusJSON is the JSON-serializable status of the proxy.
type StatusJSON struct {
	Running      bool   `json:"running"`
	TargetServer string `json:"target_server,omitempty"`
	StartedAt    string `json:"started_at,omitempty"`
	PlayerCount  int    `json:"player_count"`
	LocalPort    int    `json:"local_port"`
}

// Core is the main proxy controller.
type Core struct {
	mu       sync.RWMutex
	servers  []*ServerEntry
	serverID int

	// Proxy state
	proxyCtx    context.Context
	proxyCancel context.CancelFunc
	listener    *minecraft.Listener
	status      StatusJSON
}

// NewCore creates a new Core instance.
func NewCore() *Core {
	return &Core{
		servers: make([]*ServerEntry, 0),
		status:  StatusJSON{Running: false},
	}
}

// AddServer adds a server and returns its ID.
func (c *Core) AddServer(name, address, port string) string {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.serverID++
	id := fmt.Sprintf("srv_%d", c.serverID)
	c.servers = append(c.servers, &ServerEntry{ID: id, Name: name, Address: address, Port: port})
	return id
}

// RemoveServer removes a server by ID.
func (c *Core) RemoveServer(id string) bool {
	c.mu.Lock()
	defer c.mu.Unlock()
	for i, s := range c.servers {
		if s.ID == id {
			c.servers = append(c.servers[:i], c.servers[i+1:]...)
			return true
		}
	}
	return false
}

// GetServers returns all saved servers.
func (c *Core) GetServers() []*ServerEntry {
	c.mu.RLock()
	defer c.mu.RUnlock()
	r := make([]*ServerEntry, len(c.servers))
	copy(r, c.servers)
	return r
}

// GetServersJSON returns servers as JSON.
func (c *Core) GetServersJSON() string {
	c.mu.RLock()
	defer c.mu.RUnlock()
	d, _ := json.Marshal(c.servers)
	return string(d)
}

// GetStatusJSON returns current status as JSON.
func (c *Core) GetStatusJSON() string {
	c.mu.RLock()
	defer c.mu.RUnlock()
	d, _ := json.Marshal(c.status)
	return string(d)
}

// IsRunning returns whether the proxy is active.
func (c *Core) IsRunning() bool {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.status.Running
}

// StartProxy starts a full MITM proxy that forwards traffic between
// the console (client) and the target Bedrock server.
// All traffic goes through the phone, ensuring maximum compatibility.
func (c *Core) StartProxy(serverAddress, serverPort string) error {
	c.mu.Lock()
	if c.status.Running {
		c.mu.Unlock()
		return fmt.Errorf("proxy is already running")
	}
	c.mu.Unlock()

	target := net.JoinHostPort(serverAddress, serverPort)

	ctx, cancel := context.WithCancel(context.Background())
	defer func() {
		if c.status.Running == false {
			cancel()
		}
	}()

	// Create a status provider that fetches live status from the remote server
	statusProvider, err := minecraft.NewForeignStatusProvider(target)
	if err != nil {
		cancel()
		return fmt.Errorf("failed to create status provider: %w", err)
	}

	// Listen on a random port (the phone will advertise via LAN pings)
	listener, err := minecraft.ListenConfig{
		StatusProvider:          statusProvider,
		AuthenticationDisabled:  true,
		MaximumPlayers:          5,
	}.Listen("raknet", "0.0.0.0:0")
	if err != nil {
		cancel()
		return fmt.Errorf("failed to start listener: %w", err)
	}

	localAddr := listener.Addr().(*net.UDPAddr)

	c.mu.Lock()
	c.listener = listener
	c.proxyCtx = ctx
	c.proxyCancel = cancel
	c.status = StatusJSON{
		Running:      true,
		TargetServer: target,
		StartedAt:    time.Now().Format(time.RFC3339),
		LocalPort:    localAddr.Port,
	}
	c.mu.Unlock()

	log.Printf("Dr.N proxy started on port %d, targeting %s", localAddr.Port, target)

	go c.acceptLoop(ctx, listener, target)
	return nil
}

// acceptLoop accepts incoming connections and spawns proxy handlers.
func (c *Core) acceptLoop(ctx context.Context, listener *minecraft.Listener, target string) {
	defer func() {
		listener.Close()
		c.mu.Lock()
		c.status = StatusJSON{Running: false}
		c.mu.Unlock()
	}()

	for {
		conn, err := listener.Accept()
		if err != nil {
			select {
			case <-ctx.Done():
				return
			default:
				log.Printf("accept error: %v", err)
				return
			}
		}

		go c.handleConn(ctx, conn.(*minecraft.Conn), target)
	}
}

// handleConn handles a connection from the console (PS5/Xbox/Switch).
// It uses the BedrockTogether-style TRANSFER approach:
// 1. Console connects to phone (LAN)
// 2. Phone dials the real server to get GameData
// 3. Phone sends StartGame + Transfer packet to console
// 4. Console reconnects DIRECTLY to the real server
// 5. Phone can go to sleep 🎉
func (c *Core) handleConn(ctx context.Context, clientConn *minecraft.Conn, target string) {
	addr := clientConn.RemoteAddr().String()
	log.Printf("New connection from %s -> transferring to %s", addr, target)

	c.mu.Lock()
	c.status.PlayerCount++
	c.mu.Unlock()

	defer func() {
		clientConn.Close()
		c.mu.Lock()
		c.status.PlayerCount--
		if c.status.PlayerCount < 0 {
			c.status.PlayerCount = 0
		}
		c.mu.Unlock()
	}()

	// Dial the remote server to get its GameData
	// This is only needed for the StartGame packet (not for proxying)
	serverConn, err := minecraft.Dialer{
		ClientData:   clientConn.ClientData(),
		IdentityData: clientConn.IdentityData(),
	}.Dial("raknet", target)
	if err != nil {
		log.Printf("failed to dial remote %s: %v", target, err)
		return
	}

	// Complete server handshake so we get GameData
	if err := serverConn.DoSpawn(); err != nil {
		log.Printf("DoSpawn error on remote: %v", err)
		serverConn.Close()
		return
	}

	// Send StartGame to the console with the REAL server's game data
	// This makes the console think it's connected to the remote server
	if err := clientConn.StartGame(serverConn.GameData()); err != nil {
		log.Printf("StartGame error on client: %v", err)
		serverConn.Close()
		return
	}

	// Close the temporary connection to the remote server
	serverConn.Close()

	// Parse target address for the Transfer packet
	host, portStr, err := net.SplitHostPort(target)
	if err != nil {
		log.Printf("invalid target %s: %v", target, err)
		return
	}
	portNum := 19132
	if p, err := strconv.Atoi(portStr); err == nil {
		portNum = p
	}

	// Send TRANSFER packet → tells PS5 "go connect to this server directly!"
	transferPk := &packet.Transfer{
		Address: host,
		Port:    uint16(portNum),
	}
	if err := clientConn.WritePacket(transferPk); err != nil {
		log.Printf("transfer error: %v", err)
		return
	}

	log.Printf("✅ Transferred %s -> %s (phone can sleep now!)", addr, target)

	// Wait a moment for the transfer to be sent, then close
	// The PS5 reconnects directly to the real server
	time.Sleep(500 * time.Millisecond)
}

// StopProxy stops the running proxy.
func (c *Core) StopProxy() error {
	c.mu.Lock()
	defer c.mu.Unlock()

	if !c.status.Running {
		return fmt.Errorf("proxy is not running")
	}

	c.proxyCancel()
	if c.listener != nil {
		c.listener.Close()
	}
	c.status = StatusJSON{Running: false}
	log.Println("Dr.N proxy stopped")
	return nil
}