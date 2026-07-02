// Package drnbind provides gomobile-compatible bindings for the Dr.N proxy core.
//
// Build for Android:
//
//	cd go/core && gomobile bind -target=android -o ../../flutter_app/android/app/libs/drn.aar github.com/b3nni/drn/core/drnbind
//
// Build for iOS:
//
//	cd go/core && gomobile bind -target=ios -o ../../flutter_app/ios/Runner/drn.xcframework github.com/b3nni/drn/core/drnbind
package drnbind

import "github.com/b3nni/drn/core/drn"

// Core wraps the proxy logic for gomobile export.
type Core struct {
	inner *drn.Core
}

// NewCore creates a new proxy controller.
func NewCore() *Core {
	return &Core{inner: drn.NewCore()}
}

// AddServer adds a server to the saved list. Returns the server ID.
func (c *Core) AddServer(name, address, port string) string {
	return c.inner.AddServer(name, address, port)
}

// RemoveServer removes a server by ID. Returns true if found and removed.
func (c *Core) RemoveServer(id string) bool {
	return c.inner.RemoveServer(id)
}

// GetServersJSON returns saved servers as a JSON array string.
func (c *Core) GetServersJSON() string {
	return c.inner.GetServersJSON()
}

// GetStatusJSON returns the current proxy status as JSON.
func (c *Core) GetStatusJSON() string {
	return c.inner.GetStatusJSON()
}

// IsRunning returns whether the proxy is currently active.
func (c *Core) IsRunning() bool {
	return c.inner.IsRunning()
}

// StartProxy starts the proxy targeting serverAddress:serverPort.
func (c *Core) StartProxy(serverAddress, serverPort string) error {
	return c.inner.StartProxy(serverAddress, serverPort)
}

// StopProxy stops the running proxy.
func (c *Core) StopProxy() error {
	return c.inner.StopProxy()
}