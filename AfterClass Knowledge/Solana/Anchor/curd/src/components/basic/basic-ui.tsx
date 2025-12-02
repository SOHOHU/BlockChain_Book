'use client'

import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useEffect, useState, FormEvent } from 'react'
import { useBasicProgram } from './basic-data-access'
import { useWallet } from '@solana/wallet-adapter-react'

export function BasicCreate() {
  // 按照步骤到这里，不用改什么，添加一个isFormValid即可
  const { createEntry } = useBasicProgram()
  const [title, setTitle] = useState('')
  const [message, setMessage] = useState('')
  const { publicKey } = useWallet()
  const isFormValid = title.trim() !== '' && message.trim() !== ''

  const handleSubmit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    if (!publicKey || !isFormValid) return
    createEntry.mutate({ title: title.trim(), message: message.trim() }, { onSuccess: () => {
      setTitle('')
      setMessage('')
    } })
  }
  // 前面这一串保留这个模板就好
  // 这部分按照自己的期望写用户界面就可以
  return (
    <Card>
      <CardHeader>
        <CardTitle>Create journal entry</CardTitle>
        <CardDescription>Fill in the title and message to create your PDA-backed journal entry.</CardDescription>
      </CardHeader>
      <CardContent>
        <form className="flex flex-col gap-4" onSubmit={handleSubmit}>
          <div className="space-y-2">
            <Label htmlFor="title">Title</Label>
            <Input
              id="title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="My first note"
              required
              disabled={createEntry.isPending}
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="message">Message</Label>
            <textarea
              id="message"
              className="textarea textarea-bordered w-full min-h-[120px]"
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Write something memorable..."
              required
              disabled={createEntry.isPending}
            />
          </div>
          <Button type="submit" disabled={createEntry.isPending}>
            {createEntry.isPending ? 'Creating...' : 'Create entry'}
          </Button>
        </form>
      </CardContent>
    </Card>
  )
}


// 在这个函数实现合约的功能，并且给出效果
export function BasicProgram() {
  const { accounts, updateEntry, deleteEntry } = useBasicProgram()
  const entry = accounts.data?.[0]
  const [title, setTitle] = useState('')
  const [message, setMessage] = useState('')
  // 前面这部分都不用改


  // 这部分按照模板，看情况修改，因为我这里表单是title和message，所以这么写
  // 当远端数据变化时，把链上存储的 entry.account.title/message 同步到本地表单状态，确保表单显示当前值。
  useEffect(() => {
    setTitle(entry?.account.title ?? '')
    setMessage(entry?.account.message ?? '')
  }, [entry?.account.message, entry?.account.title])


  // 查询未完成时显示加载 spinner。按自己的期望写界面
  if (accounts.isLoading) {
    return <span className="loading loading-spinner loading-lg" />
  }

  // 查询完成但没有找到账户时显示提示，引导用户先创建 entry，一样写界面
  if (!entry) {
    return (
      <div className="alert alert-info flex justify-center">
        <span>No journal entry found for this wallet. Create one to get started.</span>
      </div>
    )
  }

  // 渲染一个卡片，展示 PDA 地址和两个输入框，按钮触发updateEntry.mutate({ title, message }) 更新，或 deleteEntry.mutate() 删除，操作中禁用按钮并切换文案。
  // 总之就是写这个函数调用后端界面变化
  return (
    <Card>
      <CardHeader>
        <CardTitle>Your journal entry</CardTitle>
        <CardDescription>Update or delete the entry stored at your PDA.</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="space-y-2">
          <Label>Account</Label>
          <p className="text-sm break-all text-muted-foreground">{entry.publicKey.toBase58()}</p>
        </div>
        <div className="space-y-2">
          <Label htmlFor="update-title">Title</Label>
          <Input
            id="update-title"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            disabled={updateEntry.isPending || deleteEntry.isPending}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="update-message">Message</Label>
          <textarea
            id="update-message"
            className="textarea textarea-bordered w-full min-h-[120px]"
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            disabled={updateEntry.isPending || deleteEntry.isPending}
          />
        </div>
        <div className="flex gap-3">
          <Button
            onClick={() => updateEntry.mutate({ title, message })}
            disabled={updateEntry.isPending || deleteEntry.isPending}
          >
            {updateEntry.isPending ? 'Updating...' : 'Update entry'}
          </Button>
          <Button
            variant="destructive"
            onClick={() => deleteEntry.mutate()}
            disabled={deleteEntry.isPending || updateEntry.isPending}
          >
            {deleteEntry.isPending ? 'Deleting...' : 'Delete entry'}
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}
