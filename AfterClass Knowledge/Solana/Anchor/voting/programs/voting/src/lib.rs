
// 优秀的合约设计思路
// 1 设计好对象（账户）和指令，以及PDA的种子形式，确保PDA唯一性
// 2 一个一个指令来，先写简单program框架，然后写相关的实现类，然后写相关的账户
use anchor_lang::prelude::*;

declare_id!("2mQubwWSDgyvAwPJL7nhE6CAvKRQ32AegUc7RFVKrZf2");

#[program]
pub mod voting {
    use super::*;

    // 一个合约指令要对应一个账户类实现, 这个实现指令会放进context
    pub fn initialize_poll(
        ctx: Context<InitializePoll>,
        poll_id: u64,
        question: String,
        poll_start: i64,
        poll_end: i64,
        candidate_amount: u64,
    ) -> Result<()> {
        let poll = &mut ctx.accounts.poll;
        poll.poll_id = poll_id;
        poll.question = question;
        poll.poll_start = poll_start;
        poll.poll_end = poll_end;
        poll.candidate_amount = candidate_amount;
        msg!("Greetings from: initialize_poll");
        Ok(())
    }

    pub fn initialize_candidate(
        ctx: Context<InitializeCandidate>,
        candidate_name: String,
        _poll_id: u64,
    ) -> Result<()> {
        let candidate = &mut ctx.accounts.candidate;
        candidate.candidate_name = candidate_name;
        candidate.vote_count = 0;
        msg!("Greetings from: initialize_candidate");
        Ok(())
    }

    pub fn vote(ctx: Context<Vote>, _poll_id: u64, _candidate_name: String) -> Result<()> {
        // 执行投票逻辑
        let candidate = &mut ctx.accounts.candidate;
        candidate.vote_count += 1;
        msg!("Greetings from: vote");
        Ok(())
    }
}

#[derive(Accounts)]
pub struct InitializePoll<'info> {
    // 每个实现类用三个元素，signer，account，program
    #[account(mut)]
    pub user: Signer<'info>,
    // 记得给Signer后的东西初始化，payer，space，seeds，bump
    #[account(
        init,
        payer = user,
        space = 8 + Poll::INIT_SPACE,
        seeds = [b"poll"],
        bump
    )]
    pub poll: Account<'info, Poll>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct InitializeCandidate<'info> {
    #[account(mut)]
    pub user: Signer<'info>,
    #[account(
        init,
        payer = user,
        space = 8 + Candidate::INIT_SPACE,
        seeds = [b"candidate", poll.key().as_ref()],
        bump
    )]
    pub candidate: Account<'info, Candidate>,
    /// 关联的投票
    pub poll: Account<'info, Poll>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct Vote<'info> {
    // 这时候就不一个Account，因为这个函数有多个账户参与，也要声明一下有参与的这些账户
    #[account(mut)]
    pub user: Signer<'info>,
    #[account(mut)]
    pub poll: Account<'info, Poll>, 
    #[account(mut)]
    pub candidate: Account<'info, Candidate>,
    pub system_program: Program<'info, System>,
}
// 
#[account]
#[derive(InitSpace)]
pub struct Poll {
    pub poll_id: u64,
    #[max_len(50)]
    pub question: String,
    pub poll_start: i64,
    pub poll_end: i64,
    pub candidate_amount: u64,
}


#[account]
#[derive(InitSpace)]
pub struct Candidate {
    #[max_len(50)]
    pub candidate_name: String,
    pub vote_count: u64,
}
