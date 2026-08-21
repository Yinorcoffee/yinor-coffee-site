# 交接说明（HANDOFF）

新站已在本目录完整构建并验证。下一步把它推到你的 GitHub，由我接管后续所有修改和部署。

## 一、你需要做的（5 分钟）

### 1. 创建 GitHub 仓库

1. 登录 https://github.com → 右上角 **+** → **New repository**
2. Repository name 填 `yinor-coffee-site`（可自定）
3. 选 **Private**（私有，安全）
4. 不要勾选任何初始化选项（Add README / .gitignore 都**不勾**，保持空仓库）
5. 点 **Create repository**

### 2. 生成受限令牌（Fine-grained Token）

1. GitHub 右上角头像 → **Settings** → 左侧最底部 **Developer settings**
2. **Personal access tokens** → **Fine-grained tokens** → **Generate new token**
3. Token name 随意（如 `yinor-site-deploy`）；Expiration 选 7 天或 30 天
4. **Repository access** 选 **Only select repositories** → 勾选刚建的 `yinor-coffee-site`
5. **Permissions → Repository permissions** 里只把 **Contents** 设为 **Read and write**，其他全部保持 **No access**
6. 点 **Generate token** → **复制**生成的 token（只显示一次！）

### 3. 把 token 发给我

把 token 粘贴发给我即可。我会：
- 把 `out/`（可部署的完整站点）和全部源码推到你的仓库
- 验证 GitHub Pages / Netlify 自动部署
- 之后任何内容修改（加产品、写博客、调样式）我直接在源码上改并重新部署

> ⚠️ 安全边界：这个 token 只能读写 `yinor-coffee-site` 这一个仓库，碰不到你其他仓库和账号。交接完成后你可以随时到 Settings → Developer settings 里把它**删除**，我后续改用其他方式或你重新授权。
> 如果你不想发 token：也可以自己把本文件夹上传到仓库（网页端 Upload files 拖拽即可），我远程指导你部署。

## 二、部署平台选择（交接时一起定）

| 平台 | 优点 | 适合 |
|---|---|---|
| **GitHub Pages**（推荐先用） | 免费、自动构建（已配好 Actions）、绑定自定义域名免费 | 快速上线预览 |
| **Netlify**（推荐正式） | 免费、自动 HTTPS、301 重定向完整支持（已配 `_redirects`）、全球 CDN | 正式运营 |
| Vercel | 同上，Vercel 生态 | 备选 |

> 无论选哪个，`yinorcoffee.com` 域名都会在**新平台完全就绪并验证后**才切换 DNS，旧站保留在线直到新站稳定——SEO 零风险切换。

## 三、我要做的（拿到 token 后）

1. 推送代码到仓库
2. 配置部署（按你选的平台）
3. 等部署完成，给你一个预览 URL 让你在手机和电脑上检查
4. 你满意后，切换 DNS（需你在 Hostinger hPanel 操作，或给我 Hostinger API token 我来切）
5. 切换后：GSC 提交 sitemap、请求收录、监控 2-4 周

## 四、本机无 git 的说明

当前构建机器没有安装 git，所以仓库尚未初始化。不影响任何事：你创建好空仓库后，我把 `out/` 内容打包/通过 token 直接上传，或者你用网页 Upload files 上传本文件夹全部内容（含 `.github/` 和 `out/`）即可。
