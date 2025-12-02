use anchor_lang::prelude::*;

declare_id!("Cmt5HgWC2VSxzNHNvFT1KqYtuAFVSPU2EXB6T3FV7WbF");

// 使用program宏，使得下面的内容变成Solana智能合约
#[program]
pub mod favorites {
    use super::*;

    pub fn initialize(_ctx: Context<Initialize>) -> Result<()> {
        // 打印日志，当成Println就可以了
        msg!("Greetings from: initialize");
        Ok(())
    }

    pub fn initialize_favorites(ctx: Context<InitializeFavorites>, number: u64, color: String, hobbies: Vec<String>) -> Result<()> {
        // 传参，初始化账户信息
        let favorites = &mut ctx.accounts.favorites;
        favorites.number = number;
        favorites.color = color;
        favorites.hobbies = hobbies;
        Ok(())

    }
}

// 声明Account和InitSpace，让下面的内容变成Solana账户
#[account]
#[derive(InitSpace)]

pub struct Favorites{
    pub number: u64,

    // 既然String是任意长的，使用这个宏可以限定长度
    #[max_len(50)]
    pub color: String,
    // 对于Vec可以指定数量
    #[max_len(5, 50)]
    pub hobbies: Vec<String>,

}

// 按照惯例，只有账户还不够，需要专门写一个创建账户，或管理账户列表的类
#[derive(Accounts)]
pub struct InitializeFavorites<'info>{
    // 必写
    #[account(mut)]
    pub user: Signer<'info>,
    // 初始化Favorites空间和信息
    #[account(init, payer=user, space=9000, seeds=[b"favorites".as_ref()], bump)]
    pub favorites: Account<'info, Favorites>,

    // 初始化合约序列
    pub system_program: Program<'info, System>,
}

// 用于 initialize 的空上下文
#[derive(Accounts)]
pub struct Initialize {}
