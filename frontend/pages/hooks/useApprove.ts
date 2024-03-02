import { useAccount, useReadContract, useWriteContract, useClient } from "wagmi"
import { DEPLOYED_ADAPTER, approveAndAllowanceAbi, symbolToAsset } from "../src/constants"
import { sepolia } from "viem/chains"
import { waitForTransactionReceipt } from "viem/actions"
import { parseBigInt } from "../src/formatters"

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
      DEPLOYED_ADAPTER // here goes the spender address
    ],
  })

  const allowance = asset ? parseBigInt(allowanceResult.data as bigint, asset.decimals) : 0

  const approve = async (amount: number) => {
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
          DEPLOYED_ADAPTER,
          bigintAmount,
        ],
      })
      await waitForTransactionReceipt(client, { hash })
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
