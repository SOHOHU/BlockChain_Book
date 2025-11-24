package main

import (
	"crypto/rand"
	"encoding/hex"
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

const (
	sessionCookieName = "demo_sid"
	sessionCtxKey     = "session_handle"
)

// sessionEntry 存放会话数据及过期时间（示例仅存字符串）。
type sessionEntry struct {
	values map[string]string
	// 过期时间，时间戳类型
	expires time.Time
}

// SessionStore 持有全部 session 数据与配置，使用内存 map 存储。
type SessionStore struct {
	mu sync.RWMutex
	// 数据
	data  map[string]*sessionEntry
	ttl   time.Duration
	cname string
}

// NewSessionStore 创建一个 SessionStore。
func NewSessionStore(cookieName string, ttl time.Duration) *SessionStore {
	return &SessionStore{
		data:  make(map[string]*sessionEntry),
		ttl:   ttl,
		cname: cookieName,
	}
}

// Middleware 为每个请求加载/创建 session，并刷新 cookie。
// 用重构gin.HandlerFunc接口的方式
func (s *SessionStore) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 获取cookie
		sid, _ := c.Cookie(s.cname) // 取出客户端携带的 sid，如果没有则新建
		_, ok := s.get(sid)
		// 63行可知，新建一个sid，为一个sessionentry
		if !ok {
			sid, _ = s.new()
		}
		// 将 session 句柄放入上下文，供业务 handler 使用。
		// 在123行说明，set只是给session传值
		c.Set(sessionCtxKey, sessionHandle{id: sid, store: s})
		// 刷新 Cookie 以延长过期时间。
		c.SetCookie(s.cname, sid, int(s.ttl.Seconds()), "/", "", false, true)
		c.Next()
	}
}

func (s *SessionStore) new() (string, *sessionEntry) {
	b := make([]byte, 16)
	// rand.Read会将byte切片随机填充
	_, _ = rand.Read(b)
	sid := hex.EncodeToString(b)
	entry := &sessionEntry{
		values:  make(map[string]string),
		expires: time.Now().Add(s.ttl),
	}
	s.mu.Lock()
	s.data[sid] = entry
	s.mu.Unlock()
	return sid, entry
}

// 读sessionoentry
func (s *SessionStore) get(id string) (*sessionEntry, bool) {
	if id == "" {
		return nil, false
	}
	s.mu.RLock()
	entry, ok := s.data[id]
	s.mu.RUnlock()
	// 判断时间
	if !ok || time.Now().After(entry.expires) {
		if ok {
			s.delete(id)
		}
		return nil, false
	}
	return entry, true
}

func (s *SessionStore) delete(id string) {
	s.mu.Lock()
	delete(s.data, id)
	s.mu.Unlock()
}

func (s *SessionStore) setValue(id, key, val string) {
	// 设置sessionentry的值，结构
	s.mu.Lock() // 写入时刷新过期时间
	if entry, ok := s.data[id]; ok {
		entry.values[key] = val
		entry.expires = time.Now().Add(s.ttl)
	}
	s.mu.Unlock()
}

func (s *SessionStore) getValue(id, key string) (string, bool) {
	// 获取具体sessionid
	s.mu.RLock()
	entry, ok := s.data[id]
	if !ok {
		s.mu.RUnlock()
		return "", false
	}
	val, ok := entry.values[key]
	s.mu.RUnlock()
	return val, ok
}

// sessionHandle 是放入 gin.Context 的句柄，屏蔽内部锁。
type sessionHandle struct {
	id    string
	store *SessionStore
}

func (h sessionHandle) Set(key, val string) {
	h.store.setValue(h.id, key, val)
}

func (h sessionHandle) Get(key string) (string, bool) {
	return h.store.getValue(h.id, key)
}

func (h sessionHandle) Clear() {
	h.store.delete(h.id)
}

func sessionFromCtx(c *gin.Context) sessionHandle {
	if v, ok := c.Get(sessionCtxKey); ok {
		if h, ok := v.(sessionHandle); ok {
			return h
		}
	}
	return sessionHandle{}
}

func main() {
	r := gin.Default()

	// 演示普通 Cookie 的读写。
	r.GET("/cookie/set", func(c *gin.Context) {
		c.SetCookie("demo_cookie", "hello-cookie", 3600, "/", "", false, true)
		c.String(http.StatusOK, "cookie 已设置，键=demo_cookie，值=hello-cookie")
	})
	r.GET("/cookie/read", func(c *gin.Context) {
		val, err := c.Cookie("demo_cookie")
		if err != nil {
			c.String(http.StatusOK, "未找到 demo_cookie")
			return
		}
		c.String(http.StatusOK, "demo_cookie=%s", val)
	})

	// Session 中间件与路由。
	// 初始化
	store := NewSessionStore(sessionCookieName, 2*time.Hour)
	r.Use(store.Middleware())

	r.POST("/login", func(c *gin.Context) {
		username := c.PostForm("username")
		if username == "" {
			username = "guest"
		}
		// 获得一个sessionhandle
		sess := sessionFromCtx(c)
		sess.Set("user", username) // 将登录用户写入 session
		c.JSON(http.StatusOK, gin.H{"msg": "login ok", "user": username})
	})

	r.GET("/profile", func(c *gin.Context) {
		sess := sessionFromCtx(c)
		// 获取sessionentry具体的sessionid
		if user, ok := sess.Get("user"); ok {
			c.JSON(http.StatusOK, gin.H{"user": user, "note": "profile from session"})
			return
		}
		c.JSON(http.StatusUnauthorized, gin.H{"error": "no session, please login"})
	})

	r.POST("/logout", func(c *gin.Context) {
		sess := sessionFromCtx(c)
		// 清除session信息
		sess.Clear()
		// 删除 Cookie。
		c.SetCookie(sessionCookieName, "", -1, "/", "", false, true)
		c.JSON(http.StatusOK, gin.H{"msg": "logout ok"})
	})

	_ = r.Run(":8080")
}
