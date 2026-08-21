# Yinor Coffee — 独立站源码（静态站）

yinorcoffee.com 的全新静态站。**URL 结构与旧站完全一致**，迁移后 Google 收录不受影响。

## 目录结构

```
yinor-site/
├── build.ps1            # 构建脚本（PowerShell，生成 out/）
├── assets/              # 样式 + 图片（logo、产品图、hero 图）
├── src/
│   ├── partials/        # 页头/页脚模板（含 Organization 结构化数据）
│   ├── pages/           # 核心页（首页、类别页、关于、询价、博客列表、法律页、404）
│   ├── products/        # 12 个产品页
│   └── posts/           # 7 篇博客文章
└── out/                 # 构建产物（部署这个目录即可）
```

## 如何修改内容

改完 `src/` 下的文件后，运行构建：

```powershell
pwsh build.ps1
```

然后部署 `out/` 目录。

- **加产品**：复制 `src/products/` 里任意一个 `.body.html`，改文件名（= 网址 slug）和内容
- **加博客**：复制 `src/posts/` 里任意一个 `.body.html`
- **改导航/页脚**：`src/partials/header.html` / `footer.html`
- **改样式**：`assets/css/style.css`
- **每个页面顶部的 `<!-- title: ... / desc: ... -->` 就是该页的 SEO 标题和描述**

## 部署方式（任选其一）

### 方式 A：GitHub Pages（免费，推荐先预览）

仓库根目录已包含 `.github/workflows/deploy.yml`，推送到 GitHub 后自动构建并发布到 GitHub Pages。

1. 在 GitHub 建一个仓库（如 `yinor-coffee-site`，Private 即可）
2. 推送代码（推送方式见仓库交接说明）
3. 仓库 Settings → Pages → Source 选 **GitHub Actions**
4. 自定义域名：Settings → Pages → Custom domain 填 `yinorcoffee.com`（需要先把 DNS 指到 GitHub Pages，见下）

### 方式 B：Netlify（免费，推荐正式使用）

1. 登录 netlify.com → Add new site → Import an existing project → 连接 GitHub 仓库
2. Build command 留空，Publish directory 填 `out`（或直接拖拽上传 `out/` 文件夹）
3. 站点设置 → Domain management → Add custom domain → `yinorcoffee.com`
4. 按 Netlify 提示把域名 DNS 改为指向 Netlify（`_redirects` 文件已内置，301 规则自动生效）

### 方式 C：Vercel / 其他静态托管

Vercel：导入仓库 → Framework 选 Other → Output directory 填 `out`。其余静态托管同理，上传 `out/` 目录即可。

## 切换域名（正式上线）

1. 在新平台（Netlify/Pages/Vercel）把 `yinorcoffee.com` 绑定好
2. 到 Hostinger hPanel → Domains → DNS 管理，把 A 记录/NS 改成新平台的地址
   - **重要**：切换前先让旧站和新站同时在线 24-48 小时（新旧平台都绑定域名），再改 DNS，最大限度减少波动
3. DNS 生效后（1-24 小时），Google 会顺着相同 URL 无缝重新收录
4. 在 Google Search Console 用"网址检查"对首页和主要页面请求编入索引

> ⚠️ 旧站（Hostinger Website Builder）在 DNS 切换前**不要删除**——保持它在线直到新站稳定运行。

## 注意事项

- 产品图已从旧站 CDN 下载并压缩（JPEG 800px，总资产 2.4MB）；后续可替换为更高清的实拍图
- 询价表单当前用 `mailto:` 发送（打开用户邮箱客户端）。若想网页内直接提交，可接入 Formspree/Netlify Forms（免费额度），我可以帮你配置
- 法律页（隐私/条款）基于旧站内容整理，建议让法务/顾问过目一遍
- 社交链接（Facebook/TikTok/Instagram/WhatsApp）与旧站一致
