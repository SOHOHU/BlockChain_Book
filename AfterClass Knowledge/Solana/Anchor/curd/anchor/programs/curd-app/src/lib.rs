use anchor_lang::prelude::*;

declare_id!("2pw1YK6w22B4hkWmG9zhW9JyvCTeqzQViJYaQ8qCDaxu");

#[program]
pub mod basic {
    use super::*;

    // 建完账户马上写构造函数，即初始化实现结构
    pub fn create_journal_entry(ctx: Context<CreateEntry>, title: String, message: String) -> Result<()> {
        let journal_entry = &mut ctx.accounts.journal_entry;
        journal_entry.title = title;
        journal_entry.message = message;
        journal_entry.owner = *ctx.accounts.user.key;
        msg!("Greetings from: create_journal_entry");
        Ok(())
    }

    pub fn update_journal_entry(ctx: Context<UpdateEntry>, title: String, message: String) -> Result<()>
    {
        let journal_entry = &mut ctx.accounts.journal_entry;
        journal_entry.title = title;
        journal_entry.message = message;
        msg!("Greetings from: update_journal_entry");
        Ok(())
    }

    pub fn delete_journal_entry(ctx: Context<DeleteEntry>) -> Result<()>
    {
        msg!("Greetings from: delete_journal_entry");
        Ok(())
    }

}

#[account]
#[derive(InitSpace)]
// 经典的创建需要的账户，包括所有需要占用空间的数据结构
pub struct JournalEntryState {
    pub owner: Pubkey,
    #[max_len(50)]
    pub title: String,
    #[max_len(200)]
    pub message: String,
}


#[derive(Accounts)]
// 经典，函数的实现结构需要三步走
struct CreateEntry<'info> {
    // 三步走两个宏，别忘了
    #[account(mut)]
    pub user: Signer<'info>,
    #[account(
        init,
        // 支付链上空间租金的人
        payer = user,
        space = 8 + JournalEntryState::INIT_SPACE,
        seeds = [b"journal_entry", user.key().as_ref()],
        bump
    )]
    pub journal_entry: Account<'info, JournalEntryState>,
    pub system_program: Program<'info, System>,
}

// 每一个实现结构都要加这个宏
#[derive(Accounts)]
pub struct UpdateEntry<'info> {
    #[account(mut)]
    pub user: Signer<'info>,
    // 因为这个功能，或者说实现这个功能的账户已经被初始化，所以不需要init，但是更新的话我们需要它可变，所以mut
    #[account(
        mut,
        seeds = [b"journal_entry", user.key().as_ref()],
        bump,
        // 我每次更新会重新分配空间，空间变大租金要加，空间变小退还租金，所以此处需要先重新计算空间
        realloc = JournalEntryState::INIT_SPACE,
        realloc::payer = user,
        // 清零原始空间再重新计算，我们这里规定了生命周期，不用担心空指针的事情
        realloc::zero = true
    )]
    pub journal_entry: Account<'info, JournalEntryState>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct DeleteEntry<'info> {
    #[account(mut)]
    pub user: Signer<'info>,
    #[account(
        mut,
        // 删除关闭这个公钥的所有者。关闭后自动释放空间
        close = user,
        seeds = [b"journal_entry", user.key().as_ref()],
        bump
    )]
    pub journal_entry: Account<'info, JournalEntryState>,
    pub system_program: Program<'info, System>,
}
