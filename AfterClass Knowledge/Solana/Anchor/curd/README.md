# curd

## 写一个Solana Dapp的流程
### 1、anchor - programs - curdapp - src - lib
在这里写solana，智能合约的rust代码，分步见文件
### 2、anchor build -> solana-test-validator -> anchor deploy 在本地的RPC部署合约
部署成功之后才可以正常使用Dapp，同时看看合约有没有问题
### 3、src - components - basic
依次处理文件，实现合约逻辑和用户界面
### 4、测试  

This is a Next.js app containing:

- Tailwind CSS setup for styling
- Useful wallet UI elements setup using [@solana/web3.js](https://www.npmjs.com/package/@solana/web3.js)
- A basic Greeter Solana program written in Anchor
- UI components for interacting with the Greeter program

## Getting Started

### Installation

#### Download the template

```shell
pnpm create solana-dapp@latest -t gh:solana-foundation/templates/web3js/curd
```

#### Install Dependencies

```shell
pnpm install
```

## Apps

### anchor

This is a Solana program written in Rust using the Anchor framework.

#### Commands

You can use any normal anchor commands. Either move to the `anchor` directory and run the `anchor` command or prefix the
command with `pnpm`, eg: `pnpm anchor`.

#### Sync the program id:

Running this command will create a new keypair in the `anchor/target/deploy` directory and save the address to the
Anchor config file and update the `declare_id!` macro in the `./src/lib.rs` file of the program.

You will manually need to update the constant in `anchor/lib/counter-exports.ts` to match the new program id.

```shell
pnpm anchor keys sync
```

#### Build the program:

```shell
pnpm anchor-build
```

#### Start the test validator with the program deployed:

```shell
pnpm anchor-localnet
```

#### Run the tests

```shell
pnpm anchor-test
```

#### Deploy to Devnet

```shell
pnpm anchor deploy --provider.cluster devnet
```

### web

This is a React app that uses the Anchor generated client to interact with the Solana program.

#### Commands

Start the web app

```shell
pnpm dev
```

Build the web app

```shell
pnpm build
```
