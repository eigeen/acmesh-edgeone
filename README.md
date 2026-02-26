# acme.sh dnsapi: EdgeOne DNS

为 `acme.sh` 提供腾讯云 **EdgeOne(TEO)** 的 DNS-01 接入脚本（创建/删除 `_acme-challenge` TXT 记录）。

## 说明

目前仅限国内版本

此项目为 `codex` vibe coding 结果，已为AI提供API文档尽量保证结果可控。此项目不保证长期*主动*维护，欢迎提交 issue 和 PR。

## 依赖

- 你已安装并可用 `acme.sh`
- 目标环境：Linux amd64（脚本为 POSIX `sh`，依赖 `openssl` / `sed` / `grep` / `cut`）

## 安装（自动安装模块）

默认安装到 `~/.acme.sh/dnsapi/dns_edgeone.sh`：

一键安装：

```sh
curl -fsSL https://raw.githubusercontent.com/eigeen/acmesh-edgeone/main/install.sh | sh
```

如果使用 Fork 仓库：

```sh
EDGEONE_REPO_RAW_BASE="https://raw.githubusercontent.com/<you>/<repo>/main" \
  curl -fsSL https://raw.githubusercontent.com/<you>/<repo>/main/install.sh | sh
```

Git Clone 安装：

```sh
git clone https://github.com/eigeen/acmesh-edgeone.git
cd acmesh-edgeone
chmod +x install.sh uninstall.sh
./install.sh
```

如果你的 acme 安装目录不是 `~/.acme.sh`：

```sh
./install.sh /path/to/.acme.sh
```

卸载：

```sh
./uninstall.sh
```

## 使用

必须配置的环境变量：

```sh
export EDGEONE_SECRET_ID="AKIDxxxxxxxxxxxxxxxx"
export EDGEONE_SECRET_KEY="xxxxxxxxxxxxxxxx"
export EDGEONE_ZONE_ID="zone-xxxxxxxx"
```

可选：

```sh
export EDGEONE_TOKEN=""   # 临时密钥的 SessionToken（可选）
export EDGEONE_REGION=""  # 可选，通常可不填
export EDGEONE_TTL="300"  # TXT TTL，默认 300
export EDGEONE_TXT_OVERWRITE="1" # 创建 TXT 失败时是否覆盖同名 TXT（默认 1）
```

签发示例：

```sh
acme.sh --issue --dns dns_edgeone -d example.com -d "*.example.com"
```

如果遇到 DNS 传播慢/解析链路不一致（例如 CA 校验时报 NXDOMAIN），建议增加等待时间：

```sh
acme.sh --issue --dns dns_edgeone --dnssleep 300 -d example.com -d "*.example.com"
```

调试建议：

```sh
acme.sh --issue --staging --debug 2 --dns dns_edgeone -d example.com
```

## ZoneId 获取

`EDGEONE_ZONE_ID` 是 EdgeOne 站点 ID（形如 `zone-xxxxxxxx`）。你可以在 EdgeOne 控制台或 API Explorer 中获取。

如果你不设置 `EDGEONE_ZONE_ID`，脚本会尝试调用 `DescribeZones` 自动匹配（best-effort；需要对应权限）。

仓库内也提供了 DNS 相关接口的摘录（见 `docs/eo_dns_api.md`）。

## 排错

- `AuthFailure.SignatureFailure`：常见原因是 `EDGEONE_SECRET_ID/EDGEONE_SECRET_KEY` 不正确，或服务器时间不准（建议开启 NTP 同步）。
- 如果你同时签发 `-d example.com -d "*.example.com"`，acme.sh 可能需要同名 TXT 同时存在多个值；此时建议设置 `EDGEONE_TXT_OVERWRITE=0`（前提是你的 DNS 支持同名多条 TXT）。
- `DNS problem: NXDOMAIN looking up TXT for _acme-challenge...`：通常是 DNS 传播/缓存/解析链路导致 CA 查不到 TXT；重试时加 `--dnssleep 300`（或更大），并确认域名 NS 已正确接入 EdgeOne。

## 文件结构

- `dnsapi/dns_edgeone.sh`：acme.sh DNS API 模块（`dns_edgeone_add` / `dns_edgeone_rm`）
- `install.sh` / `uninstall.sh`：自动安装/卸载到你的 `acme.sh` 安装目录
