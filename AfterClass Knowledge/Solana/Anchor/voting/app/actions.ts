import {
  ActionGetResponse,
  ActionPostRequest,
  ActionPostResponse,
  createPostResponse,
} from "@solana/actions";
import * as anchor from "@coral-xyz/anchor";
import { AnchorProvider, BN, Program } from "@coral-xyz/anchor";
import { PublicKey, Transaction } from "@solana/web3.js";
import idl from "../target/idl/voting.json";
import type { Voting } from "../target/types/voting";

// === Config ===
// RPC/公网地址可通过环境变量覆盖，便于本地或隧道(ngrok)部署时使用。
const RPC_URL = process.env.RPC_URL ?? "http://127.0.0.1:8899";
const PUBLIC_URL = process.env.PUBLIC_URL ?? "http://localhost:3000";

// 构造 Anchor Program 客户端。ProgramId 来自 IDL metadata，避免硬编码。
function getProgram(): Program<Voting> {
  const connection = new anchor.web3.Connection(RPC_URL, "confirmed");
  const provider = new AnchorProvider(connection, AnchorProvider.local().wallet, {
    preflightCommitment: "confirmed",
  });
  return new Program<Voting>(idl as Voting, provider);
}

// GET：返回 Action 描述（Action Provider 返回元数据，客户端渲染按钮）
export async function handleGet(): Promise<ActionGetResponse> {
  return {
    title: "Vote on Poll",
    description: "Cast your vote on the Voting program",
    icon: "https://placehold.co/64x64",
    label: "Vote",
    links: {
      actions: [
        {
          type: "post",
          label: "Vote Alice",
          href: `${PUBLIC_URL}/api/vote?candidate=Alice&poll_id=1`,
        },
        {
          type: "post",
          label: "Vote Bob",
          href: `${PUBLIC_URL}/api/vote?candidate=Bob&poll_id=1`,
        },
      ],
    },
  };
}

// POST：根据用户参数构造交易，返回待签名的 ActionPostResponse（transaction 类型）
export async function handlePost(
  req: ActionPostRequest<Record<string, string | string[]>>
): Promise<ActionPostResponse> {
  const account = req.account;
  if (!account) throw new Error("missing account");

  // 解析参数（Solana Actions 规范使用 data 字段传参）
  const data = (req.data ?? {}) as Record<string, string | string[]>;
  const candidateVal = data["candidate"];
  const pollVal = data["poll_id"];
  const candidate =
    typeof candidateVal === "string"
      ? candidateVal
      : Array.isArray(candidateVal) && candidateVal.length > 0
      ? candidateVal[0]
      : "Alice";
  const pollIdNum =
    typeof pollVal === "string"
      ? Number(pollVal)
      : Array.isArray(pollVal) && pollVal.length > 0
      ? Number(pollVal[0])
      : 1;
  const pollId = new BN(pollIdNum);

  const user = new PublicKey(account);
  const program = getProgram();
  const programId = program.programId;

  // PDA 计算与 on-chain seeds 对齐
  const [pollPda] = PublicKey.findProgramAddressSync(
    [Buffer.from("poll")],
    programId
  );
  const [candidatePda] = PublicKey.findProgramAddressSync(
    [Buffer.from("candidate"), pollPda.toBuffer()],
    programId
  );

  // 构造未签名交易
  const tx: Transaction = await program.methods
    .vote(pollId, candidate)
    .accounts({
      user,
      poll: pollPda,
      candidate: candidatePda,
    })
    .transaction();

  // 返回 Action POST 响应，客户端钱包签名并发送
  return createPostResponse({
    fields: {
      type: "transaction",
      transaction: tx,
      message: `Created vote tx for ${candidate}`,
    },
  });
}

/**
 * Action Execution & Lifecycle（Solana 官方概念，简述放在注释便于查阅）：
 *
 * 1) Discovery：客户端向 Action Provider 发送 GET（/api/vote），获取元数据(title/description/links)。
 * 2) Parameter Input：links.actions 可包含参数；本例直接把 candidate/poll_id 放在 href query。
 * 3) POST 构建：客户端提交 account+data，handlePost 构造交易并返回 transaction 类型响应。
 * 4) Signing & Submission：用户钱包签名返回的交易并广播到链上。
 * 5) Completion：客户端可根据交易签名展示完成状态，或继续 next action 链。
 */
