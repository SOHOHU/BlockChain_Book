# Buy Me A Coffee - Frontend

这是 Buy Me A Coffee DApp 的前端应用，基于 Next.js 和 TypeScript 构建。

## 🚀 快速开始

### 安装依赖

```bash
npm install
```

### 配置合约地址

编辑 `lib/contract.ts`，更新合约地址：

```typescript
export const CONTRACT_ADDRESS = "YOUR_DEPLOYED_CONTRACT_ADDRESS";
```

### 开发模式

```bash
npm run dev
```

访问 http://localhost:3000

### 生产构建

```bash
npm run build
npm start
```

## 📦 部署到 Vercel

### 方式一：使用 Vercel CLI

```bash
npm install -g vercel
vercel
```

### 方式二：GitHub 集成

1. 推送代码到 GitHub
2. 在 Vercel 中导入项目
3. Vercel 会自动检测并部署

## 🔧 环境变量

前端不需要环境变量，所有交易通过用户的 MetaMask 钱包签名。

## 📝 使用说明

1. **连接钱包**：使用 MetaMask 连接
2. **确保正确的网络**：Kaia Kairos Testnet (Chain ID: 1001)
3. **购买咖啡**：输入信息并发送 KAIA
4. **查看记录**：所有打赏记录显示在留言墙

## 🛠️ 技术栈

- **框架**: Next.js 14+ (App Router)
- **语言**: TypeScript
- **样式**: Tailwind CSS
- **Web3**: ethers.js v6
- **部署**: Vercel

## 📂 项目结构

```
frontend/
├── app/
│   ├── page.tsx          # 主页面
│   ├── layout.tsx        # 布局
│   └── globals.css       # 全局样式
├── lib/
│   └── contract.ts       # 合约配置和 ABI
├── public/              # 静态资源
└── package.json
```

## 🔗 相关链接

- [Next.js 文档](https://nextjs.org/docs)
- [Ethers.js 文档](https://docs.ethers.org/v6/)
- [Kaia 文档](https://docs.kaia.io/)
