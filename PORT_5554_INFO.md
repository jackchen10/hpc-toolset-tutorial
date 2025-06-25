# 端口 5554 - OnDemand Dex 身份认证服务

## 🔍 服务说明

**端口 5554**运行的是**OnDemand Dex**身份认证服务，这是一个 OpenID Connect (OIDC) 身份提供者，用于：

- 为 OnDemand、ColdFront 和 XDMoD 提供统一身份认证
- 连接 LDAP 目录服务进行用户验证
- 提供单点登录(SSO)功能

## 🔑 登录凭据

### LDAP 用户账户

根据配置，以下用户应该可以登录：

- **用户名**: `hpcadmin`
- **密码**: `ilovelinux`

- **用户名**: `cgray`
- **密码**: `test123`

- **用户名**: `sfoster`
- **密码**: `ilovelinux`

- **用户名**: `csimmons`
- **密码**: `ilovelinux`

- **用户名**: `astewart`
- **密码**: `ilovelinux`

## 🌐 访问方式

### 直接访问 Dex

- **URL**: https://localhost:5554
- 这是身份认证服务的管理界面

### 通过其他服务访问

通常您不需要直接访问端口 5554，而是通过以下方式使用：

1. **OnDemand**: https://localhost:3443
   - 点击登录后会重定向到 Dex 进行认证
2. **ColdFront**: https://localhost:2443
   - 支持 OIDC 登录（通过 Dex）
3. **XDMoD**: https://localhost:4443
   - 支持 SAML/OIDC 登录（通过 Dex）
   - 管理员: admin/admin
   - LDAP 用户: hpcadmin/ilovelinux

## 🔧 当前状态

### 已知问题

目前 LDAP 服务可能没有正确初始化用户数据，这会导致：

- Dex 无法验证 LDAP 用户
- 登录可能失败

### 解决方案

1. **重启 LDAP 服务**:

   ```bash
   docker compose restart ldap
   ```

2. **等待服务完全启动**（约 30 秒）

3. **验证 LDAP 用户**:
   ```bash
   docker exec ldap ldapsearch -x -H ldap://localhost -b "ou=People,dc=example,dc=org" "(objectClass=posixAccount)" uid
   ```

## 🚀 推荐使用方式

### 1. 使用 OnDemand 登录

1. 访问 https://localhost:3443
2. 点击登录按钮
3. 会自动重定向到 Dex 认证页面
4. 使用 LDAP 凭据登录

### 2. 使用 ColdFront OIDC 登录

1. 访问 https://localhost:2443
2. 查找 OIDC/SSO 登录选项
3. 使用 LDAP 凭据登录

### 3. 直接管理员登录

对于 ColdFront 和 XDMoD，您也可以使用本地管理员账户：

- **用户名**: `admin`
- **密码**: `admin`

## 📋 技术细节

### Dex 配置

- **发行者**: https://localhost:5554
- **LDAP 连接**: ldap:636
- **用户基 DN**: ou=People,dc=example,dc=org
- **组基 DN**: ou=Groups,dc=example,dc=org

### 集成服务

- **ColdFront**: 使用 OIDC 连接 Dex
- **XDMoD**: 使用 SAML/OIDC 连接 Dex
- **OnDemand**: 内置 Dex 作为身份提供者

## 🛠️ 故障排除

如果无法登录：

1. **检查 LDAP 状态**:

   ```bash
   docker logs ldap --tail=10
   ```

2. **检查 Dex 状态**:

   ```bash
   docker logs ondemand --tail=10
   ```

3. **重启认证相关服务**:

   ```bash
   docker compose restart ldap ondemand
   ```

4. **等待服务完全启动**后再尝试登录

---

**注意**: 端口 5554 主要用于服务间通信和认证重定向，一般用户通过其他服务的登录页面间接使用此服务。
