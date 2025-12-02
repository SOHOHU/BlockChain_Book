import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { Voting } from "../target/types/voting";

const { PublicKey, SystemProgram } = anchor.web3;
const BN = anchor.BN;

describe("voting", () => {
  // 使用本地集群（anchor test 会自动启动本地验证器）
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.Voting as Program<Voting>;
  const user = provider.wallet.publicKey;

  // 预设 PDA（按照程序 seeds）
  const [pollPda] = PublicKey.findProgramAddressSync(
    [Buffer.from("poll")],
    program.programId
  );
  const [candidatePda] = PublicKey.findProgramAddressSync(
    [Buffer.from("candidate"), pollPda.toBuffer()],
    program.programId
  );

  it("initializes poll, adds candidate, and votes", async () => {
    // 1) 初始化 Poll
    await program.methods
      .initializePoll(
        new BN(1), // poll_id
        "Who is the best dev?", // question
        new BN(0), // poll_start
        new BN(1_000_000), // poll_end
        new BN(1) // candidate_amount
      )
      .accounts({
        user,
        poll: pollPda,
        systemProgram: SystemProgram.programId,
      })
      .rpc();

    // 2) 初始化 Candidate
    await program.methods
      .initializeCandidate("Alice", new BN(1))
      .accounts({
        user,
        candidate: candidatePda,
        poll: pollPda,
        systemProgram: SystemProgram.programId,
      })
      .rpc();

    // 3) 投票
    await program.methods
      .vote(new BN(1), "Alice")
      .accounts({
        user,
        poll: pollPda,
        candidate: candidatePda,
        systemProgram: SystemProgram.programId,
      })
      .rpc();

    // 4) 验证计数
    const candidate = await program.account.candidate.fetch(candidatePda);
    expect(candidate.voteCount.toNumber()).to.equal(1);
    expect(candidate.candidateName).to.equal("Alice");
  });
});
