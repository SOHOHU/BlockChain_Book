'use client'
//是前端与 Anchor 程序交互的集中数据层，这些数据会上传到用户页面
import { getBasicProgram, getBasicProgramId } from '@project/anchor'
import { useConnection, useWallet } from '@solana/wallet-adapter-react'
import { Cluster, PublicKey, SystemProgram } from '@solana/web3.js'
import { useMutation, useQuery } from '@tanstack/react-query'
import { useMemo } from 'react'
import { useCluster } from '../cluster/cluster-data-access'
import { useAnchorProvider } from '../solana/solana-provider'
import { useTransactionToast } from '../use-transaction-toast'
import { toast } from 'sonner'

interface EntryArgs {
  title: string
  message: string
}

export function useBasicProgram() {
  // RPC 连接（来自钱包适配器）
  const { connection } = useConnection()
  // 当前钱包公钥
  const { publicKey } = useWallet()
  // 当前选定的集群（localnet/devnet等）
  const { cluster } = useCluster()
  // 交易签名 toast
  const transactionToast = useTransactionToast()
  // Anchor Provider（含连接与钱包）
  const provider = useAnchorProvider()
  // 按集群取 programId
  const programId = useMemo(() => getBasicProgramId(cluster.network as Cluster), [cluster])
  // Anchor Program 客户端
  const program = useMemo(() => getBasicProgram(provider, programId), [provider, programId])
  // 前面这些用Anchor自带的就好
  // 基于钱包公钥派生 journal_entry PDA
  const journalEntryPda = useMemo(
    () =>
      publicKey
        ? PublicKey.findProgramAddressSync([Buffer.from('journal_entry'), publicKey.toBuffer()], programId)[0]
        : undefined,
    [programId, publicKey],
  )

  // 查询当前钱包拥有的 JournalEntryState，使用useQuery，这里就不能用自带的了
  const accounts = useQuery({
    queryKey: ['journalEntry', { cluster, owner: publicKey?.toBase58() }],
    enabled: !!publicKey,
    queryFn: () =>
      program.account.journalEntryState.all([
        {
          memcmp: {
            offset: 8, // anchor account discriminator
            bytes: publicKey!.toBase58(),
          },
        },
      ]),
  })

  // 所有的合约指令用usemutation实现
  // 创建 journal entry
  // 封装一笔「创建 journal entry」的链上写操作，mutationKey 描述作用域，便于缓存/并发控制。
  const createEntry = useMutation<string, Error, EntryArgs>({
    mutationKey: ['journalEntry', 'create', { cluster }],
    // 接收表单入参（title/message）
    mutationFn: async ({ title, message }) => {
      // 先校验钱包和 PDA 派生存在，否则抛错。
      if (!publicKey || !journalEntryPda) throw new Error('Wallet not connected')
      const accountInputs = {
        user: publicKey,
        journalEntry: journalEntryPda,
        systemProgram: SystemProgram.programId,
      } satisfies {
        user: PublicKey
        journalEntry: PublicKey
        systemProgram: PublicKey
      }
      // program.methods.createJournalEntry(...).accounts(...).rpc() 发交易。
      return program.methods
        .createJournalEntry(title, message)
        .accounts(accountInputs)
        .rpc()
    },
    onSuccess: (signature) => {
      transactionToast(signature)
      accounts.refetch()
    },
    onError: (error) => {
      toast.error(`Error creating entry: ${error.message}`)
    },
  })

  // 更新 journal entry
  const updateEntry = useMutation<string, Error, EntryArgs>({
    mutationKey: ['journalEntry', 'update', { cluster }],
    mutationFn: async ({ title, message }) => {
      if (!publicKey || !journalEntryPda) throw new Error('Wallet not connected')
      const accountInputs = {
        user: publicKey,
        journalEntry: journalEntryPda,
        systemProgram: SystemProgram.programId,
      } satisfies {
        user: PublicKey
        journalEntry: PublicKey
        systemProgram: PublicKey
      }
      return program.methods
        .updateJournalEntry(title, message)
        .accounts(accountInputs)
        .rpc()
    },
    onSuccess: (signature) => {
      transactionToast(signature)
      accounts.refetch()
    },
    onError: (error) => {
      toast.error(`Error updating entry: ${error.message}`)
    },
  })

  // 删除 journal entry
  const deleteEntry = useMutation<string, Error, void>({
    mutationKey: ['journalEntry', 'delete', { cluster }],
    mutationFn: async () => {
      if (!publicKey || !journalEntryPda) throw new Error('Wallet not connected')
      const accountInputs = {
        user: publicKey,
        journalEntry: journalEntryPda,
        systemProgram: SystemProgram.programId,
      } satisfies {
        user: PublicKey
        journalEntry: PublicKey
        systemProgram: PublicKey
      }
      return program.methods
        .deleteJournalEntry()
        .accounts(accountInputs)
        .rpc()
    },
    onSuccess: (signature) => {
      transactionToast(signature)
      accounts.refetch()
    },
    onError: (error) => {
      toast.error(`Error deleting entry: ${error.message}`)
    },
  })

  // 查询程序账户（用于展示部署状态）
  const getProgramAccount = useQuery({
    queryKey: ['get-program-account', { cluster }],
    queryFn: () => connection.getParsedAccountInfo(programId),
  })

  // 每一个指令操作都可以把上面的代码当作模板，无非就是
  // 1、实例化usemutation
  // 2、 return program.methods.deleteJournalEntry().accounts(accountInputs).rpc() 发送交易
  // 3、写on正误

  return {
    cluster,
    programId,
    program,
    journalEntryPda,
    accounts,
    createEntry,
    updateEntry,
    deleteEntry,
    getProgramAccount,
  }
}
