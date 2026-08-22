# Yinor Coffee 网站 - 自助编辑指南（中文）

> 你的网站源码在 `E:\deepseekharenss\yinor-site\` 文件夹里。改内容 = 改这个文件夹里的文件 → 双击"发布网站.bat" → 上线完成。

## 一、文件地图（哪里改什么）

| 想改什么 | 打开哪个文件 | 说明 |
|---|---|---|
| **首页文字**（标题/副标题/介绍/FAQ） | `src\pages\index.body.html` | 最大的那个文件，全站最重要 |
| **产品目录页** | `src\pages\premium-espresso-blends-coffee-beans.body.html` | "All Products" 页 |
| **3 个类别页** | `src\pages\regular-espresso-blends-coffee-beans.body.html` 等 | Regular / Premium / SOE |
| **关于我们** | `src\pages\about-us-coffee-beans.body.html` | |
| **询价页** | `src\pages\request-a-consultation-coffee-wholesale-inquiry.body.html` | |
| **单个产品页** | `src\products\` 文件夹里对应的文件 | 文件名 = 产品网址 |
| **博客文章** | `src\posts\` 文件夹里对应的文件 | 文件名 = 文章网址 |
| **顶部导航**（菜单） | `src\partials\header.html` | 首页/产品/博客等链接 |
| **页脚**（社交图标/联系方式） | `src\partials\footer.html` | |
| **颜色/字体/样式** | `assets\css\style.css` | 不懂 CSS 就别动 |
| **产品图片/Logo** | `assets\img\` 文件夹 | 直接替换同名文件 |
| **网站目录 PDF** | `assets\yinor-coffee-catalogue.pdf` | 直接替换 |

## 二、怎么编辑（3 种方式）

1. **记事本**：右键文件 → 打开方式 → 记事本（够用，但没行号）
2. **Notepad++**（推荐，免费）：notepad-plus-plus.org 下载
3. **VS Code**（最专业，免费）：code.visualstudio.com 下载 → 文件 → 打开文件夹 → 选 `yinor-site`

## 三、文件里的结构（看懂就不怕）

每个页面文件顶部有一段 `<!-- 和 -->`，**这是"页面设置"，别改坏**：

```
<!--
title: 页面的 SEO 标题（谷歌搜索显示的）
desc: 页面的描述（谷歌搜索简介）
ogimage: 分享图
-->
```

`-->` 之后才是**页面正文**（HTML 代码）。改文字时：

- 改 `<h1>...</h1>` 之间 → 大标题
- 改 `<p>...</p>` 之间 → 段落文字
- 改 `<a href="网址">文字</a>` → 链接
- ⚠️ 不要删掉 `<` `>` 符号，只改里面的文字内容

## 四、改完怎么发布（1 分钟）

1. 保存文件
2. **双击 `发布网站.bat`**
3. 弹窗里输入 Netlify 令牌（以后我会教你重新生成，或告诉我帮你处理），回车
4. 看到 "DEPLOYED" 就是成功了
5. 打开 yinorcoffee.com 刷新查看（手机端可能要清缓存）

## 五、重要提醒

- ⚠️ **不要改 `docs\` 文件夹**里的文件——那是程序自动生成的，下次发布会被覆盖
- ⚠️ 改文字时注意别把 `<!-- title: ... -->` 那几行弄乱
- ⚠️ 中文/特殊符号没问题，但**不要从 Word 复制**带弯引号的内容（会产生乱码）
- 💡 **没把握的改动**：改完前把原文件复制一份备份，或直接让我来改（更保险）
- 📌 以后我帮你改也是走同样流程：改 `src\` → 发布 → 上线
