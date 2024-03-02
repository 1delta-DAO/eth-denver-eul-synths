import { useAccount, useReadContract, useWriteContract, useClient } from "wagmi"
import { approveAndAllowanceAbi, symbolToAsset } from "../src/constants"
import { sepolia } from "viem/chains"
import { waitForTransactionReceipt } from "viem/actions"

interface useApproveProps {
  assetSymbol: string
}

export const useApprove = ({ assetSymbol }: useApproveProps) => {

  const asset = symbolToAsset(assetSymbol)
  const account = useAccount()
  const { writeContractAsync, isPending, isError, isSuccess } = useWriteContract()
  const client = useClient()

  const allowanceResult = useReadContract({
    abi: approveAndAllowanceAbi,
    address: asset?.address as `0x${string}`,
    functionName: 'allowance',
    chainId: sepolia.id,
    args: [
      account?.address as `0x${string}`,
      account?.address // here goes the spender address
    ],
  })

  const allowance = asset ? Number(allowanceResult.data as bigint) / 10 ** asset?.decimals : 0

  const approve = async (spender: `0x${string}`, amount: number) => {
    if (!client) throw new Error('Client not found')
    if (!asset) throw new Error('Asset not found')
    const bigintAmount = BigInt(amount * 10 ** asset.decimals)
    try {
      const hash = await writeContractAsync({
        abi: approveAndAllowanceAbi,
        address: asset.address as `0x${string}`,
        functionName: 'approve',
        chainId: sepolia.id,
        args: [
          spender,
          bigintAmount,
        ],
      })
      await waitForTransactionReceipt(client, {hash})
      allowanceResult.refetch()
    } catch (e: any) {
      console.error(e)
    }
  }

  return {
    allowance,
    approve,
    isPending,
    isError,
    isSuccess,
  }
}
